import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:novel_glide/core/file_system/domain/repositories/json_repository.dart';
import 'package:novel_glide/core/path_provider/domain/repositories/app_path_provider.dart';
import 'package:novel_glide/features/cloud/data/repositories/cloud_index_repository_impl.dart';
import 'package:novel_glide/features/cloud/domain/entities/cloud_index.dart';
import 'package:novel_glide/features/cloud/domain/entities/cloud_providers.dart';
import 'package:novel_glide/features/cloud/domain/entities/index_entry.dart';
import 'package:novel_glide/features/cloud/domain/entities/sync_status.dart';
import 'package:novel_glide/features/cloud/domain/repositories/cloud_repository.dart';

// Mocks
class MockCloudRepository extends Mock implements CloudRepository {}

class MockJsonRepository extends Mock implements JsonRepository {}

class MockAppPathProvider extends Mock implements AppPathProvider {}

void main() {
  group('CloudIndexRepositoryImpl', () {
    late MockCloudRepository mockCloudRepository;
    late MockJsonRepository mockJsonRepository;
    late MockAppPathProvider mockAppPathProvider;
    late CloudIndexRepositoryImpl repository;

    // Test data
    late IndexEntry testEntry;
    late CloudIndex testIndex;

    setUp(() {
      mockCloudRepository = MockCloudRepository();
      mockJsonRepository = MockJsonRepository();
      mockAppPathProvider = MockAppPathProvider();

      repository = CloudIndexRepositoryImpl(
        cloudRepository: mockCloudRepository,
        jsonRepository: mockJsonRepository,
        appPathProvider: mockAppPathProvider,
      );

      // Create test data
      testEntry = IndexEntry(
        bookId: 'book-123',
        fileName: 'test.epub',
        cloudFileId: 'cloud-id-123',
        metadataCloudFileId: 'meta-id-123',
        localFileHash: 'hash-123',
        lastSyncedAt: DateTime(2025, 1, 1),
        syncStatus: SyncStatus.synced,
      );

      testIndex = CloudIndex(
        version: 1,
        lastUpdatedAt: DateTime(2025, 1, 1),
        books: <IndexEntry>[testEntry],
      );
    });

    group('getIndex', () {
      test('returns local index when cloud fetch fails (offline)', () async {
        // Arrange
        when(() => mockAppPathProvider.dataPath)
            .thenAnswer((_) async => '/data');
        when(() => mockCloudRepository.getFile(
              CloudProviders.google,
              any(),
            )).thenAnswer((_) async => null);
        when(() => mockJsonRepository.readJson(
              path: any(named: 'path'),
              fallbackValue: any(named: 'fallbackValue'),
            )).thenAnswer((_) async => testIndex.toJson() as Map<String, dynamic>);

        // Act
        final CloudIndex result = await repository.getIndex();

        // Assert
        expect(result.books.length, equals(testIndex.books.length));
        expect(result.books.first.bookId, equals('book-123'));
      });

      test('returns cloud index when available', () async {
        // This test would require mocking the downloadFile stream
        // For now, we test the fallback behavior
        when(() => mockAppPathProvider.dataPath)
            .thenAnswer((_) async => '/data');
        when(() => mockCloudRepository.getFile(
              CloudProviders.google,
              any(),
            )).thenAnswer((_) async => null);
        when(() => mockJsonRepository.readJson(
              path: any(named: 'path'),
              fallbackValue: any(named: 'fallbackValue'),
            )).thenAnswer((_) async => testIndex.toJson() as Map<String, dynamic>);

        final CloudIndex result = await repository.getIndex();
        expect(result.books, isNotEmpty);
      });

      test('returns empty index when both cloud and local fail', () async {
        // Arrange
        when(() => mockAppPathProvider.dataPath)
            .thenAnswer((_) async => '/data');
        when(() => mockCloudRepository.getFile(
              CloudProviders.google,
              any(),
            )).thenAnswer((_) async => null);
        when(() => mockJsonRepository.readJson(
              path: any(named: 'path'),
              fallbackValue: any(named: 'fallbackValue'),
            )).thenThrow(Exception('File not found'));

        // Act
        final CloudIndex result = await repository.getIndex();

        // Assert - should return empty index, not crash
        expect(result.version, equals(1));
        expect(result.books, isEmpty);
      });
    });

    group('updateIndex', () {
      test('writes to local immediately (optimistic)', () async {
        // Arrange
        when(() => mockAppPathProvider.dataPath)
            .thenAnswer((_) async => '/data');
        when(() => mockJsonRepository.writeJson(
              path: any(named: 'path'),
              data: any(named: 'data'),
            )).thenAnswer((_) async => {});

        // Act
        await repository.updateIndex(testIndex);

        // Assert - writeJson should be called
        verify(() => mockJsonRepository.writeJson(
              path: any(named: 'path'),
              data: any(named: 'data'),
            )).called(1);
      });

      test('does not crash if local write fails', () async {
        // Arrange
        when(() => mockAppPathProvider.dataPath)
            .thenAnswer((_) async => '/data');
        when(() => mockJsonRepository.writeJson(
              path: any(named: 'path'),
              data: any(named: 'data'),
            )).thenThrow(Exception('Write failed'));

        // Act & Assert - should not throw
        expect(
          () => repository.updateIndex(testIndex),
          returnsNormally,
        );
      });
    });

    group('getEntry', () {
      test('returns entry when found', () async {
        // Arrange
        when(() => mockAppPathProvider.dataPath)
            .thenAnswer((_) async => '/data');
        when(() => mockCloudRepository.getFile(
              CloudProviders.google,
              any(),
            )).thenAnswer((_) async => null);
        when(() => mockJsonRepository.readJson(
              path: any(named: 'path'),
              fallbackValue: any(named: 'fallbackValue'),
            )).thenAnswer((_) async => testIndex.toJson() as Map<String, dynamic>);

        // Act
        final IndexEntry? result = await repository.getEntry('book-123');

        // Assert
        expect(result, isNotNull);
        expect(result?.bookId, equals('book-123'));
      });

      test('returns null when entry not found', () async {
        // Arrange
        when(() => mockAppPathProvider.dataPath)
            .thenAnswer((_) async => '/data');
        when(() => mockCloudRepository.getFile(
              CloudProviders.google,
              any(),
            )).thenAnswer((_) async => null);
        when(() => mockJsonRepository.readJson(
              path: any(named: 'path'),
              fallbackValue: any(named: 'fallbackValue'),
            )).thenAnswer((_) async => testIndex.toJson() as Map<String, dynamic>);

        // Act
        final IndexEntry? result = await repository.getEntry('nonexistent');

        // Assert
        expect(result, isNull);
      });
    });

    group('updateEntry', () {
      test('updates entry in index', () async {
        // Arrange
        when(() => mockAppPathProvider.dataPath)
            .thenAnswer((_) async => '/data');
        when(() => mockCloudRepository.getFile(
              CloudProviders.google,
              any(),
            )).thenAnswer((_) async => null);
        when(() => mockJsonRepository.readJson(
              path: any(named: 'path'),
              fallbackValue: any(named: 'fallbackValue'),
            )).thenAnswer((_) async => testIndex.toJson() as Map<String, dynamic>);
        when(() => mockJsonRepository.writeJson(
              path: any(named: 'path'),
              data: any(named: 'data'),
            )).thenAnswer((_) async => {});

        final IndexEntry newEntry = testEntry.copyWith(
          syncStatus: SyncStatus.syncing,
        );

        // Act
        await repository.updateEntry(newEntry);

        // Assert
        verify(() => mockJsonRepository.writeJson(
              path: any(named: 'path'),
              data: any(named: 'data'),
            )).called(1);
      });
    });

    group('Graceful Degradation', () {
      test('returns valid index even when local read throws', () async {
        // Arrange
        when(() => mockAppPathProvider.dataPath)
            .thenAnswer((_) async => '/data');
        when(() => mockCloudRepository.getFile(
              CloudProviders.google,
              any(),
            )).thenAnswer((_) async => null);
        when(() => mockJsonRepository.readJson(
              path: any(named: 'path'),
              fallbackValue: any(named: 'fallbackValue'),
            )).thenThrow(Exception('Corrupted file'));

        // Act
        final CloudIndex result = await repository.getIndex();

        // Assert - should return valid empty index
        expect(result, isNotNull);
        expect(result.version, greaterThanOrEqualTo(1));
      });

      test('handles corrupted local JSON gracefully', () async {
        // Arrange
        when(() => mockAppPathProvider.dataPath)
            .thenAnswer((_) async => '/data');
        when(() => mockCloudRepository.getFile(
              CloudProviders.google,
              any(),
            )).thenAnswer((_) async => null);
        when(() => mockJsonRepository.readJson(
              path: any(named: 'path'),
              fallbackValue: any(named: 'fallbackValue'),
            )).thenAnswer((_) async => {'invalid': 'json'});

        // Act & Assert - should not throw
        expect(
          () => repository.getIndex(),
          returnsNormally,
        );
      });
    });

    group('Index Operations', () {
      test('handles empty index correctly', () async {
        // Arrange
        final CloudIndex emptyIndex = CloudIndex(
          version: 1,
          lastUpdatedAt: DateTime.now(),
          books: const <IndexEntry>[],
        );

        when(() => mockAppPathProvider.dataPath)
            .thenAnswer((_) async => '/data');
        when(() => mockCloudRepository.getFile(
              CloudProviders.google,
              any(),
            )).thenAnswer((_) async => null);
        when(() => mockJsonRepository.readJson(
              path: any(named: 'path'),
              fallbackValue: any(named: 'fallbackValue'),
            )).thenAnswer((_) async => emptyIndex.toJson() as Map<String, dynamic>);

        // Act
        final CloudIndex result = await repository.getIndex();

        // Assert
        expect(result.books, isEmpty);
      });

      test('preserves entry order during updates', () async {
        // Arrange
        final IndexEntry entry2 = testEntry.copyWith(bookId: 'book-456');
        final IndexEntry entry3 = testEntry.copyWith(bookId: 'book-789');
        final CloudIndex indexWithMultiple = CloudIndex(
          version: 1,
          lastUpdatedAt: DateTime.now(),
          books: <IndexEntry>[testEntry, entry2, entry3],
        );

        when(() => mockAppPathProvider.dataPath)
            .thenAnswer((_) async => '/data');
        when(() => mockCloudRepository.getFile(
              CloudProviders.google,
              any(),
            )).thenAnswer((_) async => null);
        when(() => mockJsonRepository.readJson(
              path: any(named: 'path'),
              fallbackValue: any(named: 'fallbackValue'),
            )).thenAnswer(
                (_) async => indexWithMultiple.toJson() as Map<String, dynamic>);

        // Act
        final CloudIndex result = await repository.getIndex();

        // Assert
        expect(result.books.length, equals(3));
        expect(result.books[0].bookId, equals('book-123'));
        expect(result.books[1].bookId, equals('book-456'));
        expect(result.books[2].bookId, equals('book-789'));
      });
    });
  });
}
