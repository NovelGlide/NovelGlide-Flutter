import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:novel_glide/enum/loading_state_code.dart';
import 'package:novel_glide/features/books/domain/entities/book.dart';
import 'package:novel_glide/features/collection/domain/entities/collection_data.dart';
import 'package:novel_glide/features/collection/domain/use_cases/collection_get_list_use_case.dart';
import 'package:novel_glide/features/collection/domain/use_cases/collection_observe_change_use_case.dart';
import 'package:novel_glide/features/collection/domain/use_cases/collection_update_data_use_case.dart';
import 'package:novel_glide/features/collection/presentation/add_book_page/cubit/collection_add_book_cubit.dart';

class MockCollectionGetListUseCase extends Mock
    implements CollectionGetListUseCase {}

class MockCollectionObserveChangeUseCase extends Mock
    implements CollectionObserveChangeUseCase {}

class MockCollectionUpdateDataUseCase extends Mock
    implements CollectionUpdateDataUseCase {}

void main() {
  late MockCollectionGetListUseCase mockGetListUseCase;
  late MockCollectionObserveChangeUseCase mockObserveChangeUseCase;
  late MockCollectionUpdateDataUseCase mockUpdateDataUseCase;
  late CollectionAddBookCubit cubit;

  const String bookId1 = 'book-uuid-1';
  const String bookId2 = 'book-uuid-2';
  const String bookId3 = 'book-uuid-3';

  final DateTime now = DateTime.now();

  final Book book1 = Book(
    identifier: bookId1,
    title: 'Book One',
    modifiedDate: now,
    coverIdentifier: bookId1,
    ltr: true,
  );

  final Book book2 = Book(
    identifier: bookId2,
    title: 'Book Two',
    modifiedDate: now,
    coverIdentifier: bookId2,
    ltr: true,
  );

  final Book book3 = Book(
    identifier: bookId3,
    title: 'Book Three',
    modifiedDate: now,
    coverIdentifier: bookId3,
    ltr: true,
  );

  final CollectionData collection1 = CollectionData(
    id: 'col-1',
    name: 'Collection A',
    bookIds: const <String>[bookId1],
    createdAt: now,
    updatedAt: now,
  );

  final CollectionData collection2 = CollectionData(
    id: 'col-2',
    name: 'Collection B',
    bookIds: const <String>[bookId2, bookId3],
    createdAt: now,
    updatedAt: now,
  );

  final CollectionData collection3 = CollectionData(
    id: 'col-3',
    name: 'Collection C',
    bookIds: const <String>[],
    createdAt: now,
    updatedAt: now,
  );

  setUp(() {
    mockGetListUseCase = MockCollectionGetListUseCase();
    mockObserveChangeUseCase = MockCollectionObserveChangeUseCase();
    mockUpdateDataUseCase = MockCollectionUpdateDataUseCase();

    cubit = CollectionAddBookCubit(
      mockGetListUseCase,
      mockObserveChangeUseCase,
      mockUpdateDataUseCase,
    );

    when(() => mockObserveChangeUseCase()).thenAnswer(
        (_) => const Stream<void>.empty()); // Don't refresh on changes
    when(() => mockUpdateDataUseCase(any())).thenAnswer((_) async {});
  });

  tearDown(() {
    cubit.close();
  });

  group('CollectionAddBookCubit', () {
    group('init and refresh', () {
      test('initializes with multiple selected books', () async {
        // Arrange
        when(() => mockGetListUseCase()).thenAnswer((_) async => <CollectionData>[
              collection1,
              collection2,
              collection3,
            ]);

        // Act
        await cubit.init({book1, book2});

        // Assert
        expect(cubit.state.bookRelativePathSet, contains(bookId1));
        expect(cubit.state.bookRelativePathSet, contains(bookId2));
      });

      test('computes collection membership via bookId intersection', () async {
        // Arrange
        when(() => mockGetListUseCase()).thenAnswer((_) async => <CollectionData>[
              collection1,
              collection2,
              collection3,
            ]);

        // Act
        await cubit.init({book1, book2});

        // Assert
        // collection1 contains bookId1 (selected)
        // collection2 contains bookId2 and bookId3 (bookId2 is selected)
        // collection3 is empty (no intersection)
        expect(cubit.state.selectedCollections,
            contains(collection1)); // Intersection: bookId1
        expect(cubit.state.selectedCollections,
            contains(collection2)); // Intersection: bookId2
        expect(cubit.state.selectedCollections,
            isNot(contains(collection3))); // No intersection
      });

      test('handles single selected book', () async {
        // Arrange
        when(() => mockGetListUseCase()).thenAnswer((_) async => <CollectionData>[
              collection1,
              collection2,
            ]);

        // Act
        await cubit.init({book1});

        // Assert
        expect(cubit.state.bookRelativePathSet.length, equals(1));
        expect(cubit.state.bookRelativePathSet, contains(bookId1));
      });

      test('handles no selected books', () async {
        // Arrange
        when(() => mockGetListUseCase()).thenAnswer((_) async =>
            <CollectionData>[collection1, collection2, collection3]);

        // Act
        await cubit.init(const <Book>{});

        // Assert
        expect(cubit.state.bookRelativePathSet, isEmpty);
        expect(cubit.state.selectedCollections, isEmpty);
      });

      test('sorts collections by name', () async {
        // Arrange
        final CollectionData zCollection = CollectionData(
          id: 'col-z',
          name: 'Z Collection',
          bookIds: const <String>[],
          createdAt: now,
          updatedAt: now,
        );
        final CollectionData aCollection = CollectionData(
          id: 'col-a',
          name: 'A Collection',
          bookIds: const <String>[],
          createdAt: now,
          updatedAt: now,
        );

        when(() => mockGetListUseCase()).thenAnswer(
            (_) async => <CollectionData>[zCollection, aCollection]);

        // Act
        await cubit.init({book1});

        // Assert
        expect(cubit.state.collectionList[0].name, equals('A Collection'));
        expect(cubit.state.collectionList[1].name, equals('Z Collection'));
      });
    });

    group('select - add books to collection', () {
      test('adds selected books to collection using immutable copyWith', () async {
        // Arrange
        when(() => mockGetListUseCase()).thenAnswer((_) async =>
            <CollectionData>[collection1, collection2, collection3]);

        await cubit.init({book1, book2});

        // Act
        await cubit.select(collection3); // Add to empty collection

        // Assert
        final CollectionData updatedCollection3 =
            cubit.state.collectionList.firstWhere((e) => e.id == 'col-3');
        expect(updatedCollection3.bookIds, contains(bookId1));
        expect(updatedCollection3.bookIds, contains(bookId2));
        expect(cubit.state.selectedCollections, contains(updatedCollection3));
      });

      test('preserves existing books when adding', () async {
        // Arrange
        when(() => mockGetListUseCase()).thenAnswer((_) async =>
            <CollectionData>[collection1, collection2, collection3]);

        await cubit.init({book3}); // Select book3

        // Act
        await cubit.select(collection2); // collection2 already has bookId2, bookId3

        // Assert
        final CollectionData updatedCollection2 =
            cubit.state.collectionList.firstWhere((e) => e.id == 'col-2');
        // Should still have bookId2, bookId3, and added bookId3 (idempotent)
        expect(updatedCollection2.bookIds.length, equals(2));
      });

      test('handles adding to book in multiple collections', () async {
        // Arrange
        final CollectionData sharedCollection = CollectionData(
          id: 'col-shared',
          name: 'Shared Collection',
          bookIds: const <String>[bookId1, bookId2],
          createdAt: now,
          updatedAt: now,
        );

        when(() => mockGetListUseCase()).thenAnswer((_) async =>
            <CollectionData>[collection1, sharedCollection]);

        // Act
        await cubit.init({book1});

        // Assert
        expect(cubit.state.selectedCollections.length, equals(2));
        expect(cubit.state.selectedCollections.any((e) => e.id == 'col-1'),
            isTrue);
        expect(
            cubit.state.selectedCollections.any((e) => e.id == 'col-shared'),
            isTrue);
      });
    });

    group('deselect - remove books from collection', () {
      test('removes selected books from collection', () async {
        // Arrange
        when(() => mockGetListUseCase()).thenAnswer((_) async =>
            <CollectionData>[collection1, collection2, collection3]);

        await cubit.init({book1, book2});

        // Act
        await cubit.deselect(collection1); // Remove bookId1 from collection1

        // Assert
        final CollectionData updatedCollection1 =
            cubit.state.collectionList.firstWhere((e) => e.id == 'col-1');
        expect(updatedCollection1.bookIds, isNot(contains(bookId1)));
      });

      test('removes collection from selectedCollections when empty', () async {
        // Arrange
        when(() => mockGetListUseCase()).thenAnswer((_) async =>
            <CollectionData>[collection1, collection2]);

        await cubit.init({book1}); // Only book1

        // Act
        await cubit.deselect(collection1); // Remove book1 from collection1

        // Assert
        expect(cubit.state.selectedCollections, isNot(contains(collection1)));
      });

      test('preserves unselected books in collection', () async {
        // Arrange
        final CollectionData mixedCollection = CollectionData(
          id: 'col-mixed',
          name: 'Mixed',
          bookIds: const <String>[bookId1, bookId2, bookId3],
          createdAt: now,
          updatedAt: now,
        );

        when(() => mockGetListUseCase()).thenAnswer(
            (_) async => <CollectionData>[mixedCollection]);

        // Select only book1 and book2
        await cubit.init({book1, book2});

        // Act
        await cubit.deselect(mixedCollection);

        // Assert
        final CollectionData updatedMixed =
            cubit.state.collectionList.firstWhere((e) => e.id == 'col-mixed');
        expect(updatedMixed.bookIds, isNot(contains(bookId1)));
        expect(updatedMixed.bookIds, isNot(contains(bookId2)));
        expect(updatedMixed.bookIds, contains(bookId3)); // Preserved
      });
    });

    group('save', () {
      test('calls updateDataUseCase with all collections', () async {
        // Arrange
        when(() => mockGetListUseCase()).thenAnswer((_) async =>
            <CollectionData>[collection1, collection2, collection3]);

        await cubit.init({book1});

        // Act
        await cubit.save();

        // Assert
        verify(() => mockUpdateDataUseCase(any())).called(1);
      });
    });

    group('edge cases', () {
      test('handles empty collection list', () async {
        // Arrange
        when(() => mockGetListUseCase())
            .thenAnswer((_) async => <CollectionData>[]);

        // Act
        await cubit.init({book1});

        // Assert
        expect(cubit.state.collectionList, isEmpty);
        expect(cubit.state.code, equals(LoadingStateCode.loaded));
      });

      test('handles special characters in collection names', () async {
        // Arrange
        final CollectionData specialCollection = CollectionData(
          id: 'col-special',
          name: 'Collection with spëcial çhars & symbols!',
          bookIds: const <String>[],
          createdAt: now,
          updatedAt: now,
        );

        when(() => mockGetListUseCase()).thenAnswer(
            (_) async => <CollectionData>[specialCollection]);

        // Act
        await cubit.init({book1});

        // Assert
        expect(cubit.state.collectionList[0].name,
            equals('Collection with spëcial çhars & symbols!'));
      });
    });
  });
}
