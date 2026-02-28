import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:novel_glide/core/file_system/domain/repositories/json_repository.dart';
import 'package:novel_glide/core/path_provider/domain/repositories/app_path_provider.dart';
import 'package:novel_glide/features/book_storage/data/repositories/local_book_storage.dart';
import 'package:novel_glide/features/book_storage/domain/entities/book_metadata.dart';
import 'package:novel_glide/features/book_storage/domain/entities/bookmark_entry.dart';
import 'package:novel_glide/features/book_storage/domain/entities/reading_state.dart';
import 'package:novel_glide/features/bookmark/data/repositories/bookmark_cache_repository_impl.dart';
import 'package:novel_glide/features/bookmark/domain/entities/bookmark_item.dart';

void main() {
  late BookmarkCacheRepositoryImpl repository;
  late MockLocalBookStorage mockLocalBookStorage;
  late MockJsonRepository mockJsonRepository;
  late MockAppPathProvider mockAppPathProvider;

  setUp(() {
    mockLocalBookStorage = MockLocalBookStorage();
    mockJsonRepository = MockJsonRepository();
    mockAppPathProvider = MockAppPathProvider();

    when(mockAppPathProvider.dataPath).thenAnswer((_) async => '/test/data');
    when(mockLocalBookStorage.onChanged)
        .thenAnswer((_) => const Stream.empty());

    repository = BookmarkCacheRepositoryImpl(
      localBookStorage: mockLocalBookStorage,
      jsonRepository: mockJsonRepository,
      appPathProvider: mockAppPathProvider,
    );
  });

  group('BookmarkCacheRepositoryImpl', () {
    final DateTime now = DateTime.now();
    const String bookId1 = 'book-001';
    const String bookId2 = 'book-002';
    const String bookTitle1 = 'Book One';
    const String bookTitle2 = 'Book Two';

    group('getAllBookmarks', () {
      test('returns empty list when no books have bookmarks', () async {
        when(mockJsonRepository.read(any)).thenAnswer((_) async => null);
        when(mockLocalBookStorage.getAll()).thenAnswer((_) async => <String>[]);

        final List<BookmarkItem> result = await repository.getAllBookmarks();

        expect(result, isEmpty);
      });

      test('returns all bookmarks sorted by creation time', () async {
        final DateTime time1 = now.subtract(
          const Duration(days: 2),
        );
        final DateTime time2 = now.subtract(
          const Duration(days: 1),
        );
        final DateTime time3 = now;

        final BookmarkItem item1 = BookmarkItem(
          id: 'bm-1',
          bookId: bookId1,
          bookTitle: bookTitle1,
          position: 'epubcfi(/6/4)',
          label: 'Label 1',
          createdAt: time1,
        );

        final BookmarkItem item2 = BookmarkItem(
          id: 'bm-2',
          bookId: bookId2,
          bookTitle: bookTitle2,
          position: 'epubcfi(/6/5)',
          label: 'Label 2',
          createdAt: time2,
        );

        final BookmarkItem item3 = BookmarkItem(
          id: 'bm-3',
          bookId: bookId1,
          bookTitle: bookTitle1,
          position: 'epubcfi(/6/6)',
          label: 'Label 3',
          createdAt: time3,
        );

        when(mockJsonRepository.read(any)).thenAnswer(
          (_) async => <String, dynamic>{
            bookId1: <Map<String, dynamic>>[
              item1.toJson(),
              item3.toJson(),
            ],
            bookId2: <Map<String, dynamic>>[
              item2.toJson(),
            ],
          },
        );

        final List<BookmarkItem> result = await repository.getAllBookmarks();

        expect(result, hasLength(3));
        expect(result[0].id, equals('bm-3'));
        expect(result[1].id, equals('bm-2'));
        expect(result[2].id, equals('bm-1'));
      });
    });

    group('getBookmarksForBook', () {
      test('returns bookmarks for specific book', () async {
        final BookmarkItem item1 = BookmarkItem(
          id: 'bm-1',
          bookId: bookId1,
          bookTitle: bookTitle1,
          position: 'epubcfi(/6/4)',
          label: 'Label 1',
          createdAt: now,
        );

        when(mockJsonRepository.read(any)).thenAnswer(
          (_) async => <String, dynamic>{
            bookId1: <Map<String, dynamic>>[
              item1.toJson(),
            ],
          },
        );

        final List<BookmarkItem> result =
            await repository.getBookmarksForBook(bookId1);

        expect(result, hasLength(1));
        expect(result[0].id, equals('bm-1'));
      });

      test('returns empty list for book with no bookmarks', () async {
        when(mockJsonRepository.read(any))
            .thenAnswer((_) async => <String, dynamic>{});

        final List<BookmarkItem> result =
            await repository.getBookmarksForBook(bookId1);

        expect(result, isEmpty);
      });

      test('returns bookmarks sorted by creation time', () async {
        final DateTime time1 = now.subtract(
          const Duration(hours: 2),
        );
        final DateTime time2 = now.subtract(
          const Duration(hours: 1),
        );

        final BookmarkItem item1 = BookmarkItem(
          id: 'bm-1',
          bookId: bookId1,
          bookTitle: bookTitle1,
          position: 'epubcfi(/6/4)',
          label: 'Label 1',
          createdAt: time1,
        );

        final BookmarkItem item2 = BookmarkItem(
          id: 'bm-2',
          bookId: bookId1,
          bookTitle: bookTitle1,
          position: 'epubcfi(/6/5)',
          label: 'Label 2',
          createdAt: time2,
        );

        when(mockJsonRepository.read(any)).thenAnswer(
          (_) async => <String, dynamic>{
            bookId1: <Map<String, dynamic>>[
              item1.toJson(),
              item2.toJson(),
            ],
          },
        );

        final List<BookmarkItem> result =
            await repository.getBookmarksForBook(bookId1);

        expect(result[0].id, equals('bm-2'));
        expect(result[1].id, equals('bm-1'));
      });
    });

    group('updateBookEntry', () {
      test('updates cache with new entries', () async {
        final BookmarkEntry entry = BookmarkEntry(
          id: 'bm-1',
          cfiPosition: 'epubcfi(/6/4)',
          timestamp: now,
          label: 'Label 1',
        );

        final BookMetadata metadata = BookMetadata(
          originalFilename: 'book.epub',
          title: bookTitle1,
          dateAdded: now,
          readingState: ReadingState(
            position: 'epubcfi(/6/4)',
            progress: 0.5,
            lastReadAt: now,
          ),
          bookmarks: <BookmarkEntry>[entry],
        );

        when(mockLocalBookStorage.getMetadata(bookId1))
            .thenAnswer((_) async => metadata);
        when(mockJsonRepository.write(any, any)).thenAnswer((_) async {});

        await repository.updateBookEntry(
          bookId1,
          <BookmarkEntry>[entry],
        );

        verify(mockJsonRepository.write(any, any)).called(1);
      });

      test('emits onChanged after update', () async {
        final BookmarkEntry entry = BookmarkEntry(
          id: 'bm-1',
          cfiPosition: 'epubcfi(/6/4)',
          timestamp: now,
          label: 'Label 1',
        );

        final BookMetadata metadata = BookMetadata(
          originalFilename: 'book.epub',
          title: bookTitle1,
          dateAdded: now,
          readingState: ReadingState(
            position: 'epubcfi(/6/4)',
            progress: 0.5,
            lastReadAt: now,
          ),
          bookmarks: <BookmarkEntry>[entry],
        );

        when(mockLocalBookStorage.getMetadata(bookId1))
            .thenAnswer((_) async => metadata);
        when(mockJsonRepository.write(any, any)).thenAnswer((_) async {});

        final StreamSubscription<String> sub =
            repository.onChanged.listen((_) {});

        await repository.updateBookEntry(
          bookId1,
          <BookmarkEntry>[entry],
        );

        await Future<void>.delayed(
          const Duration(milliseconds: 100),
        );
        await sub.cancel();
      });
    });

    group('removeBook', () {
      test('removes book from cache', () async {
        final BookmarkItem item1 = BookmarkItem(
          id: 'bm-1',
          bookId: bookId1,
          bookTitle: bookTitle1,
          position: 'epubcfi(/6/4)',
          label: 'Label 1',
          createdAt: now,
        );

        when(mockJsonRepository.read(any)).thenAnswer(
          (_) async => <String, dynamic>{
            bookId1: <Map<String, dynamic>>[
              item1.toJson(),
            ],
          },
        );
        when(mockJsonRepository.write(any, any)).thenAnswer((_) async {});

        await repository.getAllBookmarks();
        await repository.removeBook(bookId1);

        final List<BookmarkItem> result = await repository.getAllBookmarks();

        expect(result, isEmpty);
      });

      test('emits onChanged after removal', () async {
        when(mockJsonRepository.write(any, any)).thenAnswer((_) async {});

        final StreamSubscription<String> sub =
            repository.onChanged.listen((_) {});

        await repository.removeBook(bookId1);

        await Future<void>.delayed(
          const Duration(milliseconds: 100),
        );
        await sub.cancel();
      });
    });

    group('rebuildCache', () {
      test('rebuilds cache from all book metadata', () async {
        final BookmarkEntry entry1 = BookmarkEntry(
          id: 'bm-1',
          cfiPosition: 'epubcfi(/6/4)',
          timestamp: now,
          label: 'Label 1',
        );

        final BookmarkEntry entry2 = BookmarkEntry(
          id: 'bm-2',
          cfiPosition: 'epubcfi(/6/5)',
          timestamp: now,
          label: 'Label 2',
        );

        final BookMetadata metadata1 = BookMetadata(
          originalFilename: 'book1.epub',
          title: bookTitle1,
          dateAdded: now,
          readingState: ReadingState(
            position: 'epubcfi(/6/4)',
            progress: 0.5,
            lastReadAt: now,
          ),
          bookmarks: <BookmarkEntry>[entry1],
        );

        final BookMetadata metadata2 = BookMetadata(
          originalFilename: 'book2.epub',
          title: bookTitle2,
          dateAdded: now,
          readingState: ReadingState(
            position: 'epubcfi(/6/5)',
            progress: 0.6,
            lastReadAt: now,
          ),
          bookmarks: <BookmarkEntry>[entry2],
        );

        when(mockLocalBookStorage.getAll()).thenAnswer(
          (_) async => <String>[bookId1, bookId2],
        );
        when(mockLocalBookStorage.getMetadata(bookId1))
            .thenAnswer((_) async => metadata1);
        when(mockLocalBookStorage.getMetadata(bookId2))
            .thenAnswer((_) async => metadata2);
        when(mockJsonRepository.write(any, any)).thenAnswer((_) async {});

        await repository.rebuildCache();

        final List<BookmarkItem> result = await repository.getAllBookmarks();

        expect(result, hasLength(2));
      });

      test('handles errors gracefully during rebuild', () async {
        when(mockLocalBookStorage.getAll())
            .thenAnswer((_) async => <String>[bookId1]);
        when(mockLocalBookStorage.getMetadata(bookId1))
            .thenThrow(Exception('Read error'));
        when(mockJsonRepository.write(any, any)).thenAnswer((_) async {});

        expect(
          repository.rebuildCache(),
          completes,
        );
      });
    });

    group('onChanged stream', () {
      test('emits book ID when book changes', () async {
        when(mockJsonRepository.write(any, any)).thenAnswer((_) async {});

        final List<String> changes = <String>[];
        final StreamSubscription<String> sub = repository.onChanged.listen(
          (String id) => changes.add(id),
        );

        await repository.removeBook(bookId1);

        await Future<void>.delayed(
          const Duration(milliseconds: 100),
        );

        expect(changes, contains(bookId1));
        await sub.cancel();
      });

      test('supports multiple subscribers', () async {
        when(mockJsonRepository.write(any, any)).thenAnswer((_) async {});

        final List<String> changes1 = <String>[];
        final List<String> changes2 = <String>[];

        final StreamSubscription<String> sub1 = repository.onChanged.listen(
          (String id) => changes1.add(id),
        );
        final StreamSubscription<String> sub2 = repository.onChanged.listen(
          (String id) => changes2.add(id),
        );

        await repository.removeBook(bookId1);

        await Future<void>.delayed(
          const Duration(milliseconds: 100),
        );

        expect(changes1, contains(bookId1));
        expect(changes2, contains(bookId1));

        await sub1.cancel();
        await sub2.cancel();
      });
    });

    group('Edge cases and error handling', () {
      test('handles corrupted cache file gracefully', () async {
        when(mockJsonRepository.read(any))
            .thenThrow(Exception('Corrupted file'));

        final List<BookmarkItem> result = await repository.getAllBookmarks();

        expect(result, isEmpty);
      });

      test('handles null metadata gracefully', () async {
        when(mockLocalBookStorage.getAll()).thenAnswer(
          (_) async => <String>[bookId1],
        );
        when(mockLocalBookStorage.getMetadata(bookId1))
            .thenAnswer((_) async => null);
        when(mockJsonRepository.write(any, any)).thenAnswer((_) async {});

        expect(
          repository.rebuildCache(),
          completes,
        );
      });

      test('handles empty bookmark list in metadata', () async {
        final BookMetadata metadata = BookMetadata(
          originalFilename: 'book.epub',
          title: bookTitle1,
          dateAdded: now,
          readingState: ReadingState(
            position: 'epubcfi(/6/4)',
            progress: 0.5,
            lastReadAt: now,
          ),
          bookmarks: <BookmarkEntry>[],
        );

        when(mockLocalBookStorage.getAll()).thenAnswer(
          (_) async => <String>[bookId1],
        );
        when(mockLocalBookStorage.getMetadata(bookId1))
            .thenAnswer((_) async => metadata);
        when(mockJsonRepository.write(any, any)).thenAnswer((_) async {});

        await repository.rebuildCache();

        final List<BookmarkItem> result =
            await repository.getBookmarksForBook(bookId1);

        expect(result, isEmpty);
      });

      test('handles concurrent updateBookEntry calls', () async {
        final BookmarkEntry entry1 = BookmarkEntry(
          id: 'bm-1',
          cfiPosition: 'epubcfi(/6/4)',
          timestamp: now,
          label: 'Label 1',
        );

        final BookmarkEntry entry2 = BookmarkEntry(
          id: 'bm-2',
          cfiPosition: 'epubcfi(/6/5)',
          timestamp: now,
          label: 'Label 2',
        );

        final BookMetadata metadata = BookMetadata(
          originalFilename: 'book.epub',
          title: bookTitle1,
          dateAdded: now,
          readingState: ReadingState(
            position: 'epubcfi(/6/4)',
            progress: 0.5,
            lastReadAt: now,
          ),
          bookmarks: <BookmarkEntry>[
            entry1,
            entry2,
          ],
        );

        when(mockLocalBookStorage.getMetadata(bookId1))
            .thenAnswer((_) async => metadata);
        when(mockJsonRepository.write(any, any)).thenAnswer((_) async {});

        await Future.wait(<Future<void>>[
          repository.updateBookEntry(
            bookId1,
            <BookmarkEntry>[entry1],
          ),
          repository.updateBookEntry(
            bookId1,
            <BookmarkEntry>[entry2],
          ),
        ]);

        verify(mockJsonRepository.write(any, any)).called(2);
      });
    });
  });
}
