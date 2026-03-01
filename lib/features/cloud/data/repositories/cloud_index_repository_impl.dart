import 'dart:async';
import 'dart:convert';

import 'package:novel_glide/core/file_system/domain/repositories/json_repository.dart';
import 'package:novel_glide/core/log_system/log_system.dart';
import 'package:novel_glide/core/path_provider/domain/repositories/app_path_provider.dart';
import 'package:novel_glide/features/cloud/domain/entities/cloud_file.dart';
import 'package:novel_glide/features/cloud/domain/entities/cloud_index.dart';
import 'package:novel_glide/features/cloud/domain/entities/cloud_providers.dart';
import 'package:novel_glide/features/cloud/domain/entities/index_entry.dart';
import 'package:novel_glide/features/cloud/domain/repositories/cloud_index_repository.dart';
import 'package:novel_glide/features/cloud/domain/repositories/cloud_repository.dart';
import 'package:path/path.dart' as p;

/// Implementation of CloudIndexRepository with local caching and async cloud sync.
///
/// Manages the cloud index registry with the following behavior:
/// - Local index.json serves as the working copy
/// - Google Drive hosts the source-of-truth copy
/// - Read operations try cloud first with fallback to local
/// - Write operations update locally immediately, queue cloud upload
/// - Merge logic ensures eventual consistency across devices
/// - All errors are logged but never crash the app
class CloudIndexRepositoryImpl extends CloudIndexRepository {
  CloudIndexRepositoryImpl({
    required CloudRepository cloudRepository,
    required JsonRepository jsonRepository,
    required AppPathProvider appPathProvider,
  })  : _cloudRepository = cloudRepository,
        _jsonRepository = jsonRepository,
        _appPathProvider = appPathProvider,
        _uploadQueue = <CloudIndex>[];

  final CloudRepository _cloudRepository;
  final JsonRepository _jsonRepository;
  final AppPathProvider _appPathProvider;

  /// Queue of pending index uploads to cloud.
  /// When a local update fails to sync immediately, it's queued for retry.
  final List<CloudIndex> _uploadQueue;

  /// Whether an upload is currently in progress.
  bool _uploading = false;

  /// The filename of the index file.
  static const String _indexFileName = 'index.json';

  /// Cloud folder path for the index file.
  static const String _cloudIndexPath = 'library';

  /// Timeout duration for cloud operations.
  static const Duration _cloudTimeout = Duration(seconds: 10);

  /// Gets the local file path for the index.json file.
  Future<String> _getLocalIndexPath() async {
    final String dataPath = await _appPathProvider.dataPath;
    return p.join(dataPath, _indexFileName);
  }

  /// Creates an empty CloudIndex as default fallback.
  CloudIndex _createEmptyIndex() {
    return CloudIndex(
      version: 1,
      lastUpdatedAt: DateTime.now(),
      books: const <IndexEntry>[],
    );
  }

  /// Reads the local index.json file.
  ///
  /// Returns the deserialized CloudIndex or an empty index if the file
  /// doesn't exist or is corrupted.
  Future<CloudIndex> _readLocalIndex() async {
    try {
      final String path = await _getLocalIndexPath();
      final Map<String, dynamic> json =
          await _jsonRepository.readJson(path: path);
      final CloudIndex index = CloudIndex.fromJson(json);
      LogSystem.info('Read local index: ${index.books.length} books');
      return index;
    } catch (e) {
      LogSystem.error(
        'Failed to read local index',
        error: e,
      );
      return _createEmptyIndex();
    }
  }

  /// Writes the index to the local index.json file.
  ///
  /// This is an optimistic write that happens immediately, before cloud sync.
  /// Errors are logged but don't crash the app.
  Future<void> _writeLocalIndex(CloudIndex index) async {
    try {
      final String path = await _getLocalIndexPath();
      await _jsonRepository.writeJson(
        path: path,
        data: index.toJson() as Map<String, dynamic>,
      );
      LogSystem.info('Wrote local index: ${index.books.length} books');
    } catch (e) {
      LogSystem.error(
        'Failed to write local index',
        error: e,
      );
      // Don't rethrow - local write failure shouldn't crash the app
    }
  }

  /// Attempts to fetch the cloud index with a timeout.
  ///
  /// Returns null if offline, timeout occurs, or cloud fetch fails.
  /// The caller should fall back to local in this case.
  Future<CloudIndex?> _fetchCloudIndex() async {
    try {
      final CloudFile? cloudFile = await _cloudRepository
          .getFile(CloudProviders.google, _indexFileName)
          .timeout(
            _cloudTimeout,
            onTimeout: () {
              LogSystem.warn('Cloud index fetch timeout');
              return null;
            },
          );

      if (cloudFile == null) {
        LogSystem.info('Cloud index not found (first sync?)');
        return null;
      }

      // Download the file content
      final List<int> bytes = <int>[];
      await for (final chunk
          in _cloudRepository.downloadFile(
        CloudProviders.google,
        cloudFile,
      )) {
        bytes.addAll(chunk);
      }

      // Decode as JSON
      final String jsonString = utf8.decode(bytes);
      final dynamic decoded = jsonDecode(jsonString);
      final Map<String, dynamic> json =
          decoded as Map<String, dynamic>;
      final CloudIndex cloudIndex = CloudIndex.fromJson(json);

      LogSystem.info('Fetched cloud index: ${cloudIndex.books.length} books');
      return cloudIndex;
    } catch (e) {
      LogSystem.error(
        'Failed to fetch cloud index',
        error: e,
      );
      return null; // Fall back to local
    }
  }

  /// Uploads the index to cloud storage asynchronously.
  ///
  /// Queues the upload if one is already in progress.
  /// Errors are logged but don't crash the app.
  Future<void> _uploadIndexToCloud(CloudIndex index) async {
    _uploadQueue.add(index);

    // If already uploading, let the current upload handle the queue
    if (_uploading) {
      return;
    }

    _uploading = true;

    try {
      while (_uploadQueue.isNotEmpty) {
        final CloudIndex queuedIndex = _uploadQueue.removeAt(0);

        try {
          // Save to a temporary local file first
          final String tempPath =
              '${await _getLocalIndexPath()}.upload.tmp';
          await _jsonRepository.writeJson(
            path: tempPath,
            data: queuedIndex.toJson() as Map<String, dynamic>,
          );

          // Upload to cloud
          await _cloudRepository
              .uploadFileToPath(
                CloudProviders.google,
                tempPath,
                _cloudIndexPath,
              )
              .timeout(_cloudTimeout);

          LogSystem.info('Uploaded cloud index successfully');
        } catch (e) {
          LogSystem.error(
            'Failed to upload cloud index',
            error: e,
          );
          // Re-queue for retry on next opportunity
          _uploadQueue.insert(0, queuedIndex);
          break; // Stop trying until the network recovers
        }
      }
    } finally {
      _uploading = false;
    }
  }

  @override
  Future<CloudIndex> getIndex() async {
    final CloudIndex? cloudIndex = await _fetchCloudIndex();

    if (cloudIndex != null) {
      // Cloud fetch succeeded - check if we need to update local
      final CloudIndex localIndex = await _readLocalIndex();

      if (cloudIndex.lastUpdatedAt.isAfter(localIndex.lastUpdatedAt)) {
        // Cloud is newer - merge and update local
        final CloudIndex merged = localIndex.mergeTwoVersions(cloudIndex);
        await _writeLocalIndex(merged);
        return merged;
      }

      return cloudIndex;
    }

    // Cloud fetch failed - return local
    return _readLocalIndex();
  }

  @override
  Future<void> updateIndex(CloudIndex index) async {
    // Write locally immediately (optimistic)
    await _writeLocalIndex(index);

    // Queue cloud upload asynchronously
    unawaited(_uploadIndexToCloud(index));
  }

  @override
  Future<IndexEntry?> getEntry(String bookId) async {
    final CloudIndex index = await getIndex();
    return index.getEntry(bookId);
  }

  @override
  Future<void> updateEntry(IndexEntry entry) async {
    final CloudIndex index = await getIndex();
    final CloudIndex updated = index.updateEntry(entry);
    await updateIndex(updated);
  }
}

/// Helper to allow unawaited futures without warnings
void unawaited(Future<void> future) {
  future.ignore();
}
