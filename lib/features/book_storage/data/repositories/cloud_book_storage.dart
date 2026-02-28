import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as path;

import '../../../../core/log_system/log_system.dart';
import '../../../cloud/domain/entities/cloud_file.dart';
import '../../../cloud/domain/entities/cloud_providers.dart';
import '../../../cloud/domain/entities/drive_file_metadata.dart';
import '../../../cloud/domain/repositories/cloud_repository.dart';
import '../../domain/entities/book_metadata.dart';
import '../../domain/repositories/book_storage.dart';

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
  CloudBookStorage({
    required CloudRepository cloudRepository,
  }) : _cloudRepository = cloudRepository;

  final CloudRepository _cloudRepository;

  /// Stream controller for change notifications.
  /// Broadcast stream allows multiple listeners.
  final StreamController<BookId> _changeController =
      StreamController<BookId>.broadcast();

  /// Root path prefix for all books in cloud storage.
  /// All paths are relative to Google Drive's appDataFolder.
  static const String _booksRootPath = 'books';

  /// History folder name within each book folder (cloud only).
  static const String _historyFolderName = 'history';

  /// Cloud provider to use for all operations.
  static const CloudProviders _provider = CloudProviders.google;

  /// Construct the cloud path for a book's folder.
  /// Returns: "books/{bookId}"
  String _getBookFolderPath(BookId bookId) {
    return '$_booksRootPath/$bookId';
  }

  /// Construct the cloud path for a book's history folder.
  /// Returns: "books/{bookId}/history"
  String _getHistoryFolderPath(BookId bookId) {
    return '${_getBookFolderPath(bookId)}/$_historyFolderName';
  }

  /// Construct the cloud path for a timestamped metadata snapshot.
  /// Returns: "books/{bookId}/history/{ISO8601timestamp}.json"
  String _getHistorySnapshotPath(BookId bookId, String timestamp) {
    return '${_getHistoryFolderPath(bookId)}/$timestamp.json';
  }

  /// Convert DriveFileMetadata to CloudFile for download operations.
  CloudFile _driveFileMetadataToCloudFile(
    DriveFileMetadata metadata,
  ) {
    return CloudFile(
      identifier: metadata.fileId,
      name: metadata.name,
      length: 0, // Size not available from DriveFileMetadata
      modifiedTime: metadata.modifiedTime,
    );
  }

  /// Emit a change notification for the given book.
  void _notifyChange(BookId bookId) {
    _changeController.add(bookId);
  }

  /// Create a temporary file from bytes for uploading.
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

      // List the folder contents to see if the book.epub file exists
      try {
        final List<DriveFileMetadata> contents =
            await _cloudRepository.listFolderContents(_provider, folderPath);
        final bool bookExists = contents.any(
          (DriveFileMetadata item) =>
              item.name == BookStorage.bookContentFilename && item.isFile,
        );
        LogSystem.info('Checked existence of book $bookId: $bookExists');
        return bookExists;
      } on Exception {
        // Folder doesn't exist, so book doesn't exist
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
      // Check if book exists first
      final bool bookExists = await exists(bookId);
      if (!bookExists) {
        throw BookNotFoundException(bookId: bookId);
      }

      final String folderPath = _getBookFolderPath(bookId);

      // List folder contents to get the book.epub file metadata
      final List<DriveFileMetadata> contents =
          await _cloudRepository.listFolderContents(_provider, folderPath);
      final DriveFileMetadata bookFileMetadata = contents.firstWhere(
        (DriveFileMetadata item) =>
            item.name == BookStorage.bookContentFilename && item.isFile,
        orElse: () => throw BookNotFoundException(bookId: bookId),
      );

      // Convert metadata to CloudFile and download
      final CloudFile cloudFile = _driveFileMetadataToCloudFile(bookFileMetadata);

      // Download the file
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
  Future<void> writeBytes(BookId bookId, List<int> bytes) async {
    try {
      final String folderPath = _getBookFolderPath(bookId);

      // Create temporary file for upload
      final File tempFile = await _createTempFile(bytes);

      try {
        // Upload the file to the cloud folder
        await _cloudRepository.uploadFileToPath(
          _provider,
          tempFile,
          folderPath,
        );

        LogSystem.info('Wrote book content for $bookId: ${bytes.length} bytes');

        // Emit change notification
        _notifyChange(bookId);
      } finally {
        // Clean up temporary file
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

      // Try to list the folder to see if it exists
      try {
        await _cloudRepository.listFolderContents(_provider, folderPath);
        // Folder exists, delete it
        await _cloudRepository.deleteFolder(_provider, folderPath);
        LogSystem.info('Deleted book folder for $bookId');

        // Emit change notification
        _notifyChange(bookId);
      } on Exception {
        // Folder doesn't exist, delete is idempotent
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

      // List folder contents to check if metadata.json exists
      try {
        final List<DriveFileMetadata> contents =
            await _cloudRepository.listFolderContents(_provider, folderPath);
        final DriveFileMetadata metadataFileMetadata = contents.firstWhere(
          (DriveFileMetadata item) =>
              item.name == BookStorage.metadataFilename && item.isFile,
          orElse: () => throw Exception('Metadata file not found'),
        );

        // Convert metadata to CloudFile and download
        final CloudFile cloudFile =
            _driveFileMetadataToCloudFile(metadataFileMetadata);

        // Download the metadata file
        final List<int> bytes = <int>[];
        await for (final Uint8List chunk in _cloudRepository.downloadFile(
          _provider,
          cloudFile,
        )) {
          bytes.addAll(chunk);
        }

        // Convert bytes to JSON
        final String jsonString = utf8.decode(bytes);
        final Map<String, dynamic> jsonData =
            jsonDecode(jsonString) as Map<String, dynamic>;

        // Deserialize to BookMetadata
        final BookMetadata metadata = BookMetadata.fromJson(jsonData);
        LogSystem.info('Read metadata for book $bookId');
        return metadata;
      } on Exception catch (e) {
        // Folder or metadata file doesn't exist
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
  Future<void> writeMetadata(BookId bookId, BookMetadata metadata) async {
    try {
      final String folderPath = _getBookFolderPath(bookId);

      // Serialize metadata to JSON
      final Map<String, dynamic> jsonData = metadata.toJson();
      final String jsonString = jsonEncode(jsonData);
      final List<int> metadataBytes = utf8.encode(jsonString);

      // Create temporary file for metadata
      final File tempMetadataFile = await _createTempFile(metadataBytes);

      try {
        // Upload metadata.json
        await _cloudRepository.uploadFileToPath(
          _provider,
          tempMetadataFile,
          folderPath,
        );

        LogSystem.info('Wrote metadata for book $bookId');

        // Create timestamped snapshot in history folder (cloud only)
        final String timestamp = DateTime.now().toUtc().toIso8601String();
        final String historySnapshotPath =
            _getHistorySnapshotPath(bookId, timestamp);

        // Upload the same metadata to history folder with timestamp
        await _cloudRepository.uploadFileToPath(
          _provider,
          tempMetadataFile,
          '${_getHistoryFolderPath(bookId)}/$timestamp',
        );

        LogSystem.info(
          'Created metadata snapshot for book $bookId at $historySnapshotPath',
        );

        // Emit change notification
        _notifyChange(bookId);
      } finally {
        // Clean up temporary file
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
      // List immediate subfolders of "books/" folder
      final List<DriveFileMetadata> contents =
          await _cloudRepository.listFolderContents(
        _provider,
        _booksRootPath,
      );

      // Filter for folders only; each folder name is a BookId
      final List<String> bookIds = <String>[];
      contents
          .where((DriveFileMetadata item) => item.isFolder)
          .forEach((DriveFileMetadata item) {
        bookIds.add(item.name);
      });

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
  /// Should be called when the app is closing.
  Future<void> dispose() async {
    await _changeController.close();
    LogSystem.info('CloudBookStorage disposed');
  }
}
