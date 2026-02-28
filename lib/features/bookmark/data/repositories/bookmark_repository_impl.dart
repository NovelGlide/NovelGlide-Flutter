import 'package:novel_glide/core/log_system/log_system.dart';
import 'package:novel_glide/features/book_storage/data/repositories/local_book_storage.dart';
import 'package:novel_glide/features/book_storage/domain/entities/book_metadata.dart';
import 'package:novel_glide/features/book_storage/domain/entities/bookmark_entry.dart';
import 'package:novel_glide/features/book_storage/domain/repositories/book_storage.dart';
import 'package:novel_glide/features/bookmark/domain/entities/bookmark_item.dart';
import 'package:novel_glide/features/bookmark/domain/repositories/bookmark_cache_repository.dart';
import 'package:novel_glide/features/bookmark/domain/repositories/bookmark_repository.dart';

/// Implementation of [BookmarkRepository].
///
/// Coordinates between [BookmarkCacheRepository] for fast reads and
/// [LocalBookStorage] for persistent writes. Uses reactive cache
/// updates for high performance.
class BookmarkRepositoryImpl implements BookmarkRepository {
  /// Creates a [BookmarkRepositoryImpl] instance.
  BookmarkRepositoryImpl({
    required BookmarkCacheRepository
        bookmarkCacheRepository,
    required LocalBookStorage localBookStorage,
  })  : _bookmarkCacheRepository =
            bookmarkCacheRepository,
        _localBookStorage = localBookStorage;

  final BookmarkCacheRepository
      _bookmarkCacheRepository;
  final LocalBookStorage _localBookStorage;

  @override
  Future<List<BookmarkItem>> getAll() async {
    try {
      return await _bookmarkCacheRepository
          .getAllBookmarks();
    } catch (e, st) {
      LogSystem.error(
        'Error getting all bookmarks: $e',
        stackTrace: st,
      );
      return <BookmarkItem>[];
    }
  }

  @override
  Future<BookmarkItem?> getById(
    String entryId,
  ) async {
    try {
      final List<BookmarkItem> all =
          await _bookmarkCacheRepository
              .getAllBookmarks();

      try {
        return all.firstWhere(
          (BookmarkItem item) =>
              item.id == entryId,
        );
      } catch (e) {
        return null;
      }
    } catch (e, st) {
      LogSystem.error(
        'Error getting bookmark by ID: $e',
        stackTrace: st,
      );
      return null;
    }
  }

  @override
  Future<void> addBookmark(
    BookId bookId,
    BookmarkEntry entry,
  ) async {
    try {
      // Read current metadata
      final BookMetadata? metadata =
          await _localBookStorage
              .getMetadata(bookId);

      if (metadata == null) {
        LogSystem.warning(
          'Cannot add bookmark: Book $bookId not found',
        );
        return;
      }

      // Add entry to bookmarks list
      final List<BookmarkEntry> updated =
          <BookmarkEntry>[...metadata.bookmarks, entry];

      // Update metadata with new bookmarks
      final BookMetadata newMetadata =
          metadata.copyWith(bookmarks: updated);

      // Write back to storage
      await _localBookStorage.updateMetadata(
        bookId,
        newMetadata,
      );

      LogSystem.info(
        'Added bookmark to book $bookId: ${entry.id}',
      );
    } catch (e, st) {
      LogSystem.error(
        'Error adding bookmark: $e',
        stackTrace: st,
      );
    }
  }

  @override
  Future<void> deleteBookmarks(
    List<String> entryIds,
  ) async {
    try {
      if (entryIds.isEmpty) {
        return;
      }

      // Find which books contain these entries
      final Map<BookId, List<String>>
          bookToEntries =
          <BookId, List<String>>{};

      final List<BookmarkItem> allItems =
          await _bookmarkCacheRepository
              .getAllBookmarks();

      for (final BookmarkItem item in allItems) {
        if (entryIds.contains(item.id)) {
          bookToEntries
              .putIfAbsent(
                item.bookId,
                () => <String>[],
              )
              .add(item.id);
        }
      }

      // Update each affected book
      for (final String bookId
          in bookToEntries.keys) {
        final BookMetadata? metadata =
            await _localBookStorage
                .getMetadata(bookId);

        if (metadata == null) {
          continue;
        }

        final List<String> idsToRemove =
            bookToEntries[bookId]!;

        final List<BookmarkEntry> updated =
            metadata.bookmarks
                .where(
                  (BookmarkEntry entry) =>
                      !idsToRemove.contains(
                        entry.id,
                      ),
                )
                .toList();

        final BookMetadata newMetadata =
            metadata.copyWith(
          bookmarks: updated,
        );

        await _localBookStorage.updateMetadata(
          bookId,
          newMetadata,
        );

        LogSystem.info(
          'Deleted ${idsToRemove.length} bookmarks'
          ' from book $bookId',
        );
      }
    } catch (e, st) {
      LogSystem.error(
        'Error deleting bookmarks: $e',
        stackTrace: st,
      );
    }
  }

  @override
  Stream<void> observeChanges() {
    return _bookmarkCacheRepository.onChanged
        .map((_) => null);
  }

  @override
  Future<void> rebuildCache() async {
    try {
      await _bookmarkCacheRepository
          .rebuildCache();
      LogSystem.info(
        'Successfully rebuilt bookmark cache',
      );
    } catch (e, st) {
      LogSystem.error(
        'Error rebuilding cache: $e',
        stackTrace: st,
      );
    }
  }
}
