import 'package:novel_glide/features/book_storage/domain/entities/bookmark_entry.dart';
import 'package:novel_glide/features/book_storage/domain/repositories/book_storage.dart';
import 'package:novel_glide/features/bookmark/domain/entities/bookmark_item.dart';

/// Abstract interface for bookmark caching layer.
///
/// The cache layer maintains a fast-read collection of all bookmarks
/// across all books. It subscribes to [LocalBookStorage.onChanged] to
/// stay synchronized with the source of truth (metadata.json files).
///
/// Cache is always disposable and can be rebuilt from [LocalBookStorage]
/// at any time via [rebuildCache].
abstract class BookmarkCacheRepository {
  /// Gets all bookmarks across all books.
  ///
  /// Returns a list of all [BookmarkItem] instances, ordered by
  /// creation time (newest first).
  Future<List<BookmarkItem>> getAllBookmarks();

  /// Gets all bookmarks for a specific book.
  ///
  /// Returns a list of [BookmarkItem] instances for the book with the
  /// given [bookId], ordered by creation time (newest first).
  /// Returns an empty list if the book has no bookmarks.
  Future<List<BookmarkItem>> getBookmarksForBook(
    BookId bookId,
  );

  /// Updates bookmarks for a specific book.
  ///
  /// Called when a book's metadata is updated with new or modified
  /// bookmark entries. Updates the cache to reflect the new state
  /// of bookmarks for the given [bookId].
  Future<void> updateBookEntry(
    BookId bookId,
    List<BookmarkEntry> entries,
  );

  /// Removes all bookmarks for a specific book.
  ///
  /// Called when a book is deleted or all its bookmarks are cleared.
  Future<void> removeBook(BookId bookId);

  /// Rebuilds the entire cache from the source of truth.
  ///
  /// Reads all book metadata from [LocalBookStorage], aggregates all
  /// bookmarks, and writes the complete cache to disk.
  /// Use when the cache becomes corrupted or to ensure consistency
  /// after offline changes.
  Future<void> rebuildCache();

  /// Stream of book IDs that have changed.
  ///
  /// Emits a [BookId] whenever bookmarks in a book are updated.
  /// Multiple subscribers are supported (broadcast stream).
  Stream<BookId> get onChanged;
}
