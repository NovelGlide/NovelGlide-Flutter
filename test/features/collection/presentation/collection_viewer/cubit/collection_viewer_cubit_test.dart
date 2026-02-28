import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:novel_glide/enum/loading_state_code.dart';
import 'package:novel_glide/features/book_storage/data/repositories/local_book_storage.dart';
import 'package:novel_glide/features/book_storage/domain/entities/book_metadata.dart';
import 'package:novel_glide/features/book_storage/domain/repositories/book_storage.dart';
import 'package:novel_glide/features/books/domain/entities/book.dart';
import 'package:novel_glide/features/collection/domain/entities/collection_data.dart';
import 'package:novel_glide/features/collection/domain/use_cases/collection_get_data_use_case.dart';
import 'package:novel_glide/features/collection/domain/use_cases/collection_update_data_use_case.dart';
import 'package:novel_glide/features/collection/presentation/collection_viewer/cubit/collection_viewer_cubit.dart';

class MockLocalBookStorage extends Mock implements LocalBookStorage {}

class MockCollectionGetDataUseCase extends Mock
    implements CollectionGetDataUseCase {}

class MockCollectionUpdateDataUseCase extends Mock
    implements CollectionUpdateDataUseCase {}

void main() {
  late MockLocalBookStorage mockLocalBookStorage;
  late MockCollectionGetDataUseCase mockGetCollectionDataUseCase;
  late MockCollectionUpdateDataUseCase mockUpdateCollectionDataUseCase;
  late CollectionViewerCubit cubit;

  const String bookId1 = 'book-uuid-1';
  const String bookId2 = 'book-uuid-2';
  const String bookId3 = 'book-uuid-3';
  const String collectionId = 'collection-id-1';

  final DateTime now = DateTime.now();
  late CollectionData testCollection;
  late BookMetadata bookMetadata1;
  late BookMetadata bookMetadata2;
  late BookMetadata bookMetadata3;

  setUp(() {
    mockLocalBookStorage = MockLocalBookStorage();
    mockGetCollectionDataUseCase = MockCollectionGetDataUseCase();
    mockUpdateCollectionDataUseCase = MockCollectionUpdateDataUseCase();

    cubit = CollectionViewerCubit(
      mockLocalBookStorage,
      mockGetCollectionDataUseCase,
      mockUpdateCollectionDataUseCase,
    );

    // Setup test data
    testCollection = CollectionData(
      id: collectionId,
      name: 'Test Collection',
      bookIds: const <String>[bookId1, bookId2, bookId3],
      description: 'A test collection',
      createdAt: now,
      updatedAt: now,
      color: '#FF5722',
    );

    bookMetadata1 = BookMetadata(
      originalFilename: 'book1.epub',
      title: 'Book One',
      dateAdded: now,
      readingState: ReadingState.initial(),
      bookmarks: const <BookmarkEntry>[],
    );

    bookMetadata2 = BookMetadata(
      originalFilename: 'book2.epub',
      title: 'Book Two',
      dateAdded: now.subtract(const Duration(days: 1)),
      readingState: ReadingState.initial(),
      bookmarks: const <BookmarkEntry>[],
    );

    bookMetadata3 = BookMetadata(
      originalFilename: 'book3.epub',
      title: 'Book Three',
      dateAdded: now.subtract(const Duration(days: 2)),
      readingState: ReadingState.initial(),
      bookmarks: const <BookmarkEntry>[],
    );
  });

  tearDown(() {
    cubit.close();
  });

  group('CollectionViewerCubit', () {
    group('init', () {
      test('sets collection data correctly', () {
        cubit.init(testCollection);
        expect(cubit.collectionData.id, equals(collectionId));
        expect(cubit.collectionData.bookIds, equals(testCollection.bookIds));
      });
    });

    group('refresh - load books by bookIds', () {
      test('loads books successfully from LocalBookStorage', () async {
        // Arrange
        when(() => mockGetCollectionDataUseCase(any()))
            .thenAnswer((_) async => testCollection);
        when(() => mockLocalBookStorage.readMetadata(bookId1))
            .thenAnswer((_) async => bookMetadata1);
        when(() => mockLocalBookStorage.readMetadata(bookId2))
            .thenAnswer((_) async => bookMetadata2);
        when(() => mockLocalBookStorage.readMetadata(bookId3))
            .thenAnswer((_) async => bookMetadata3);

        cubit.init(testCollection);

        // Act
        await cubit.refresh();

        // Assert
        expect(cubit.state.code, equals(LoadingStateCode.loaded));
        expect(cubit.state.dataList.length, equals(3));
        expect(cubit.state.dataList[0].identifier, equals(bookId1));
        expect(cubit.state.dataList[0].title, equals('Book One'));
        expect(cubit.state.dataList[1].identifier, equals(bookId2));
        expect(cubit.state.dataList[2].identifier, equals(bookId3));
      });

      test('handles empty collection gracefully', () async {
        // Arrange
        final CollectionData emptyCollection = testCollection.copyWith(
          bookIds: const <String>[],
        );
        when(() => mockGetCollectionDataUseCase(any()))
            .thenAnswer((_) async => emptyCollection);

        cubit.init(emptyCollection);

        // Act
        await cubit.refresh();

        // Assert
        expect(cubit.state.code, equals(LoadingStateCode.loaded));
        expect(cubit.state.dataList, isEmpty);
      });

      test('gracefully handles missing books (deleted books)', () async {
        // Arrange
        when(() => mockGetCollectionDataUseCase(any()))
            .thenAnswer((_) async => testCollection);
        when(() => mockLocalBookStorage.readMetadata(bookId1))
            .thenAnswer((_) async => bookMetadata1);
        when(() => mockLocalBookStorage.readMetadata(bookId2))
            .thenAnswer((_) async => null); // Book deleted
        when(() => mockLocalBookStorage.readMetadata(bookId3))
            .thenAnswer((_) async => bookMetadata3);

        cubit.init(testCollection);

        // Act
        await cubit.refresh();

        // Assert - missing book should not be in the list
        expect(cubit.state.code, equals(LoadingStateCode.loaded));
        expect(cubit.state.dataList.length, equals(2));
        expect(cubit.state.dataList[0].identifier, equals(bookId1));
        expect(cubit.state.dataList[1].identifier, equals(bookId3));
      });

      test('maintains book order from collection bookIds', () async {
        // Arrange - set a different order
        final CollectionData reorderedCollection = testCollection.copyWith(
          bookIds: const <String>[bookId3, bookId1, bookId2],
        );
        when(() => mockGetCollectionDataUseCase(any()))
            .thenAnswer((_) async => reorderedCollection);
        when(() => mockLocalBookStorage.readMetadata(bookId3))
            .thenAnswer((_) async => bookMetadata3);
        when(() => mockLocalBookStorage.readMetadata(bookId1))
            .thenAnswer((_) async => bookMetadata1);
        when(() => mockLocalBookStorage.readMetadata(bookId2))
            .thenAnswer((_) async => bookMetadata2);

        cubit.init(reorderedCollection);

        // Act
        await cubit.refresh();

        // Assert
        expect(cubit.state.dataList[0].identifier, equals(bookId3));
        expect(cubit.state.dataList[1].identifier, equals(bookId1));
        expect(cubit.state.dataList[2].identifier, equals(bookId2));
      });

      test('emits loading state during refresh', () async {
        // Arrange
        when(() => mockGetCollectionDataUseCase(any()))
            .thenAnswer((_) async => testCollection);
        when(() => mockLocalBookStorage.readMetadata(any()))
            .thenAnswer((_) async => bookMetadata1);

        cubit.init(testCollection);

        // Act & Assert
        expect(
          cubit.stream,
          emitsInOrder(
            <dynamic>[
              isA<CollectionViewerState>()
                  .having((s) => s.code, 'code', LoadingStateCode.loading),
              isA<CollectionViewerState>().having(
                (s) => s.code,
                'code',
                LoadingStateCode.backgroundLoading,
              ),
            ],
          ),
        );

        await cubit.refresh();
      });

      test('handles large collection (20+ books)', () async {
        // Arrange
        final List<String> largeBookIdList =
            List<String>.generate(25, (i) => 'book-uuid-$i');
        final CollectionData largeCollection = testCollection.copyWith(
          bookIds: largeBookIdList,
        );

        when(() => mockGetCollectionDataUseCase(any()))
            .thenAnswer((_) async => largeCollection);
        for (String bookId in largeBookIdList) {
          when(() => mockLocalBookStorage.readMetadata(bookId))
              .thenAnswer((_) async => BookMetadata(
                    originalFilename: '$bookId.epub',
                    title: 'Book $bookId',
                    dateAdded: now,
                    readingState: ReadingState.initial(),
                    bookmarks: const <BookmarkEntry>[],
                  ));
        }

        cubit.init(largeCollection);

        // Act
        await cubit.refresh();

        // Assert
        expect(cubit.state.dataList.length, equals(25));
      });
    });

    group('select/deselect books', () {
      test('selects single book correctly', () async {
        // Arrange
        when(() => mockGetCollectionDataUseCase(any()))
            .thenAnswer((_) async => testCollection);
        when(() => mockLocalBookStorage.readMetadata(any()))
            .thenAnswer((_) async => bookMetadata1);

        cubit.init(testCollection);
        await cubit.refresh();

        // Act
        cubit.selectSingle(cubit.state.dataList[0]);

        // Assert
        expect(cubit.state.selectedSet.contains(cubit.state.dataList[0]),
            isTrue);
      });

      test('deselects single book correctly', () async {
        // Arrange
        when(() => mockGetCollectionDataUseCase(any()))
            .thenAnswer((_) async => testCollection);
        when(() => mockLocalBookStorage.readMetadata(any()))
            .thenAnswer((_) async => bookMetadata1);

        cubit.init(testCollection);
        await cubit.refresh();
        cubit.selectSingle(cubit.state.dataList[0]);

        // Act
        cubit.deselectSingle(cubit.state.dataList[0]);

        // Assert
        expect(cubit.state.selectedSet.contains(cubit.state.dataList[0]),
            isFalse);
      });
    });

    group('reorder books', () {
      test('reorders books and saves to collection', () async {
        // Arrange
        when(() => mockGetCollectionDataUseCase(any()))
            .thenAnswer((_) async => testCollection);
        when(() => mockLocalBookStorage.readMetadata(any()))
            .thenAnswer((_) async => bookMetadata1);
        when(() => mockUpdateCollectionDataUseCase(any()))
            .thenAnswer((_) async {});

        cubit.init(testCollection);
        await cubit.refresh();
        final Book firstBook = cubit.state.dataList[0];

        // Act
        cubit.reorder(0, 2); // Move first book to third position

        // Assert
        expect(cubit.state.dataList[2].identifier, equals(firstBook.identifier));
        // Verify that updateData was called with the reordered collection
        verify(() => mockUpdateCollectionDataUseCase(any())).called(1);
      });

      test('maintains order with idempotent reorder', () async {
        // Arrange
        when(() => mockGetCollectionDataUseCase(any()))
            .thenAnswer((_) async => testCollection);
        when(() => mockLocalBookStorage.readMetadata(any()))
            .thenAnswer((_) async => bookMetadata1);

        cubit.init(testCollection);
        await cubit.refresh();
        final List<Book> originalOrder = List<Book>.from(cubit.state.dataList);

        // Act
        cubit.reorder(1, 1); // Reorder to same position

        // Assert
        expect(cubit.state.dataList, equals(originalOrder));
      });
    });

    group('removeBooks', () {
      test('removes selected books from collection', () async {
        // Arrange
        when(() => mockGetCollectionDataUseCase(any()))
            .thenAnswer((_) async => testCollection);
        when(() => mockLocalBookStorage.readMetadata(any()))
            .thenAnswer((_) async => bookMetadata1);
        when(() => mockUpdateCollectionDataUseCase(any()))
            .thenAnswer((_) async {});

        cubit.init(testCollection);
        await cubit.refresh();
        cubit.selectSingle(cubit.state.dataList[0]);
        cubit.selectSingle(cubit.state.dataList[1]);

        // Act
        await cubit.removeBooks();

        // Assert
        expect(cubit.state.dataList.length, equals(1));
        expect(cubit.state.selectedSet, isEmpty);
      });

      test('updates collection bookIds after removal', () async {
        // Arrange
        when(() => mockGetCollectionDataUseCase(any()))
            .thenAnswer((_) async => testCollection);
        when(() => mockLocalBookStorage.readMetadata(any()))
            .thenAnswer((_) async => bookMetadata1);
        when(() => mockUpdateCollectionDataUseCase(any()))
            .thenAnswer((_) async {});

        cubit.init(testCollection);
        await cubit.refresh();
        final Book bookToRemove = cubit.state.dataList[1];
        cubit.selectSingle(bookToRemove);

        // Act
        await cubit.removeBooks();

        // Assert
        expect(cubit.collectionData.bookIds,
            isNot(contains(bookToRemove.identifier)));
        verify(() => mockUpdateCollectionDataUseCase(any())).called(1);
      });
    });
  });
}
