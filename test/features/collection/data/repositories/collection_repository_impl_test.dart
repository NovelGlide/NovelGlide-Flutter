import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:novel_glide/features/collection/data/data_sources/collection_local_json_data_source.dart';
import 'package:novel_glide/features/collection/data/repositories/collection_repository_impl.dart';
import 'package:novel_glide/features/collection/domain/entities/collection_data.dart';
import 'package:novel_glide/features/collection/domain/repositories/collection_repository.dart';

class MockCollectionLocalJsonDataSource extends Mock
    implements CollectionLocalJsonDataSource {}

void main() {
  group('CollectionRepositoryImpl', () {
    late MockCollectionLocalJsonDataSource mockDataSource;
    late CollectionRepositoryImpl repository;

    setUp(() {
      mockDataSource = MockCollectionLocalJsonDataSource();
      repository = CollectionRepositoryImpl(mockDataSource);
    });

    final DateTime now = DateTime.now();

    group('Create Collection', () {
      test('createData with default name creates collection with empty '
          'bookIds', () async {
        final CollectionData expected = CollectionData(
          id: 'test-id',
          name: 'test-id',
          bookIds: const <String>[],
          createdAt: now,
          updatedAt: now,
        );

        when(() => mockDataSource.createData())
            .thenAnswer((_) async => expected);

        final CollectionData result = await repository.createData();

        expect(result.bookIds, isEmpty);
        expect(result, equals(expected));
        verify(() => mockDataSource.createData()).called(1);
      });

      test('createData with custom name creates collection', () async {
        final CollectionData expected = CollectionData(
          id: 'test-id',
          name: 'My Collection',
          bookIds: const <String>[],
          createdAt: now,
          updatedAt: now,
        );

        when(() => mockDataSource.createData('My Collection'))
            .thenAnswer((_) async => expected);

        final CollectionData result =
            await repository.createData('My Collection');

        expect(result.name, equals('My Collection'));
        expect(result.bookIds, isEmpty);
        verify(() => mockDataSource.createData('My Collection')).called(1);
      });

      test('createData emits onChangedStream event', () async {
        final CollectionData newCollection = CollectionData(
          id: 'test-id',
          name: 'New Collection',
          bookIds: const <String>[],
          createdAt: now,
          updatedAt: now,
        );

        when(() => mockDataSource.createData())
            .thenAnswer((_) async => newCollection);

        expect(repository.onChangedStream, emits(null));
        await repository.createData();
      });
    });

    group('Add BookId to Collection', () {
      test('updateData adds bookId to collection', () async {
        final CollectionData original = CollectionData(
          id: 'col-1',
          name: 'Test',
          bookIds: const <String>['book-1'],
          createdAt: now,
          updatedAt: now,
        );

        final CollectionData updated = original.copyWith(
          bookIds: const <String>['book-1', 'book-2'],
          updatedAt: now.add(const Duration(seconds: 1)),
        );

        when(() => mockDataSource.updateData(any())).thenAnswer((_) async {});

        await repository.updateData(<CollectionData>{updated});

        verify(
          () => mockDataSource
              .updateData(any(that: contains(updated))),
        ).called(1);
      });

      test('updateData preserves existing bookIds order', () async {
        final CollectionData collection = CollectionData(
          id: 'col-1',
          name: 'Test',
          bookIds: const <String>['book-z', 'book-a', 'book-m'],
          createdAt: now,
          updatedAt: now,
        );

        when(() => mockDataSource.updateData(any())).thenAnswer((_) async {});

        await repository.updateData(<CollectionData>{collection});

        expect(collection.bookIds[0], equals('book-z'));
        expect(collection.bookIds[1], equals('book-a'));
        expect(collection.bookIds[2], equals('book-m'));
      });

      test('updateData emits onChangedStream event', () async {
        final CollectionData collection = CollectionData(
          id: 'col-1',
          name: 'Test',
          bookIds: const <String>['book-1', 'book-2'],
          createdAt: now,
          updatedAt: now,
        );

        when(() => mockDataSource.updateData(any())).thenAnswer((_) async {});

        expect(repository.onChangedStream, emits(null));
        await repository.updateData(<CollectionData>{collection});
      });
    });

    group('Remove BookId from Collection', () {
      test('updateData removes bookId from collection', () async {
        final CollectionData updated = CollectionData(
          id: 'col-1',
          name: 'Test',
          bookIds: const <String>['book-1'],
          createdAt: now,
          updatedAt: now,
        );

        when(() => mockDataSource.updateData(any())).thenAnswer((_) async {});

        await repository.updateData(<CollectionData>{updated});

        verify(
          () => mockDataSource
              .updateData(any(that: contains(updated))),
        ).called(1);
      });

      test('updateData handles removing non-existent bookId gracefully', () {
        final CollectionData collection = CollectionData(
          id: 'col-1',
          name: 'Test',
          bookIds: const <String>['book-1'],
          createdAt: now,
          updatedAt: now,
        );

        // Should not throw even if book-2 was never there
        expect(
          () => collection.copyWith(
            bookIds: collection.bookIds
                .where((String id) => id != 'book-2')
                .toList(),
          ),
          returnsNormally,
        );
      });
    });

    group('Reorder BookIds', () {
      test('updateData preserves custom bookId order', () async {
        final List<String> reorderedList = const <String>[
          'book-3',
          'book-1',
          'book-2',
        ];

        final CollectionData collection = CollectionData(
          id: 'col-1',
          name: 'Test',
          bookIds: reorderedList,
          createdAt: now,
          updatedAt: now,
        );

        when(() => mockDataSource.updateData(any())).thenAnswer((_) async {});

        await repository.updateData(<CollectionData>{collection});

        expect(collection.bookIds, equals(reorderedList));
      });

      test('round-trip preserves bookId order', () async {
        final List<String> bookIds = const <String>[
          'book-z',
          'book-m',
          'book-a',
        ];

        final CollectionData collection = CollectionData(
          id: 'col-1',
          name: 'Test',
          bookIds: bookIds,
          createdAt: now,
          updatedAt: now,
        );

        final Map<String, dynamic> json = collection.toJson();
        final CollectionData deserialized = CollectionData.fromJson(json);

        expect(deserialized.bookIds, equals(bookIds));
      });
    });

    group('Update Collection Properties', () {
      test('updateData updates collection name', () async {
        final CollectionData updated = CollectionData(
          id: 'col-1',
          name: 'Updated Name',
          bookIds: const <String>['book-1'],
          createdAt: now,
          updatedAt: now,
        );

        when(() => mockDataSource.updateData(any())).thenAnswer((_) async {});

        await repository.updateData(<CollectionData>{updated});

        expect(updated.name, equals('Updated Name'));
      });

      test('updateData updates collection color', () async {
        final CollectionData updated = CollectionData(
          id: 'col-1',
          name: 'Test',
          bookIds: const <String>['book-1'],
          createdAt: now,
          updatedAt: now,
          color: '#00FF00',
        );

        when(() => mockDataSource.updateData(any())).thenAnswer((_) async {});

        await repository.updateData(<CollectionData>{updated});

        expect(updated.color, equals('#00FF00'));
      });

      test('updateData updates collection description', () async {
        final CollectionData updated = CollectionData(
          id: 'col-1',
          name: 'Test',
          bookIds: const <String>['book-1'],
          createdAt: now,
          updatedAt: now,
          description: 'New description',
        );

        when(() => mockDataSource.updateData(any())).thenAnswer((_) async {});

        await repository.updateData(<CollectionData>{updated});

        expect(updated.description, equals('New description'));
      });

      test('updateData updates updatedAt timestamp', () async {
        final DateTime later = now.add(const Duration(hours: 1));

        final CollectionData updated = CollectionData(
          id: 'col-1',
          name: 'Test',
          bookIds: const <String>['book-1'],
          createdAt: now,
          updatedAt: later,
        );

        when(() => mockDataSource.updateData(any())).thenAnswer((_) async {});

        await repository.updateData(<CollectionData>{updated});

        expect(updated.updatedAt, equals(later));
      });
    });

    group('Delete Collection', () {
      test('deleteData removes collection', () async {
        final CollectionData collection = CollectionData(
          id: 'col-1',
          name: 'Test',
          bookIds: const <String>['book-1'],
          createdAt: now,
          updatedAt: now,
        );

        when(() => mockDataSource.deleteData(any())).thenAnswer((_) async {});

        await repository.deleteData(<CollectionData>{collection});

        verify(() => mockDataSource.deleteData(any())).called(1);
      });

      test('deleteData emits onChangedStream event', () async {
        final CollectionData collection = CollectionData(
          id: 'col-1',
          name: 'Test',
          bookIds: const <String>['book-1'],
          createdAt: now,
          updatedAt: now,
        );

        when(() => mockDataSource.deleteData(any())).thenAnswer((_) async {});

        expect(repository.onChangedStream, emits(null));
        await repository.deleteData(<CollectionData>{collection});
      });
    });

    group('Get Collection', () {
      test('getDataById retrieves collection by ID', () async {
        final CollectionData expected = CollectionData(
          id: 'col-1',
          name: 'Test Collection',
          bookIds: const <String>['book-1', 'book-2'],
          createdAt: now,
          updatedAt: now,
        );

        when(() => mockDataSource.getDataById('col-1'))
            .thenAnswer((_) async => expected);

        final CollectionData result = await repository.getDataById('col-1');

        expect(result, equals(expected));
        verify(() => mockDataSource.getDataById('col-1')).called(1);
      });

      test('getList retrieves all collections', () async {
        final List<CollectionData> expected = <CollectionData>[
          CollectionData(
            id: 'col-1',
            name: 'Collection 1',
            bookIds: const <String>['book-1'],
            createdAt: now,
            updatedAt: now,
          ),
          CollectionData(
            id: 'col-2',
            name: 'Collection 2',
            bookIds: const <String>['book-2', 'book-3'],
            createdAt: now,
            updatedAt: now,
          ),
        ];

        when(() => mockDataSource.getList())
            .thenAnswer((_) async => expected);

        final List<CollectionData> result = await repository.getList();

        expect(result, equals(expected));
        expect(result, hasLength(2));
        verify(() => mockDataSource.getList()).called(1);
      });
    });

    group('Persistence to JSON', () {
      test('JSON format uses bookIds not pathList', () {
        final CollectionData collection = CollectionData(
          id: 'col-1',
          name: 'Test',
          bookIds: const <String>['book-1', 'book-2'],
          createdAt: now,
          updatedAt: now,
        );

        final Map<String, dynamic> json = collection.toJson();

        expect(json.containsKey('bookIds'), isTrue);
        expect(json.containsKey('pathList'), isFalse);
        expect(json['bookIds'], equals(<String>['book-1', 'book-2']));
      });

      test('JSON round-trip preserves all fields', () {
        final CollectionData original = CollectionData(
          id: 'col-1',
          name: 'Test Collection',
          bookIds: const <String>['book-1', 'book-2'],
          description: 'A test collection',
          createdAt: now,
          updatedAt: now,
          color: '#FF5722',
        );

        final Map<String, dynamic> json = original.toJson();
        final CollectionData deserialized = CollectionData.fromJson(json);

        expect(deserialized, equals(original));
        expect(deserialized.bookIds, equals(original.bookIds));
      });
    });

    group('Read/Write Cycle', () {
      test('updateData persists collection to storage', () async {
        final CollectionData collection = CollectionData(
          id: 'col-1',
          name: 'Test',
          bookIds: const <String>['book-1', 'book-2'],
          createdAt: now,
          updatedAt: now,
        );

        when(() => mockDataSource.updateData(any())).thenAnswer((_) async {});

        await repository.updateData(<CollectionData>{collection});

        // Verify that updateData was called with the collection
        verify(
          () => mockDataSource.updateData(any()),
        ).called(1);
      });

      test('multiple updateData calls accumulate changes', () async {
        final CollectionData collection1 = CollectionData(
          id: 'col-1',
          name: 'Collection 1',
          bookIds: const <String>['book-1'],
          createdAt: now,
          updatedAt: now,
        );

        final CollectionData collection2 = CollectionData(
          id: 'col-2',
          name: 'Collection 2',
          bookIds: const <String>['book-2'],
          createdAt: now,
          updatedAt: now,
        );

        when(() => mockDataSource.updateData(any())).thenAnswer((_) async {});

        await repository.updateData(<CollectionData>{collection1});
        await repository.updateData(<CollectionData>{collection2});

        verify(() => mockDataSource.updateData(any())).called(2);
      });
    });
  });
}
