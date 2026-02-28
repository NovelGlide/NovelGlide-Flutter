import 'package:novel_glide/features/book_storage/domain/entities/bookmark_entry.dart';
import 'package:novel_glide/features/book_storage/domain/repositories/book_storage.dart';
import 'package:novel_glide/features/bookmark/domain/entities/bookmark_item.dart';

/// High-level bookmark repository interface.
///
/// Provides the main API for bookmark operations. Internally uses
/// [BookmarkCacheRepository] for fast reads and [LocalBookStorage]
/// for persistent writes.
abstract class BookmarkRepository {
  /// Gets all bookmarks across all books.
  ///
  /// Returns a list of all [BookmarkItem] instances, ordered by
  /// creation time (newest first).
  Future<List<BookmarkItem>> getAll();

  /// Gets a specific bookmark by ID.
  ///
  /// Returns the [BookmarkItem] with the given [entryId], or null
  /// if not found.
  Future<BookmarkItem?> getById(String entryId);

  /// Creates a new bookmark in a book.
  ///
  /// Adds a new [BookmarkEntry] to the given [bookId]'s metadata,
  /// persisting it to disk. The cache updates reactively.
  Future<void> addBookmark(
    BookId bookId,
    BookmarkEntry entry,
  );

  /// Deletes multiple bookmarks by ID.
  ///
  /// Removes the given bookmark entries from their respective books'
  /// metadata. Handles multiple books efficiently (batches updates
  /// by book). The cache updates reactively.
  Future<void> deleteBookmarks(
    List<String> entryIds,
  );

  /// Observes changes to any bookmark.
  ///
  /// Returns a stream that emits whenever any bookmark is added,
  /// modified, or deleted. Useful for reactive UI updates.
  Stream<void> observeChanges();

  /// Rebuilds the bookmark cache from the source of truth.
  ///
  /// Reads all book metadata from [LocalBookStorage], aggregates all
  /// bookmarks, and writes a fresh cache. Use when the cache becomes
  /// corrupted or to ensure consistency after offline changes.
  Future<void> rebuildCache();
}
