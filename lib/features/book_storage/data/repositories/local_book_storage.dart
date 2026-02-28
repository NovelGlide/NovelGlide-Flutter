import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as path;

import '../../../../core/file_system/domain/repositories/file_system_repository.dart';
import '../../../../core/file_system/domain/repositories/json_repository.dart';
import '../../../../core/log_system/log_system.dart';
import '../../../../core/path_provider/domain/repositories/app_path_provider.dart';
import '../../domain/entities/book_metadata.dart';
import '../../domain/repositories/book_storage.dart';

/// Local device storage implementation of [BookStorage].
///
/// Stores books in the device filesystem under [AppPathProvider.libraryPath].
/// Each book gets its own folder with:
/// - book.epub: the book content
/// - metadata.json: the book metadata
///
/// All file path construction is private to this class; consumers interact
/// solely through [BookId] values.
class LocalBookStorage implements BookStorage {
  LocalBookStorage({
    required AppPathProvider appPathProvider,
    required FileSystemRepository fileSystemRepository,
    required JsonRepository jsonRepository,
  })  : _appPathProvider = appPathProvider,
        _fileSystemRepository = fileSystemRepository,
        _jsonRepository = jsonRepository;

  final AppPathProvider _appPathProvider;
  final FileSystemRepository _fileSystemRepository;
  final JsonRepository _jsonRepository;

  /// Stream controller for change notifications.
  /// Broadcast stream allows multiple listeners.
  final StreamController<BookId> _changeController =
      StreamController<BookId>.broadcast();

  /// Get the root library directory path.
  Future<String> _getLibraryPath() async {
    return await _appPathProvider.libraryPath;
  }

  /// Construct the full path for a book's folder.
  Future<String> _getBookFolderPath(BookId bookId) async {
    final libraryPath = await _getLibraryPath();
    return path.join(libraryPath, bookId);
  }

  /// Construct the full path for a book's content file.
  Future<String> _getBookContentPath(BookId bookId) async {
    final folderPath = await _getBookFolderPath(bookId);
    return path.join(folderPath, BookStorage.bookContentFilename);
  }

  /// Construct the full path for a book's metadata file.
  Future<String> _getMetadataPath(BookId bookId) async {
    final folderPath = await _getBookFolderPath(bookId);
    return path.join(folderPath, BookStorage.metadataFilename);
  }

  /// Emit a change notification for the given book.
  void _notifyChange(BookId bookId) {
    _changeController.add(bookId);
  }

  @override
  Future<bool> exists(BookId bookId) async {
    try {
      final folderPath = await _getBookFolderPath(bookId);
      final exists = await _fileSystemRepository.existsDirectory(folderPath);
      LogSystem.info('Checked existence of book $bookId: $exists');
      return exists;
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
      final bookExists = await exists(bookId);
      if (!bookExists) {
        throw BookNotFoundException(bookId: bookId);
      }

      final contentPath = await _getBookContentPath(bookId);
      final bytes = await _fileSystemRepository.readFileAsBytes(contentPath);
      LogSystem.info(
        'Read book content for $bookId: ${bytes.length} bytes',
      );
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
      final folderPath = await _getBookFolderPath(bookId);
      final contentPath = await _getBookContentPath(bookId);

      // Create folder if it doesn't exist
      await _fileSystemRepository.createDirectory(folderPath);
      LogSystem.info('Created book folder for $bookId at $folderPath');

      // Convert List<int> to Uint8List and write the book content
      final uint8bytes = Uint8List.fromList(bytes);
      await _fileSystemRepository.writeFileAsBytes(contentPath, uint8bytes);
      LogSystem.info('Wrote book content for $bookId: ${bytes.length} bytes');

      // Emit change notification
      _notifyChange(bookId);
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
      final folderPath = await _getBookFolderPath(bookId);

      // Check if the book folder exists
      final exists = await _fileSystemRepository.existsDirectory(folderPath);

      if (exists) {
        // Delete the entire book folder and contents
        await _fileSystemRepository.deleteDirectory(folderPath);
        LogSystem.info('Deleted book folder for $bookId');

        // Emit change notification
        _notifyChange(bookId);
      } else {
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
      final metadataPath = await _getMetadataPath(bookId);

      // Check if metadata file exists
      final fileExists = await _fileSystemRepository.existsFile(metadataPath);
      if (!fileExists) {
        LogSystem.info('Metadata file not found for book $bookId');
        return null;
      }

      // Read the metadata JSON
      final jsonData = await _jsonRepository.readJson(path: metadataPath);

      // Deserialize to BookMetadata
      final metadata = BookMetadata.fromJson(jsonData);
      LogSystem.info('Read metadata for book $bookId');
      return metadata;
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
      final folderPath = await _getBookFolderPath(bookId);
      final metadataPath = await _getMetadataPath(bookId);

      // Create folder if it doesn't exist
      await _fileSystemRepository.createDirectory(folderPath);
      LogSystem.info('Created book folder for $bookId at $folderPath');

      // Serialize and write metadata
      final jsonData = metadata.toJson();
      await _jsonRepository.writeJson(path: metadataPath, data: jsonData);
      LogSystem.info('Wrote metadata for book $bookId');

      // Emit change notification
      _notifyChange(bookId);
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
      final libraryPath = await _getLibraryPath();

      // Check if library path exists
      final libraryExists =
          await _fileSystemRepository.existsDirectory(libraryPath);
      if (!libraryExists) {
        LogSystem.info('Library directory does not exist yet');
        return [];
      }

      // List immediate subdirectories
      final bookIds = <BookId>[];
      final entities = _fileSystemRepository.listDirectory(libraryPath);

      await for (final entity in entities) {
        // Only include directories (each directory is a book)
        if (entity is Directory) {
          final bookId = path.basename(entity.path);
          bookIds.add(bookId);
        }
      }

      LogSystem.info('Listed ${bookIds.length} books in library');
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
    LogSystem.info('LocalBookStorage disposed');
  }
}
