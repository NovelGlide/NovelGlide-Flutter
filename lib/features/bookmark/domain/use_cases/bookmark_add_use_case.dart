import 'package:novel_glide/core/log_system/log_system.dart';
import 'package:novel_glide/features/book_storage/domain/entities/bookmark_entry.dart';
import 'package:novel_glide/features/book_storage/domain/repositories/book_storage.dart';
import 'package:novel_glide/features/bookmark/domain/repositories/bookmark_repository.dart';

/// Use case for creating a new bookmark.
///
/// Adds a new bookmark to a book by creating a [BookmarkEntry]
/// and persisting it to the book's metadata.
class BookmarkAddUseCase {
  /// Creates a [BookmarkAddUseCase] instance.
  const BookmarkAddUseCase({
    required BookmarkRepository bookmarkRepository,
  }) : _bookmarkRepository = bookmarkRepository;

  final BookmarkRepository _bookmarkRepository;

  /// Executes the use case.
  ///
  /// [bookId] is the book to add the bookmark to.
  /// [entry] is the bookmark entry to add.
  /// Returns a future that completes when the operation is done.
  Future<void> call(
    BookId bookId,
    BookmarkEntry entry,
  ) async {
    try {
      await _bookmarkRepository.addBookmark(
        bookId,
        entry,
      );
    } catch (e, st) {
      LogSystem.error(
        'Error in BookmarkAddUseCase: $e',
        stackTrace: st,
      );
    }
  }
}
