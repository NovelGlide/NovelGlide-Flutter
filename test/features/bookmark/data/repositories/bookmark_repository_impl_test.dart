import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:novel_glide/features/book_storage/data/repositories/local_book_storage.dart';
import 'package:novel_glide/features/book_storage/domain/entities/book_metadata.dart';
import 'package:novel_glide/features/book_storage/domain/entities/bookmark_entry.dart';
import 'package:novel_glide/features/book_storage/domain/entities/reading_state.dart';
import 'package:novel_glide/features/bookmark/data/repositories/bookmark_repository_impl.dart';
import 'package:novel_glide/features/bookmark/domain/entities/bookmark_item.dart';
import 'package:novel_glide/features/bookmark/domain/repositories/bookmark_cache_repository.dart';

void main() {
  late BookmarkRepositoryImpl repository;
  late MockBookmarkCacheRepository mockCacheRepository;
  late MockLocalBookStorage mockLocalBookStorage;

  setUp(() {
    mockCacheRepository = MockBookmarkCacheRepository();
    mockLocalBookStorage = MockLocalBookStorage();

    repository = BookmarkRepositoryImpl(
      bookmarkCacheRepository: mockCacheRepository,
      localBookStorage: mockLocalBookStorage,
    );
  });

  group('BookmarkRepositoryImpl', () {
    final DateTime now = DateTime.now();
    const String bookId = 'book-001';
    const String bookTitle = 'Test Book';

    group('getAll', () {
      test('returns all bookmarks from cache', () async {
        final BookmarkItem item1 = BookmarkItem(
          id: 'bm-1',
          bookId: bookId,
          bookTitle: bookTitle,
          position: 'epubcfi(/6/4)',
          label: 'Label 1',
          createdAt: now,
        );

        final BookmarkItem item2 = BookmarkItem(
          id: 'bm-2',
          bookId: bookId,
          bookTitle: bookTitle,
          position: 'epubcfi(/6/5)',
          label: 'Label 2',
          createdAt: now.subtract(
            const Duration(hours: 1),
          ),
        );

        when(mockCacheRepository.getAllBookmarks())
            .thenAnswer(
          (_) async => <BookmarkItem>[
            item1,
            item2,
          ],
        );

        final List<BookmarkItem> result =
            await repository.getAll();

        expect(result, hasLength(2));
        expect(result[0].id, equals('bm-1'));
        expect(result[1].id, equals('bm-2'));
      });

      test('returns empty list on error', () async {
        when(mockCacheRepository.getAllBookmarks())
            .thenThrow(Exception('Error'));

        final List<BookmarkItem> result =
            await repository.getAll();

        expect(result, isEmpty);
      });
    });

    group('getById', () {
      test('returns bookmark with matching ID', () async {
        final BookmarkItem item = BookmarkItem(
          id: 'bm-1',
          bookId: bookId,
          bookTitle: bookTitle,
          position: 'epubcfi(/6/4)',
          label: 'Label 1',
          createdAt: now,
        );

        when(mockCacheRepository.getAllBookmarks())
            .thenAnswer(
          (_) async => <BookmarkItem>[item],
        );

        final BookmarkItem? result =
            await repository.getById('bm-1');

        expect(result, isNotNull);
        expect(result?.id, equals('bm-1'));
      });

      test('returns null when bookmark not found',
          () async {
        when(mockCacheRepository.getAllBookmarks())
            .thenAnswer((_) async => <BookmarkItem>[]);

        final BookmarkItem? result =
            await repository.getById('bm-not-found');

        expect(result, isNull);
      });

      test('returns null on error', () async {
        when(mockCacheRepository.getAllBookmarks())
            .thenThrow(Exception('Error'));

        final BookmarkItem? result =
            await repository.getById('bm-1');

        expect(result, isNull);
      });
    });

    group('addBookmark', () {
      test('adds bookmark to book metadata', () async {
        final BookmarkEntry entry = BookmarkEntry(
          id: 'bm-1',
          cfiPosition: 'epubcfi(/6/4)',
          timestamp: now,
          label: 'Label',
        );

        final BookMetadata metadata = BookMetadata(
          originalFilename: 'book.epub',
          title: bookTitle,
          dateAdded: now,
          readingState: ReadingState(
            position: 'epubcfi(/6/4)',
            progress: 0.5,
            lastReadAt: now,
          ),
          bookmarks: <BookmarkEntry>[],
        );

        when(mockLocalBookStorage.getMetadata(bookId))
            .thenAnswer((_) async => metadata);
        when(mockLocalBookStorage.updateMetadata(
          any,
          any,
        )).thenAnswer((_) async {});

        await repository.addBookmark(bookId, entry);

        verify(mockLocalBookStorage.updateMetadata(
          bookId,
          any,
        )).called(1);
      });

      test('handles missing book gracefully', () async {
        when(mockLocalBookStorage.getMetadata(bookId))
            .thenAnswer((_) async => null);

        final BookmarkEntry entry = BookmarkEntry(
          id: 'bm-1',
          cfiPosition: 'epubcfi(/6/4)',
          timestamp: now,
          label: 'Label',
        );

        expect(
          repository.addBookmark(bookId, entry),
          completes,
        );

        verifyNever(
          mockLocalBookStorage.updateMetadata(
            any,
            any,
          ),
        );
      });

      test('preserves existing bookmarks', () async {
        final BookmarkEntry existing =
            BookmarkEntry(
          id: 'bm-existing',
          cfiPosition: 'epubcfi(/6/3)',
          timestamp: now.subtract(
            const Duration(days: 1),
          ),
          label: 'Existing',
        );

        final BookmarkEntry newEntry = BookmarkEntry(
          id: 'bm-new',
          cfiPosition: 'epubcfi(/6/4)',
          timestamp: now,
          label: 'New',
        );

        final BookMetadata metadata = BookMetadata(
          originalFilename: 'book.epub',
          title: bookTitle,
          dateAdded: now,
          readingState: ReadingState(
            position: 'epubcfi(/6/4)',
            progress: 0.5,
            lastReadAt: now,
          ),
          bookmarks: <BookmarkEntry>[existing],
        );

        when(mockLocalBookStorage.getMetadata(bookId))
            .thenAnswer((_) async => metadata);
        when(mockLocalBookStorage.updateMetadata(
          any,
          any,
        )).thenAnswer((_) async {});

        await repository.addBookmark(bookId, newEntry);

        final VerificationResult verification =
            verify(mockLocalBookStorage.updateMetadata(
          bookId,
          captureAny,
        ));

        expect(verification.callCount, equals(1));
      });
    });

    group('deleteBookmarks', () {
      test('deletes bookmarks from their books', () async {
        final BookmarkItem item1 = BookmarkItem(
          id: 'bm-1',
          bookId: bookId,
          bookTitle: bookTitle,
          position: 'epubcfi(/6/4)',
          label: 'Label 1',
          createdAt: now,
        );

        final BookMetadata metadata = BookMetadata(
          originalFilename: 'book.epub',
          title: bookTitle,
          dateAdded: now,
          readingState: ReadingState(
            position: 'epubcfi(/6/4)',
            progress: 0.5,
            lastReadAt: now,
          ),
          bookmarks: <BookmarkEntry>[
            BookmarkEntry(
              id: 'bm-1',
              cfiPosition: 'epubcfi(/6/4)',
              timestamp: now,
              label: 'Label 1',
            ),
          ],
        );

        when(mockCacheRepository.getAllBookmarks())
            .thenAnswer(
          (_) async => <BookmarkItem>[item1],
        );
        when(mockLocalBookStorage.getMetadata(bookId))
            .thenAnswer((_) async => metadata);
        when(mockLocalBookStorage.updateMetadata(
          any,
          any,
        )).thenAnswer((_) async {});

        await repository.deleteBookmarks(
          <String>['bm-1'],
        );

        verify(mockLocalBookStorage.updateMetadata(
          bookId,
          any,
        )).called(1);
      });

      test('handles empty list gracefully', () async {
        expect(
          repository.deleteBookmarks(<String>[]),
          completes,
        );

        verifyNever(
          mockCacheRepository.getAllBookmarks(),
        );
      });

      test('handles multiple books', () async {
        final BookmarkItem item1 = BookmarkItem(
          id: 'bm-1',
          bookId: 'book-001',
          bookTitle: 'Book 1',
          position: 'epubcfi(/6/4)',
          label: 'Label 1',
          createdAt: now,
        );

        final BookmarkItem item2 = BookmarkItem(
          id: 'bm-2',
          bookId: 'book-002',
          bookTitle: 'Book 2',
          position: 'epubcfi(/6/5)',
          label: 'Label 2',
          createdAt: now,
        );

        final BookMetadata metadata1 = BookMetadata(
          originalFilename: 'book1.epub',
          title: 'Book 1',
          dateAdded: now,
          readingState: ReadingState(
            position: 'epubcfi(/6/4)',
            progress: 0.5,
            lastReadAt: now,
          ),
          bookmarks: <BookmarkEntry>[
            BookmarkEntry(
              id: 'bm-1',
              cfiPosition: 'epubcfi(/6/4)',
              timestamp: now,
              label: 'Label 1',
            ),
          ],
        );

        final BookMetadata metadata2 = BookMetadata(
          originalFilename: 'book2.epub',
          title: 'Book 2',
          dateAdded: now,
          readingState: ReadingState(
            position: 'epubcfi(/6/5)',
            progress: 0.6,
            lastReadAt: now,
          ),
          bookmarks: <BookmarkEntry>[
            BookmarkEntry(
              id: 'bm-2',
              cfiPosition: 'epubcfi(/6/5)',
              timestamp: now,
              label: 'Label 2',
            ),
          ],
        );

        when(mockCacheRepository.getAllBookmarks())
            .thenAnswer(
          (_) async => <BookmarkItem>[
            item1,
            item2,
          ],
        );
        when(mockLocalBookStorage.getMetadata('book-001'))
            .thenAnswer((_) async => metadata1);
        when(mockLocalBookStorage.getMetadata('book-002'))
            .thenAnswer((_) async => metadata2);
        when(mockLocalBookStorage.updateMetadata(
          any,
          any,
        )).thenAnswer((_) async {});

        await repository.deleteBookmarks(
          <String>['bm-1', 'bm-2'],
        );

        verify(mockLocalBookStorage.updateMetadata(
          'book-001',
          any,
        )).called(1);
        verify(mockLocalBookStorage.updateMetadata(
          'book-002',
          any,
        )).called(1);
      });
    });

    group('observeChanges', () {
      test('returns stream of changes', () async {
        final StreamController<String> controller =
            StreamController<String>.broadcast();

        when(mockCacheRepository.onChanged)
            .thenAnswer((_) => controller.stream);

        final Stream<void> changes =
            repository.observeChanges();

        expect(changes, isNotNull);
        controller.close();
      });
    });

    group('rebuildCache', () {
      test('delegates to cache repository', () async {
        when(mockCacheRepository.rebuildCache())
            .thenAnswer((_) async {});

        await repository.rebuildCache();

        verify(mockCacheRepository.rebuildCache())
            .called(1);
      });

      test('handles errors gracefully', () async {
        when(mockCacheRepository.rebuildCache())
            .thenThrow(Exception('Error'));

        expect(
          repository.rebuildCache(),
          completes,
        );
      });
    });
  });
}
