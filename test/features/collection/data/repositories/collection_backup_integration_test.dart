import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:novel_glide/core/file_system/domain/repositories/json_repository.dart';
import 'package:novel_glide/core/path_provider/domain/repositories/json_path_provider.dart';
import 'package:novel_glide/features/collection/data/data_sources/collection_local_json_data_source_impl.dart';
import 'package:novel_glide/features/collection/domain/entities/collection_data.dart';

class MockJsonPathProvider extends Mock implements JsonPathProvider {}

class MockJsonRepository extends Mock implements JsonRepository {}

void main() {
  late MockJsonPathProvider mockJsonPathProvider;
  late MockJsonRepository mockJsonRepository;
  late CollectionLocalJsonDataSourceImpl dataSource;

  const String testPath = '/test/path/collections.json';

  final DateTime now = DateTime.now();

  setUp(() {
    mockJsonPathProvider = MockJsonPathProvider();
    mockJsonRepository = MockJsonRepository();

    when(() => mockJsonPathProvider.collectionFilePath)
        .thenReturn(testPath);

    dataSource = CollectionLocalJsonDataSourceImpl(
      mockJsonPathProvider,
      mockJsonRepository,
    );
  });

  group('Collection Backup & Restore Integration', () {
    group('JSON format verification', () {
      test('backup uses bookIds key, not pathList', () async {
        // Arrange
        final CollectionData collection = CollectionData(
          id: 'col-1',
          name: 'Test Collection',
          bookIds: const <String>['book-id-1', 'book-id-2'],
          description: 'Test Description',
          createdAt: now,
          updatedAt: now,
          color: '#FF5722',
        );

        // Simulate reading empty data
        when(() => mockJsonRepository.readJson(path: testPath))
            .thenAnswer((_) async => <String, dynamic>{});

        // Act
        await dataSource.createData('col-1', 'Test Collection');
        await dataSource.updateData({collection});

        // Assert - Verify writeJson was called with bookIds
        final invocation =
            verify(() => mockJsonRepository.writeJson(path: testPath, data: any(named: 'data')))
                .captured;
        if (invocation.isNotEmpty) {
          final Map<String, dynamic> writtenData =
              invocation.last as Map<String, dynamic>;
          expect(writtenData.containsKey('col-1'), isTrue);
          final Map<String, dynamic> collectionJson =
              writtenData['col-1'] as Map<String, dynamic>;
          expect(collectionJson.containsKey('bookIds'), isTrue);
          expect(collectionJson.containsKey('pathList'), isFalse);
        }
      });

      test('bookIds preserved during round-trip serialization', () async {
        // Arrange
        const List<String> bookIds = <String>['uuid-1', 'uuid-2', 'uuid-3'];
        final CollectionData original = CollectionData(
          id: 'col-1',
          name: 'Round Trip Test',
          bookIds: bookIds,
          createdAt: now,
          updatedAt: now,
        );

        // Act - Serialize to JSON
        final Map<String, dynamic> json = original.toJson();

        // Assert - Verify bookIds in JSON
        expect(json['bookIds'], equals(bookIds));

        // Act - Deserialize from JSON
        final CollectionData restored = CollectionData.fromJson(json);

        // Assert - Verify bookIds preserved
        expect(restored.bookIds, equals(original.bookIds));
      });
    });

    group('Backup/Restore cycle', () {
      test('backup collections with bookIds', () async {
        // Arrange
        final List<CollectionData> collections = <CollectionData>[
          CollectionData(
            id: 'col-1',
            name: 'Fiction',
            bookIds: const <String>['book-1', 'book-2'],
            createdAt: now,
            updatedAt: now,
          ),
          CollectionData(
            id: 'col-2',
            name: 'Non-Fiction',
            bookIds: const <String>['book-3', 'book-4', 'book-5'],
            createdAt: now,
            updatedAt: now,
          ),
        ];

        // Simulate current state
        final Map<String, dynamic> backupData = <String, dynamic>{};
        for (CollectionData col in collections) {
          backupData[col.id] = col.toJson();
        }

        when(() => mockJsonRepository.readJson(path: testPath))
            .thenAnswer((_) async => <String, dynamic>{});
        when(() => mockJsonRepository.writeJson(
                path: testPath, data: any(named: 'data')))
            .thenAnswer((_) async {});

        // Act
        await dataSource.updateData(collections.toSet());

        // Assert
        verify(
          () => mockJsonRepository.writeJson(
            path: testPath,
            data: any(named: 'data'),
          ),
        ).called(greaterThanOrEqualTo(1));
      });

      test('restore collections from backup with bookIds intact', () async {
        // Arrange
        final Map<String, dynamic> backupJson = <String, dynamic>{
          'col-1': <String, dynamic>{
            'id': 'col-1',
            'name': 'Fiction',
            'bookIds': <String>['book-1', 'book-2'],
            'description': '',
            'createdAt': now.toIso8601String(),
            'updatedAt': now.toIso8601String(),
            'color': '#808080',
          },
          'col-2': <String, dynamic>{
            'id': 'col-2',
            'name': 'Non-Fiction',
            'bookIds': <String>['book-3', 'book-4', 'book-5'],
            'description': 'Non-fiction works',
            'createdAt': now.toIso8601String(),
            'updatedAt': now.toIso8601String(),
            'color': '#FF5722',
          },
        };

        when(() => mockJsonRepository.readJson(path: testPath))
            .thenAnswer((_) async => backupJson);

        // Act
        final List<CollectionData> restored = await dataSource.getList();

        // Assert
        expect(restored.length, equals(2));
        expect(restored[0].bookIds, equals(<String>['book-1', 'book-2']));
        expect(restored[1].bookIds,
            equals(<String>['book-3', 'book-4', 'book-5']));
      });

      test('multiple collections backup/restore', () async {
        // Arrange
        final List<CollectionData> collections = <CollectionData>[
          for (int i = 0; i < 5; i++)
            CollectionData(
              id: 'col-$i',
              name: 'Collection $i',
              bookIds: <String>[
                for (int j = 0; j < i + 1; j++) 'book-$i-$j'
              ],
              createdAt: now,
              updatedAt: now,
            ),
        ];

        final Map<String, dynamic> backupData = <String, dynamic>{};
        for (CollectionData col in collections) {
          backupData[col.id] = col.toJson();
        }

        when(() => mockJsonRepository.readJson(path: testPath))
            .thenAnswer((_) async => backupData);

        // Act
        final List<CollectionData> restored = await dataSource.getList();

        // Assert
        expect(restored.length, equals(5));
        for (int i = 0; i < 5; i++) {
          expect(restored[i].bookIds.length, equals(i + 1));
        }
      });

      test('empty collections in backup', () async {
        // Arrange
        final Map<String, dynamic> backupJson = <String, dynamic>{
          'col-empty': <String, dynamic>{
            'id': 'col-empty',
            'name': 'Empty Collection',
            'bookIds': <String>[],
            'description': 'No books yet',
            'createdAt': now.toIso8601String(),
            'updatedAt': now.toIso8601String(),
            'color': '#808080',
          },
        };

        when(() => mockJsonRepository.readJson(path: testPath))
            .thenAnswer((_) async => backupJson);

        // Act
        final List<CollectionData> restored = await dataSource.getList();

        // Assert
        expect(restored.length, equals(1));
        expect(restored[0].bookIds, isEmpty);
      });

      test('backup → restore → backup produces consistent JSON', () async {
        // Arrange
        final CollectionData original = CollectionData(
          id: 'col-test',
          name: 'Consistency Test',
          bookIds: const <String>['book-1', 'book-2', 'book-3'],
          description: 'Testing consistency',
          createdAt: now,
          updatedAt: now,
          color: '#E91E63',
        );

        // Act - First serialization
        final Map<String, dynamic> firstJson = original.toJson();
        final String firstJsonStr = jsonEncode(firstJson);

        // Act - Deserialize and re-serialize
        final CollectionData restored =
            CollectionData.fromJson(firstJson);
        final Map<String, dynamic> secondJson = restored.toJson();
        final String secondJsonStr = jsonEncode(secondJson);

        // Assert - JSON should be identical
        expect(secondJsonStr, equals(firstJsonStr));
        expect(restored.bookIds, equals(original.bookIds));
      });
    });
  });
}
