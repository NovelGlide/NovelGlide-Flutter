import 'dart:async';

import 'package:novel_glide/features/book_storage/domain/entities/book_metadata.dart';

/// Type alias for a book's unique identifier (UUID v4 string).
/// Generated once when a book is added and never changes for its lifetime.
typedef BookId = String;

/// Exception thrown when a book storage operation fails.
class BookStorageException implements Exception {
  /// Creates a [BookStorageException].
  BookStorageException({
    required this.message,
    this.originalError,
    this.stackTrace,
  });

  /// Human-readable error message describing the failure.
  final String message;

  /// The underlying error that caused this exception, if any.
  final Object? originalError;

  /// Stack trace from the original error, if available.
  final StackTrace? stackTrace;

  @override
  String toString() => 'BookStorageException: $message';
}

/// Exception thrown when a requested book is not found.
class BookNotFoundException extends BookStorageException {
  /// Creates a [BookNotFoundException] for the given [bookId].
  BookNotFoundException({required BookId bookId})
      : super(message: 'Book not found: $bookId');
}

/// Abstract interface for storing and retrieving book content and metadata.
///
/// Provides a unified API for both local device storage and cloud storage
/// implementations. All callers identify books solely by [BookId]; file paths
/// and cloud IDs are implementation details hidden from consumers.
///
/// Concrete implementations: [LocalBookStorage], [CloudBookStorage]
abstract class BookStorage {
  /// Filename for the book content file (EPUB).
  static const String bookContentFilename = 'book.epub';

  /// Filename for the metadata JSON file.
  static const String metadataFilename = 'metadata.json';

  /// Check if a book with the given [bookId] exists in storage.
  ///
  /// Throws [BookStorageException] if the check fails.
  Future<bool> exists(BookId bookId);

  /// Read the raw bytes of a book's content file.
  ///
  /// Throws [BookNotFoundException] if no book with this [bookId] exists.
  /// Throws [BookStorageException] for other failures.
  Future<List<int>> readBytes(BookId bookId);

  /// Write a book's content file to storage.
  ///
  /// Creates the book folder if it does not already exist.
  /// Emits a change notification after successful write.
  ///
  /// Throws [BookStorageException] if the write fails.
  Future<void> writeBytes(
    BookId bookId,
    List<int> bytes,
  );

  /// Delete a book entirely from storage.
  ///
  /// Removes the entire book folder and all its contents.
  /// Emits a change notification after successful delete.
  ///
  /// Does nothing if the book does not exist (idempotent).
  /// Throws [BookStorageException] if the delete fails.
  Future<void> delete(BookId bookId);

  /// Read the metadata for a book.
  ///
  /// Returns null if no metadata exists yet for this book.
  /// Throws [BookStorageException] if the read fails.
  Future<BookMetadata?> readMetadata(BookId bookId);

  /// Write metadata for a book to storage.
  ///
  /// Emits a change notification after successful write.
  ///
  /// Throws [BookStorageException] if the write fails.
  Future<void> writeMetadata(
    BookId bookId,
    BookMetadata metadata,
  );

  /// List all [BookId] values present in this storage.
  ///
  /// Returns an empty list if no books are stored.
  /// Throws [BookStorageException] if the listing fails.
  Future<List<BookId>> listBookIds();

  /// Stream that emits a [BookId] whenever that book is written or deleted.
  ///
  /// Consumers subscribe to this stream to react to changes without polling.
  /// The stream is infinite and does not close naturally.
  Stream<BookId> changeStream();
}
