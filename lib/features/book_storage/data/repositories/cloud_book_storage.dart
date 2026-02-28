import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as path;

import 'package:novel_glide/core/log_system/log_system.dart';
import 'package:novel_glide/features/cloud/domain/entities/cloud_file.dart';
import 'package:novel_glide/features/cloud/domain/entities/cloud_providers.dart';
import 'package:novel_glide/features/cloud/domain/entities/drive_file_metadata.dart';
import 'package:novel_glide/features/cloud/domain/repositories/cloud_repository.dart';
import 'package:novel_glide/features/book_storage/domain/entities/book_metadata.dart';
import 'package:novel_glide/features/book_storage/domain/repositories/book_storage.dart';

/// Cloud storage implementation of [BookStorage].
///
/// Stores books in Google Drive's appDataFolder under a "books/" prefix.
/// Each book gets its own folder with:
/// - book.epub: the book content
/// - metadata.json: the book metadata
/// - history/: timestamped metadata snapshots (cloud only)
///
/// All path construction is private to this class; consumers interact
/// solely through [BookId] values.
class CloudBookStorage implements BookStorage {
  /// Creates a [CloudBookStorage] instance.
  ///
  /// Requires a [CloudRepository] for all cloud operations.
  CloudBookStorage({
    required CloudRepository cloudRepository,
  }) : _cloudRepository = cloudRepository;

  final CloudRepository _cloudRepository;

  /// Stream controller for change notifications.
  ///
  /// Broadcast stream allows multiple listeners to subscribe.
  final StreamController<BookId> _changeController =
      StreamController<BookId>.broadcast();

  /// Root path prefix for all books in cloud storage.
  ///
  /// All paths are relative to Google Drive's appDataFolder.
  static const String _booksRootPath = 'books';

  /// History folder name within each book folder (cloud only).
  static const String _historyFolderName = 'history';

  /// Cloud provider to use for all operations.
  static const CloudProviders _provider = CloudProviders.google;

  /// Construct the cloud path for a book's folder.
  ///
  /// Returns: "books/{bookId}"
  String _getBookFolderPath(BookId bookId) {
    return '$_booksRootPath/$bookId';
  }

  /// Construct the cloud path for a book's history folder.
  ///
  /// Returns: "books/{bookId}/history"
  String _getHistoryFolderPath(BookId bookId) {
    return '${_getBookFolderPath(bookId)}/$_historyFolderName';
  }

  /// Construct the cloud path for a timestamped metadata snapshot.
  ///
  /// Returns: "books/{bookId}/history/{ISO8601timestamp}.json"
  String _getHistorySnapshotPath(
    BookId bookId,
    String timestamp,
  ) {
    return '${_getHistoryFolderPath(bookId)}/$timestamp.json';
  }

  /// Convert [DriveFileMetadata] to [CloudFile] for download operations.
  CloudFile _driveFileMetadataToCloudFile(
    DriveFileMetadata metadata,
  ) {
    return CloudFile(
      identifier: metadata.fileId,
      name: metadata.name,
      length: 0,
      modifiedTime: metadata.modifiedTime,
    );
  }

  /// Emit a change notification for the given [bookId].
  void _notifyChange(BookId bookId) {
    _changeController.add(bookId);
  }

  /// Create a temporary file from bytes for uploading.
  ///
  /// Returns the File object that can be used with uploadFileToPath.
  /// Note: Caller is responsible for cleanup.
  Future<File> _createTempFile(List<int> bytes) async {
    final Directory tempDir =
        await Directory.systemTemp.createTemp('cloud_book_');
    final File tempFile = File(path.join(tempDir.path, 'temp_upload'));
    await tempFile.writeAsBytes(bytes);
    return tempFile;
  }

  @override
  Future<bool> exists(BookId bookId) async {
    try {
      final String folderPath = _getBookFolderPath(bookId);

      try {
        final List<DriveFileMetadata> contents =
            await _cloudRepository.listFolderContents(
          _provider,
          folderPath,
        );
        final bool bookExists = contents.any(
          (DriveFileMetadata item) =>
              item.name == BookStorage.bookContentFilename && item.isFile,
        );
        LogSystem.info('Checked existence of book $bookId: $bookExists');
        return bookExists;
      } on Exception {
        LogSystem.info('Book folder for $bookId does not exist');
        return false;
      }
    } catch (error, stackTrace) {
      LogSystem.error(
        'Failed to check existence of book $bookId',
        error: error,
        stackTrace: stackTrace,
      );
      throw BookStorageException(
        message: 'Failed to check existence of book $bookId',
        originalError: error,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<List<int>> readBytes(BookId bookId) async {
    try {
      final bool bookExists = await exists(bookId);
      if (!bookExists) {
        throw BookNotFoundException(bookId: bookId);
      }

      final String folderPath = _getBookFolderPath(bookId);
      final List<DriveFileMetadata> contents =
          await _cloudRepository.listFolderContents(
        _provider,
        folderPath,
      );
      final DriveFileMetadata bookFileMetadata = contents.firstWhere(
        (DriveFileMetadata item) =>
            item.name == BookStorage.bookContentFilename && item.isFile,
        orElse: () => throw BookNotFoundException(bookId: bookId),
      );

      final CloudFile cloudFile =
          _driveFileMetadataToCloudFile(bookFileMetadata);

      final List<int> bytes = <int>[];
      await for (final Uint8List chunk in _cloudRepository.downloadFile(
        _provider,
        cloudFile,
      )) {
        bytes.addAll(chunk);
      }

      LogSystem.info('Read book content for $bookId: ${bytes.length} bytes');
      return bytes;
    } on BookNotFoundException {
      rethrow;
    } catch (error, stackTrace) {
      LogSystem.error(
        'Failed to read book content for $bookId',
        error: error,
        stackTrace: stackTrace,
      );
      throw BookStorageException(
        message: 'Failed to read book content for $bookId',
        originalError: error,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<void> writeBytes(
    BookId bookId,
    List<int> bytes,
  ) async {
    try {
      final String folderPath = _getBookFolderPath(bookId);
      final File tempFile = await _createTempFile(bytes);

      try {
        await _cloudRepository.uploadFileToPath(
          _provider,
          tempFile,
          folderPath,
        );

        LogSystem.info('Wrote book content for $bookId: ${bytes.length} bytes');
        _notifyChange(bookId);
      } finally {
        await tempFile.delete();
        await tempFile.parent.delete();
      }
    } catch (error, stackTrace) {
      LogSystem.error(
        'Failed to write book content for $bookId',
        error: error,
        stackTrace: stackTrace,
      );
      throw BookStorageException(
        message: 'Failed to write book content for $bookId',
        originalError: error,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<void> delete(BookId bookId) async {
    try {
      final String folderPath = _getBookFolderPath(bookId);

      try {
        await _cloudRepository.listFolderContents(_provider, folderPath);
        await _cloudRepository.deleteFolder(_provider, folderPath);
        LogSystem.info('Deleted book folder for $bookId');
        _notifyChange(bookId);
      } on Exception {
        LogSystem.info('Book $bookId does not exist, delete is idempotent');
      }
    } catch (error, stackTrace) {
      LogSystem.error(
        'Failed to delete book $bookId',
        error: error,
        stackTrace: stackTrace,
      );
      throw BookStorageException(
        message: 'Failed to delete book $bookId',
        originalError: error,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<BookMetadata?> readMetadata(BookId bookId) async {
    try {
      final String folderPath = _getBookFolderPath(bookId);

      try {
        final List<DriveFileMetadata> contents =
            await _cloudRepository.listFolderContents(
          _provider,
          folderPath,
        );
        final DriveFileMetadata metadataFileMetadata = contents.firstWhere(
          (DriveFileMetadata item) =>
              item.name == BookStorage.metadataFilename && item.isFile,
          orElse: () => throw Exception('Metadata file not found'),
        );

        final CloudFile cloudFile =
            _driveFileMetadataToCloudFile(metadataFileMetadata);

        final List<int> bytes = <int>[];
        await for (final Uint8List chunk in _cloudRepository.downloadFile(
          _provider,
          cloudFile,
        )) {
          bytes.addAll(chunk);
        }

        final String jsonString = utf8.decode(bytes);
        final Map<String, dynamic> jsonData =
            jsonDecode(jsonString) as Map<String, dynamic>;

        final BookMetadata metadata = BookMetadata.fromJson(jsonData);
        LogSystem.info('Read metadata for book $bookId');
        return metadata;
      } on Exception catch (e) {
        if (e.toString().contains('Metadata file not found')) {
          LogSystem.info('Metadata file not found for book $bookId');
          return null;
        }
        rethrow;
      }
    } catch (error, stackTrace) {
      LogSystem.error(
        'Failed to read metadata for book $bookId',
        error: error,
        stackTrace: stackTrace,
      );
      throw BookStorageException(
        message: 'Failed to read metadata for book $bookId',
        originalError: error,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<void> writeMetadata(
    BookId bookId,
    BookMetadata metadata,
  ) async {
    try {
      final String folderPath = _getBookFolderPath(bookId);
      final Map<String, dynamic> jsonData = metadata.toJson();
      final String jsonString = jsonEncode(jsonData);
      final List<int> metadataBytes = utf8.encode(jsonString);

      final File tempMetadataFile = await _createTempFile(metadataBytes);

      try {
        await _cloudRepository.uploadFileToPath(
          _provider,
          tempMetadataFile,
          folderPath,
        );

        LogSystem.info('Wrote metadata for book $bookId');

        final String timestamp = DateTime.now().toUtc().toIso8601String();
        final String historySnapshotPath =
            _getHistorySnapshotPath(bookId, timestamp);

        await _cloudRepository.uploadFileToPath(
          _provider,
          tempMetadataFile,
          '${_getHistoryFolderPath(bookId)}/$timestamp',
        );

        LogSystem.info(
          'Created metadata snapshot for book $bookId '
          'at $historySnapshotPath',
        );

        _notifyChange(bookId);
      } finally {
        await tempMetadataFile.delete();
        await tempMetadataFile.parent.delete();
      }
    } catch (error, stackTrace) {
      LogSystem.error(
        'Failed to write metadata for book $bookId',
        error: error,
        stackTrace: stackTrace,
      );
      throw BookStorageException(
        message: 'Failed to write metadata for book $bookId',
        originalError: error,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Future<List<BookId>> listBookIds() async {
    try {
      final List<DriveFileMetadata> contents =
          await _cloudRepository.listFolderContents(
        _provider,
        _booksRootPath,
      );

      final List<String> bookIds = <String>[];
      for (final DriveFileMetadata item in contents) {
        if (item.isFolder) {
          bookIds.add(item.name);
        }
      }

      LogSystem.info('Listed ${bookIds.length} books from cloud storage');
      return bookIds;
    } catch (error, stackTrace) {
      LogSystem.error(
        'Failed to list book IDs',
        error: error,
        stackTrace: stackTrace,
      );
      throw BookStorageException(
        message: 'Failed to list book IDs',
        originalError: error,
        stackTrace: stackTrace,
      );
    }
  }

  @override
  Stream<BookId> changeStream() {
    return _changeController.stream;
  }

  /// Close the change stream controller.
  ///
  /// Should be called when the app is closing.
  Future<void> dispose() async {
    await _changeController.close();
    LogSystem.info('CloudBookStorage disposed');
  }
}
