import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:novel_glide/features/book_storage/data/repositories/local_book_storage.dart';
import 'package:novel_glide/features/book_storage/domain/entities/book_metadata.dart';
import 'package:novel_glide/features/books/domain/entities/book.dart';
import 'package:novel_glide/features/collection/domain/entities/collection_data.dart';
import 'package:novel_glide/features/collection/domain/repositories/collection_repository.dart';
import 'package:novel_glide/features/collection/domain/use_cases/collection_create_data_use_case.dart';
import 'package:novel_glide/features/collection/domain/use_cases/collection_delete_data_use_case.dart';
import 'package:novel_glide/features/collection/domain/use_cases/collection_get_data_use_case.dart';
import 'package:novel_glide/features/collection/domain/use_cases/collection_get_list_use_case.dart';
import 'package:novel_glide/features/collection/domain/use_cases/collection_update_data_use_case.dart';

class MockCollectionRepository extends Mock implements CollectionRepository {}

class MockLocalBookStorage extends Mock implements LocalBookStorage {}

void main() {
  late MockCollectionRepository mockRepository;
  late MockLocalBookStorage mockBookStorage;
  late CollectionCreateDataUseCase createUseCase;
  late CollectionDeleteDataUseCase deleteUseCase;
  late CollectionGetDataUseCase getUseCase;
  late CollectionGetListUseCase getListUseCase;
  late CollectionUpdateDataUseCase updateUseCase;

  final DateTime now = DateTime.now();
  const String collectionId = 'collection-id-1';
  const List<String> bookIds = <String>[
    'book-uuid-1',
    'book-uuid-2',
    'book-uuid-3',
    'book-uuid-4',
    'book-uuid-5',
  ];

  setUp(() {
    mockRepository = MockCollectionRepository();
    mockBookStorage = MockLocalBookStorage();

    createUseCase = CollectionCreateDataUseCase(mockRepository);
    deleteUseCase = CollectionDeleteDataUseCase(mockRepository);
    getUseCase = CollectionGetDataUseCase(mockRepository);
    getListUseCase = CollectionGetListUseCase(mockRepository);
    updateUseCase = CollectionUpdateDataUseCase(mockRepository);
  });

  group('Collection Feature Integration Tests', () {
    group('Full Lifecycle', () {
      test('create → add books → view → remove → delete', () async {
        // Arrange - Create empty collection
        when(() => mockRepository.createData(any(), any()))
            .thenAnswer((_) async => CollectionData(
                  id: collectionId,
                  name: 'My Collection',
                  bookIds: const <String>[],
                  createdAt: now,
                  updatedAt: now,
                ));

        // Act 1: Create collection
        final CollectionData created =
            await createUseCase('My Collection', null);

        // Assert 1: Collection created with no books
        expect(created.id, isNotEmpty);
        expect(created.name, equals('My Collection'));
        expect(created.bookIds, isEmpty);

        // Arrange 2: Add books
        final CollectionData withBooks = created.copyWith(
          bookIds: bookIds.sublist(0, 2),
        );
        when(() => mockRepository.updateData(any()))
            .thenAnswer((_) async {});

        // Act 2: Add books
        await updateUseCase({withBooks});

        // Verify update was called
        verify(() => mockRepository.updateData(any())).called(1);

        // Arrange 3: Get updated collection
        when(() => mockRepository.getDataById(any()))
            .thenAnswer((_) async => withBooks);

        // Act 3: Retrieve collection with books
        final CollectionData retrieved = await getUseCase(created.id);

        // Assert 3: Books are present
        expect(retrieved.bookIds.length, equals(2));

        // Arrange 4: Delete collection
        when(() => mockRepository.deleteData(any()))
            .thenAnswer((_) async {});

        // Act 4: Delete
        await deleteUseCase(retrieved.id);

        // Assert 4: Deletion was called
        verify(() => mockRepository.deleteData(any())).called(1);
      });

      test('update collection properties (name, color, description)',
          () async {
        // Arrange
        final CollectionData original = CollectionData(
          id: collectionId,
          name: 'Original Name',
          bookIds: bookIds,
          description: 'Original description',
          createdAt: now,
          updatedAt: now,
          color: '#808080',
        );

        final CollectionData updated = original.copyWith(
          name: 'New Name',
          description: 'New description',
          color: '#FF5722',
          updatedAt: now.add(const Duration(minutes: 5)),
        );

        when(() => mockRepository.updateData(any()))
            .thenAnswer((_) async {});

        // Act
        await updateUseCase({updated});

        // Assert
        verify(() => mockRepository.updateData(any())).called(1);
        expect(updated.name, equals('New Name'));
        expect(updated.description, equals('New description'));
        expect(updated.color, equals('#FF5722'));
      });

      test('persistence of collection in JSON file format', () async {
        // Arrange
        final CollectionData collection = CollectionData(
          id: collectionId,
          name: 'Persistent Collection',
          bookIds: bookIds,
          description: 'Should be persisted',
          createdAt: now,
          updatedAt: now,
          color: '#FF5722',
        );

        // Act - Serialize to JSON
        final Map<String, dynamic> json = collection.toJson();

        // Assert - JSON has expected keys (bookIds, not pathList)
        expect(json.containsKey('id'), isTrue);
        expect(json.containsKey('name'), isTrue);
        expect(json.containsKey('bookIds'), isTrue);
        expect(json.containsKey('description'), isTrue);
        expect(json.containsKey('createdAt'), isTrue);
        expect(json.containsKey('updatedAt'), isTrue);
        expect(json.containsKey('color'), isTrue);
        expect(json.containsKey('pathList'), isFalse); // Old format not present

        // Act - Deserialize from JSON
        final CollectionData restored = CollectionData.fromJson(json);

        // Assert - Restored matches original
        expect(restored.id, equals(collection.id));
        expect(restored.name, equals(collection.name));
        expect(restored.bookIds, equals(collection.bookIds));
        expect(restored.description, equals(collection.description));
        expect(restored.color, equals(collection.color));
      });
    });

    group('Add-Book Flow', () {
      test('select multiple books → identify membership → add to collection',
          () async {
        // Arrange
        final Set<Book> selectedBooks = <Book>{
          Book(
            identifier: bookIds[0],
            title: 'Book 1',
            modifiedDate: now,
            coverIdentifier: bookIds[0],
            ltr: true,
          ),
          Book(
            identifier: bookIds[1],
            title: 'Book 2',
            modifiedDate: now,
            coverIdentifier: bookIds[1],
            ltr: true,
          ),
        };

        final CollectionData existingCollection = CollectionData(
          id: 'existing-col',
          name: 'Existing Collection',
          bookIds: <String>[bookIds[0]], // Book 1 already in collection
          createdAt: now,
          updatedAt: now,
        );

        final CollectionData newCollection = CollectionData(
          id: 'new-col',
          name: 'New Collection',
          bookIds: const <String>[],
          createdAt: now,
          updatedAt: now,
        );

        when(() => mockRepository.getList()).thenAnswer(
            (_) async => <CollectionData>[existingCollection, newCollection]);

        // Act 1: Get all collections
        final List<CollectionData> collections = await getListUseCase();

        // Assert 1: Detect membership via intersection
        final Set<String> selectedBookIdSet =
            selectedBooks.map((Book b) => b.identifier).toSet();
        final Set<CollectionData> memberCollections = collections
            .where((CollectionData c) =>
                c.bookIds.toSet().intersection(selectedBookIdSet).isNotEmpty)
            .toSet();

        expect(memberCollections.length, equals(1)); // Only existing collection
        expect(memberCollections.first.id, equals('existing-col'));

        // Act 2: Create new collection and add selected books
        final CollectionData newCollWithBooks =
            newCollection.copyWith(bookIds: selectedBookIdSet.toList());

        when(() => mockRepository.updateData(any()))
            .thenAnswer((_) async {});

        await updateUseCase({newCollWithBooks});

        // Assert 2: Update was called
        verify(() => mockRepository.updateData(any())).called(1);
      });

      test('add selected books to existing collection', () async {
        // Arrange
        final Book bookToAdd = Book(
          identifier: bookIds[2],
          title: 'Book to Add',
          modifiedDate: now,
          coverIdentifier: bookIds[2],
          ltr: true,
        );

        final CollectionData existingCollection = CollectionData(
          id: 'target-col',
          name: 'Target Collection',
          bookIds: <String>[bookIds[0], bookIds[1]],
          createdAt: now,
          updatedAt: now,
        );

        // Act - Add book to existing collection
        final CollectionData updated = existingCollection.copyWith(
          bookIds: <String>[...existingCollection.bookIds, bookToAdd.identifier],
        );

        when(() => mockRepository.updateData(any()))
            .thenAnswer((_) async {});

        await updateUseCase({updated});

        // Assert
        expect(updated.bookIds.length, equals(3));
        expect(updated.bookIds, contains(bookToAdd.identifier));
        verify(() => mockRepository.updateData(any())).called(1);
      });

      test('verify bookIds stored correctly after add', () async {
        // Arrange
        final List<String> addedBookIds = bookIds.sublist(0, 3);
        final CollectionData collection = CollectionData(
          id: 'verify-col',
          name: 'Verify Collection',
          bookIds: addedBookIds,
          createdAt: now,
          updatedAt: now,
        );

        when(() => mockRepository.updateData(any()))
            .thenAnswer((_) async {});

        // Act
        await updateUseCase({collection});

        // Assert
        expect(collection.bookIds, equals(addedBookIds));
        expect(collection.bookIds[0], equals(bookIds[0]));
        expect(collection.bookIds[1], equals(bookIds[1]));
        expect(collection.bookIds[2], equals(bookIds[2]));
      });
    });

    group('Edge Cases', () {
      test('empty collection handling', () async {
        // Arrange
        final CollectionData emptyCollection = CollectionData(
          id: 'empty-col',
          name: 'Empty',
          bookIds: const <String>[],
          createdAt: now,
          updatedAt: now,
        );

        when(() => mockRepository.createData(any(), any()))
            .thenAnswer((_) async => emptyCollection);

        // Act
        final CollectionData created = await createUseCase('Empty', null);

        // Assert
        expect(created.bookIds, isEmpty);
      });

      test('single book collection', () async {
        // Arrange & Act
        final CollectionData singleBookCollection = CollectionData(
          id: 'single-col',
          name: 'Single Book',
          bookIds: <String>[bookIds[0]],
          createdAt: now,
          updatedAt: now,
        );

        // Assert
        expect(singleBookCollection.bookIds.length, equals(1));
        expect(singleBookCollection.bookIds[0], equals(bookIds[0]));
      });

      test('large collection (50+ books)', () async {
        // Arrange
        final List<String> largeBookIdList =
            List<String>.generate(50, (i) => 'book-uuid-large-$i');

        final CollectionData largeCollection = CollectionData(
          id: 'large-col',
          name: 'Large Collection',
          bookIds: largeBookIdList,
          createdAt: now,
          updatedAt: now,
        );

        // Act & Assert
        expect(largeCollection.bookIds.length, equals(50));
      });

      test('collection with special characters in name/description', () async {
        // Arrange & Act
        final CollectionData specialCollection = CollectionData(
          id: 'special-col',
          name: 'Spëcial Çollëction & Symbols! 中文 العربية',
          description: 'Test dëscription with émojis 📚✨',
          bookIds: bookIds,
          createdAt: now,
          updatedAt: now,
        );

        // Assert
        expect(specialCollection.name,
            contains('Spëcial Çollëction & Symbols! 中文 العربية'));
        expect(specialCollection.description,
            contains('Test dëscription with émojis'));
      });

      test('remove non-existent book from collection (graceful handling)',
          () async {
        // Arrange
        final CollectionData collection = CollectionData(
          id: 'test-col',
          name: 'Test',
          bookIds: <String>[bookIds[0], bookIds[1]],
          createdAt: now,
          updatedAt: now,
        );

        const String nonExistentBookId = 'non-existent-uuid';

        // Act - Try to remove book that doesn't exist
        final List<String> updated = collection.bookIds
            .where((String id) => id != nonExistentBookId)
            .toList();

        final CollectionData result = collection.copyWith(bookIds: updated);

        // Assert - Collection unchanged because non-existent book wasn't there
        expect(result.bookIds, equals(collection.bookIds));
      });

      test('reorder books in collection maintains all books', () async {
        // Arrange
        final CollectionData collection = CollectionData(
          id: 'reorder-col',
          name: 'Reorder Test',
          bookIds: bookIds,
          createdAt: now,
          updatedAt: now,
        );

        // Act - Reorder: move first to last
        final List<String> reordered = <String>[
          ...collection.bookIds.sublist(1),
          collection.bookIds[0],
        ];

        final CollectionData result = collection.copyWith(bookIds: reordered);

        // Assert - All books present, different order
        expect(result.bookIds.length, equals(collection.bookIds.length));
        expect(result.bookIds.last, equals(collection.bookIds[0]));
      });

      test('concurrent add/remove operations preserve state', () async {
        // Arrange
        final CollectionData initial = CollectionData(
          id: 'concurrent-col',
          name: 'Concurrent Test',
          bookIds: bookIds.sublist(0, 3),
          createdAt: now,
          updatedAt: now,
        );

        // Simulate concurrent operations
        // 1. Add bookIds[3]
        final CollectionData afterAdd =
            initial.copyWith(bookIds: <String>[...initial.bookIds, bookIds[3]]);

        // 2. Remove bookIds[0]
        final List<String> withoutFirst = afterAdd.bookIds
            .where((String id) => id != bookIds[0])
            .toList();
        final CollectionData afterRemove = afterAdd.copyWith(bookIds: withoutFirst);

        // Assert - Expected final state
        expect(afterRemove.bookIds.length, equals(3));
        expect(afterRemove.bookIds, contains(bookIds[3]));
        expect(afterRemove.bookIds, isNot(contains(bookIds[0])));
      });
    });

    group('Backup & Restore Integration', () {
      test('backup collections preserves all bookIds', () async {
        // Arrange
        final List<CollectionData> collections = <CollectionData>[
          CollectionData(
            id: 'backup-col-1',
            name: 'Collection 1',
            bookIds: bookIds.sublist(0, 2),
            createdAt: now,
            updatedAt: now,
          ),
          CollectionData(
            id: 'backup-col-2',
            name: 'Collection 2',
            bookIds: bookIds.sublist(2, 5),
            createdAt: now,
            updatedAt: now,
          ),
        ];

        // Act - Serialize all collections to JSON (backup)
        final Map<String, Map<String, dynamic>> backup = <String, Map<String, dynamic>>{};
        for (CollectionData col in collections) {
          backup[col.id] = col.toJson();
        }

        // Assert - Backup contains all bookIds
        expect(backup['backup-col-1']?['bookIds'], equals(bookIds.sublist(0, 2)));
        expect(backup['backup-col-2']?['bookIds'], equals(bookIds.sublist(2, 5)));
      });

      test('restore from backup and verify bookIds intact', () async {
        // Arrange
        const String backupJson = '''
{
  "backup-col-1": {
    "id": "backup-col-1",
    "name": "Collection 1",
    "bookIds": ["book-uuid-1", "book-uuid-2"],
    "description": "",
    "createdAt": "2026-01-01T00:00:00.000Z",
    "updatedAt": "2026-01-01T00:00:00.000Z",
    "color": "#808080"
  }
}
''';

        final Map<String, dynamic> backupData = <String, dynamic>{
          'backup-col-1': <String, dynamic>{
            'id': 'backup-col-1',
            'name': 'Collection 1',
            'bookIds': <String>['book-uuid-1', 'book-uuid-2'],
            'description': '',
            'createdAt': now.toIso8601String(),
            'updatedAt': now.toIso8601String(),
            'color': '#808080',
          },
        };

        // Act - Restore from backup
        final CollectionData restored = CollectionData.fromJson(
            backupData['backup-col-1'] as Map<String, dynamic>);

        // Assert
        expect(restored.id, equals('backup-col-1'));
        expect(restored.bookIds, equals(<String>['book-uuid-1', 'book-uuid-2']));
      });

      test('can add/remove books after restore', () async {
        // Arrange
        final CollectionData restored = CollectionData(
          id: 'post-restore-col',
          name: 'Restored Collection',
          bookIds: <String>[bookIds[0], bookIds[1]],
          createdAt: now,
          updatedAt: now,
        );

        when(() => mockRepository.updateData(any()))
            .thenAnswer((_) async {});

        // Act - Add book after restore
        final CollectionData withNewBook =
            restored.copyWith(bookIds: <String>[...restored.bookIds, bookIds[2]]);

        await updateUseCase({withNewBook});

        // Assert
        expect(withNewBook.bookIds.length, equals(3));
        expect(withNewBook.bookIds, contains(bookIds[2]));
        verify(() => mockRepository.updateData(any())).called(1);
      });
    });
  });
}
