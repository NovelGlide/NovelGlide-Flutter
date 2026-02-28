import 'dart:async';
import 'dart:convert';

import 'package:novel_glide/core/file_system/domain/repositories/json_repository.dart';
import 'package:novel_glide/core/log_system/log_system.dart';
import 'package:novel_glide/core/path_provider/domain/repositories/app_path_provider.dart';
import 'package:novel_glide/features/book_storage/data/repositories/local_book_storage.dart';
import 'package:novel_glide/features/book_storage/domain/entities/book_metadata.dart';
import 'package:novel_glide/features/book_storage/domain/entities/bookmark_entry.dart';
import 'package:novel_glide/features/book_storage/domain/repositories/book_storage.dart';
import 'package:novel_glide/features/bookmark/domain/entities/bookmark_item.dart';
import 'package:novel_glide/features/bookmark/domain/repositories/bookmark_cache_repository.dart';
import 'package:path/path.dart' as path;

/// Implementation of [BookmarkCacheRepository] using local JSON cache.
///
/// Maintains a fast-read cache file (bookmark_cache.json) that mirrors
/// all bookmarks from all books' metadata.json files. Subscribes to
/// [LocalBookStorage.onChanged] for reactive updates.
///
/// Cache file structure:
/// {
///   "bookId1": [
///     {"id": "...", "bookId": "...", "position": "...", ...},
///     ...
///   ],
///   "bookId2": [...]
/// }
class BookmarkCacheRepositoryImpl implements BookmarkCacheRepository {
  /// Creates a [BookmarkCacheRepositoryImpl] instance.
  BookmarkCacheRepositoryImpl({
    required LocalBookStorage localBookStorage,
    required JsonRepository jsonRepository,
    required AppPathProvider appPathProvider,
  })  : _localBookStorage = localBookStorage,
        _jsonRepository = jsonRepository,
        _appPathProvider = appPathProvider {
    _initializeCache();
  }

  final LocalBookStorage _localBookStorage;
  final JsonRepository _jsonRepository;
  final AppPathProvider _appPathProvider;

  /// In-memory cache: Map<BookId, List<BookmarkItem>>
  final Map<String, List<BookmarkItem>> _cache =
      <String, List<BookmarkItem>>{};

  /// Stream controller for change notifications.
  final StreamController<BookId> _changeController =
      StreamController<BookId>.broadcast();

  /// Flag to track initialization.
  bool _initialized = false;

  /// Subscribes to LocalBookStorage.onChanged and rebuilds cache.
  void _initializeCache() {
    _localBookStorage.onChanged.listen((BookId bookId) {
      _handleBookChanged(bookId);
    });
  }

  /// Handle a book change notification from LocalBookStorage.
  ///
  /// Hot path: Read the updated book metadata and update the
  /// cache for that specific book.
  Future<void> _handleBookChanged(BookId bookId) async {
    try {
      final bool exists =
          await _localBookStorage.exists(bookId);

      if (!exists) {
        // Book was deleted
        _cache.remove(bookId);
        await _saveCacheFile();
        _changeController.add(bookId);
        return;
      }

      // Read updated metadata
      final BookMetadata? metadata =
          await _localBookStorage.getMetadata(bookId);

      if (metadata == null) {
        _cache.remove(bookId);
        await _saveCacheFile();
        _changeController.add(bookId);
        return;
      }

      // Convert BookmarkEntry list to BookmarkItem list
      final List<BookmarkItem> items =
          metadata.bookmarks
              .map(
                (BookmarkEntry entry) =>
                    BookmarkItem.fromBookmarkEntry(
                  entry,
                  metadata.title,
                  bookId,
                ),
              )
              .toList();

      _cache[bookId] = items;
      await _saveCacheFile();
      _changeController.add(bookId);

      LogSystem.info(
        'Updated cache for book $bookId with'
        ' ${items.length} bookmarks',
      );
    } catch (e, st) {
      LogSystem.error(
        'Error handling book change for $bookId: $e',
        stackTrace: st,
      );
    }
  }

  /// Get the path to the cache file.
  Future<String> _getCachePath() async {
    final String dataPath =
        await _appPathProvider.dataPath;
    return path.join(dataPath, 'bookmark_cache.json');
  }

  /// Load cache from disk.
  Future<void> _loadCacheFile() async {
    try {
      final String cachePath = await _getCachePath();
      final Map<String, dynamic>? data =
          await _jsonRepository.read(cachePath);

      if (data == null) {
        LogSystem.info('Cache file not found, starting fresh');
        return;
      }

      _cache.clear();

      for (final String bookId in data.keys) {
        final dynamic bookData = data[bookId];
        if (bookData is List) {
          final List<BookmarkItem> items =
              (bookData as List<dynamic>)
                  .map(
                    (dynamic item) =>
                        BookmarkItem.fromJson(
                      item as Map<String, dynamic>,
                    ),
                  )
                  .toList();
          _cache[bookId] = items;
        }
      }

      LogSystem.info('Loaded cache with ${_cache.length}'
          ' books');
    } catch (e, st) {
      LogSystem.warning(
        'Failed to load cache file: $e. Starting fresh.',
        stackTrace: st,
      );
      _cache.clear();
    }
  }

  /// Save cache to disk.
  Future<void> _saveCacheFile() async {
    try {
      final String cachePath = await _getCachePath();

      final Map<String, dynamic> data =
          <String, dynamic>{};

      for (final String bookId in _cache.keys) {
        final List<BookmarkItem> items = _cache[bookId]!;
        data[bookId] = items
            .map((BookmarkItem item) => item.toJson())
            .toList();
      }

      await _jsonRepository.write(cachePath, data);
      LogSystem.debug(
        'Saved bookmark cache to disk',
      );
    } catch (e, st) {
      LogSystem.error(
        'Failed to save cache file: $e',
        stackTrace: st,
      );
    }
  }

  @override
  Future<List<BookmarkItem>> getAllBookmarks() async {
    if (!_initialized) {
      await _loadCacheFile();
      _initialized = true;
    }

    final List<BookmarkItem> allItems =
        <BookmarkItem>[];

    for (final List<BookmarkItem> items in _cache.values) {
      allItems.addAll(items);
    }

    // Sort by creation time (newest first)
    allItems.sort(
      (BookmarkItem a, BookmarkItem b) =>
          b.createdAt.compareTo(a.createdAt),
    );

    return allItems;
  }

  @override
  Future<List<BookmarkItem>> getBookmarksForBook(
    BookId bookId,
  ) async {
    if (!_initialized) {
      await _loadCacheFile();
      _initialized = true;
    }

    final List<BookmarkItem> items =
        _cache[bookId] ?? <BookmarkItem>[];

    // Sort by creation time (newest first)
    items.sort(
      (BookmarkItem a, BookmarkItem b) =>
          b.createdAt.compareTo(a.createdAt),
    );

    return items;
  }

  @override
  Future<void> updateBookEntry(
    BookId bookId,
    List<BookmarkEntry> entries,
  ) async {
    try {
      final List<BookmarkItem> items =
          <BookmarkItem>[];

      // Get book title from metadata
      final BookMetadata? metadata =
          await _localBookStorage.getMetadata(bookId);

      if (metadata != null) {
        for (final BookmarkEntry entry in entries) {
          items.add(
            BookmarkItem.fromBookmarkEntry(
              entry,
              metadata.title,
              bookId,
            ),
          );
        }
      }

      _cache[bookId] = items;
      await _saveCacheFile();
      _changeController.add(bookId);

      LogSystem.info(
        'Updated cache for book $bookId with'
        ' ${items.length} bookmarks',
      );
    } catch (e, st) {
      LogSystem.error(
        'Error updating book entry for $bookId: $e',
        stackTrace: st,
      );
    }
  }

  @override
  Future<void> removeBook(BookId bookId) async {
    try {
      _cache.remove(bookId);
      await _saveCacheFile();
      _changeController.add(bookId);

      LogSystem.info('Removed cache for book $bookId');
    } catch (e, st) {
      LogSystem.error(
        'Error removing book $bookId from cache: $e',
        stackTrace: st,
      );
    }
  }

  @override
  Future<void> rebuildCache() async {
    try {
      LogSystem.info('Starting cold path cache rebuild');

      _cache.clear();

      // Get all books from LocalBookStorage
      final List<BookId> bookIds =
          await _localBookStorage.getAll();

      for (final BookId bookId in bookIds) {
        try {
          final BookMetadata? metadata =
              await _localBookStorage
                  .getMetadata(bookId);

          if (metadata != null) {
            final List<BookmarkItem> items =
                metadata.bookmarks
                    .map(
                      (BookmarkEntry entry) =>
                          BookmarkItem
                              .fromBookmarkEntry(
                        entry,
                        metadata.title,
                        bookId,
                      ),
                    )
                    .toList();

            _cache[bookId] = items;
          }
        } catch (e, st) {
          LogSystem.warning(
            'Error reading metadata for book'
            ' $bookId: $e',
            stackTrace: st,
          );
        }
      }

      await _saveCacheFile();

      LogSystem.info(
        'Completed cache rebuild:'
        ' ${_cache.length} books,'
        ' ${_cache.values.fold<int>(0, (int sum, List<BookmarkItem> items) => sum + items.length)} bookmarks',
      );
    } catch (e, st) {
      LogSystem.error(
        'Error rebuilding cache: $e',
        stackTrace: st,
      );
    }
  }

  @override
  Stream<BookId> get onChanged =>
      _changeController.stream;
}
