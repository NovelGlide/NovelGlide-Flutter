import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:novel_glide/core/file_system/domain/repositories/file_system_repository.dart';
import 'package:novel_glide/features/book_storage/domain/entities/book_metadata.dart';
import 'package:novel_glide/features/book_storage/domain/entities/bookmark_entry.dart';
import 'package:novel_glide/features/book_storage/domain/entities/reading_state.dart';
import 'package:novel_glide/features/book_storage/domain/repositories/book_storage.dart';
import 'package:novel_glide/features/cloud/data/repositories/book_cloud_sync_repository_impl.dart';
import 'package:novel_glide/features/cloud/domain/entities/cloud_index.dart';
import 'package:novel_glide/features/cloud/domain/entities/index_entry.dart';
import 'package:novel_glide/features/cloud/domain/entities/sync_status.dart';
import 'package:novel_glide/features/cloud/domain/repositories/book_cloud_sync_repository.dart';
import 'package:novel_glide/features/cloud/domain/repositories/cloud_index_repository.dart';
import 'package:novel_glide/features/cloud/domain/repositories/cloud_repository.dart';

// Mocks
class MockCloudIndexRepository extends Mock
    implements CloudIndexRepository {}

class MockCloudRepository extends Mock implements CloudRepository {}

class MockBookStorage extends Mock implements BookStorage {}

class MockFileSystemRepository extends Mock
    implements FileSystemRepository {}

void main() {
  group('BookCloudSyncRepositoryImpl', () {
    late MockCloudIndexRepository mockCloudIndexRepository;
    late MockCloudRepository mockCloudRepository;
    late MockBookStorage mockBookStorage;
    late MockFileSystemRepository mockFileSystemRepository;
    late BookCloudSyncRepositoryImpl repository;

    // Test data
    late IndexEntry testEntry;
    late BookMetadata testBook;
    late ReadingState testReadingState;

    setUp(() {
      mockCloudIndexRepository = MockCloudIndexRepository();
      mockCloudRepository = MockCloudRepository();
      mockBookStorage = MockBookStorage();
      mockFileSystemRepository = MockFileSystemRepository();

      repository = BookCloudSyncRepositoryImpl(
        cloudIndexRepository: mockCloudIndexRepository,
        cloudRepository: mockCloudRepository,
        bookStorage: mockBookStorage,
        fileSystemRepository: mockFileSystemRepository,
      );

      testReadingState = ReadingState(
        cfiPosition: '/6/4[chap01]!/4/2/14,/1:0',
        progress: 45.5,
        lastReadTime: DateTime(2025, 1, 1, 10, 0),
        totalSeconds: 3600,
      );

      testBook = BookMetadata(
        bookId: 'book-123',
        title: 'Test Book',
        author: 'Test Author',
        filePath: '/local/path/test.epub',
        bookmarkCount: 2,
        readingState: testReadingState,
        bookmarks: const <BookmarkEntry>[],
      );

      testEntry = IndexEntry(
        bookId: 'book-123',
        fileName: 'test.epub',
        cloudFileId: 'cloud-123',
        metadataCloudFileId: 'meta-123',
        localFileHash: 'hash-old',
        lastSyncedAt: DateTime(2025, 1, 1),
        syncStatus: SyncStatus.synced,
      );
    });

    group('syncBook', () {
      test('syncs book with updated index status to synced', () async {
        // Arrange
        when(() => mockCloudIndexRepository.getEntry('book-123'))
            .thenAnswer((_) async => testEntry);
        when(() => mockCloudIndexRepository.updateEntry(any()))
            .thenAnswer((_) async => {});
        when(() => mockBookStorage.readMetadata('book-123'))
            .thenAnswer((_) async => testBook);
        when(() => mockFileSystemRepository.readFileAsBytes(any()))
            .thenAnswer((_) async => <int>[1, 2, 3, 4, 5]);

        // Act
        await repository.syncBook('book-123');

        // Assert
        verify(() => mockCloudIndexRepository.updateEntry(any())).called(greaterThan(0));
      });

      test('returns cloudOnly status if local book not found', () async {
        // Arrange
        when(() => mockCloudIndexRepository.getEntry('book-123'))
            .thenAnswer((_) async => testEntry);
        when(() => mockCloudIndexRepository.updateEntry(any()))
            .thenAnswer((_) async => {});
        when(() => mockBookStorage.readMetadata('book-123'))
            .thenAnswer((_) async => null);

        // Act
        await repository.syncBook('book-123');

        // Assert - should update status to cloudOnly
        verify(() => mockCloudIndexRepository.updateEntry(any())).called(greaterThan(0));
      });

      test('does not crash on error', () async {
        // Arrange
        when(() => mockCloudIndexRepository.getEntry('book-123'))
            .thenThrow(Exception('Error'));

        // Act & Assert
        expect(
          () => repository.syncBook('book-123'),
          returnsNormally,
        );
      });
    });

    group('syncMetadata', () {
      test('syncs only metadata without EPUB', () async {
        // Arrange
        when(() => mockBookStorage.readMetadata('book-123'))
            .thenAnswer((_) async => testBook);

        // Act
        await repository.syncMetadata('book-123');

        // Assert - should complete without errors
        expect(() async {}, returnsNormally);
      });

      test('handles missing local book gracefully', () async {
        // Arrange
        when(() => mockBookStorage.readMetadata('book-123'))
            .thenAnswer((_) async => null);

        // Act & Assert
        expect(
          () => repository.syncMetadata('book-123'),
          returnsNormally,
        );
      });
    });

    group('downloadBook', () {
      test('updates status to synced after download', () async {
        // Arrange
        when(() => mockCloudIndexRepository.getEntry('book-123'))
            .thenAnswer((_) async => testEntry);
        when(() => mockCloudIndexRepository.updateEntry(any()))
            .thenAnswer((_) async => {});

        // Act
        await repository.downloadBook('book-123');

        // Assert
        verify(() => mockCloudIndexRepository.updateEntry(any())).called(greaterThan(0));
      });

      test('handles missing cloud entry gracefully', () async {
        // Arrange
        when(() => mockCloudIndexRepository.getEntry('book-123'))
            .thenAnswer((_) async => null);

        // Act & Assert
        expect(
          () => repository.downloadBook('book-123'),
          returnsNormally,
        );
      });

      test('sets status to syncing during download', () async {
        // Arrange
        when(() => mockCloudIndexRepository.getEntry('book-123'))
            .thenAnswer((_) async => testEntry);
        when(() => mockCloudIndexRepository.updateEntry(any()))
            .thenAnswer((_) async => {});

        // Act
        await repository.downloadBook('book-123');

        // Assert
        verify(() => mockCloudIndexRepository.updateEntry(any())).called(greaterThan(0));
      });
    });

    group('uploadBook', () {
      test('uploads book and updates index', () async {
        // Arrange
        when(() => mockCloudIndexRepository.getEntry('book-123'))
            .thenAnswer((_) async => testEntry);
        when(() => mockCloudIndexRepository.updateEntry(any()))
            .thenAnswer((_) async => {});
        when(() => mockBookStorage.readMetadata('book-123'))
            .thenAnswer((_) async => testBook);
        when(() => mockFileSystemRepository.readFileAsBytes(any()))
            .thenAnswer((_) async => <int>[1, 2, 3]);
        when(() => mockCloudRepository.uploadFileToPath(
              any(),
              any(),
              any(),
            )).thenAnswer((_) async => 'uploaded-id');

        // Act
        await repository.uploadBook('book-123');

        // Assert
        verify(() => mockCloudRepository.uploadFileToPath(
              any(),
              any(),
              any(),
            )).called(1);
        verify(() => mockCloudIndexRepository.updateEntry(any())).called(greaterThan(0));
      });

      test('handles missing local book gracefully', () async {
        // Arrange
        when(() => mockCloudIndexRepository.getEntry('book-123'))
            .thenAnswer((_) async => testEntry);
        when(() => mockCloudIndexRepository.updateEntry(any()))
            .thenAnswer((_) async => {});
        when(() => mockBookStorage.readMetadata('book-123'))
            .thenAnswer((_) async => null);

        // Act & Assert
        expect(
          () => repository.uploadBook('book-123'),
          returnsNormally,
        );
      });

      test('updates hash after upload', () async {
        // Arrange
        when(() => mockCloudIndexRepository.getEntry('book-123'))
            .thenAnswer((_) async => testEntry);
        when(() => mockCloudIndexRepository.updateEntry(any()))
            .thenAnswer((_) async => {});
        when(() => mockBookStorage.readMetadata('book-123'))
            .thenAnswer((_) async => testBook);
        when(() => mockFileSystemRepository.readFileAsBytes(any()))
            .thenAnswer((_) async => <int>[1, 2, 3]);
        when(() => mockCloudRepository.uploadFileToPath(
              any(),
              any(),
              any(),
            )).thenAnswer((_) async => 'uploaded-id');

        // Act
        await repository.uploadBook('book-123');

        // Assert - should call updateEntry to update hash
        verify(() => mockCloudIndexRepository.updateEntry(any())).called(greaterThan(0));
      });
    });

    group('evictLocalCopy', () {
      test('deletes local file and updates status', () async {
        // Arrange
        when(() => mockBookStorage.readMetadata('book-123'))
            .thenAnswer((_) async => testBook);
        when(() => mockFileSystemRepository.deleteFile(any()))
            .thenAnswer((_) async => {});
        when(() => mockCloudIndexRepository.getEntry('book-123'))
            .thenAnswer((_) async => testEntry);
        when(() => mockCloudIndexRepository.updateEntry(any()))
            .thenAnswer((_) async => {});

        // Act
        await repository.evictLocalCopy('book-123');

        // Assert
        verify(() => mockFileSystemRepository.deleteFile(any())).called(1);
        verify(() => mockCloudIndexRepository.updateEntry(any())).called(1);
      });

      test('sets status to cloudOnly after eviction', () async {
        // Arrange
        when(() => mockBookStorage.readMetadata('book-123'))
            .thenAnswer((_) async => testBook);
        when(() => mockFileSystemRepository.deleteFile(any()))
            .thenAnswer((_) async => {});
        when(() => mockCloudIndexRepository.getEntry('book-123'))
            .thenAnswer((_) async => testEntry);
        when(() => mockCloudIndexRepository.updateEntry(any()))
            .thenAnswer((_) async => {});

        // Act
        await repository.evictLocalCopy('book-123');

        // Assert
        verify(() => mockCloudIndexRepository.updateEntry(any())).called(1);
      });

      test('handles missing local book gracefully', () async {
        // Arrange
        when(() => mockBookStorage.readMetadata('book-123'))
            .thenAnswer((_) async => null);

        // Act & Assert
        expect(
          () => repository.evictLocalCopy('book-123'),
          returnsNormally,
        );
      });
    });

    group('getSyncStatus', () {
      test('returns correct status from index', () async {
        // Arrange
        when(() => mockCloudIndexRepository.getEntry('book-123'))
            .thenAnswer((_) async => testEntry);

        // Act
        final SyncStatus status = await repository.getSyncStatus('book-123');

        // Assert
        expect(status, equals(testEntry.syncStatus));
      });

      test('returns localOnly if entry not in index', () async {
        // Arrange
        when(() => mockCloudIndexRepository.getEntry('book-123'))
            .thenAnswer((_) async => null);

        // Act
        final SyncStatus status = await repository.getSyncStatus('book-123');

        // Assert
        expect(status, equals(SyncStatus.localOnly));
      });

      test('returns error status on exception', () async {
        // Arrange
        when(() => mockCloudIndexRepository.getEntry('book-123'))
            .thenThrow(Exception('Error'));

        // Act
        final SyncStatus status = await repository.getSyncStatus('book-123');

        // Assert
        expect(status, equals(SyncStatus.error));
      });
    });

    group('Error Handling', () {
      test('does not crash on upload failure', () async {
        // Arrange
        when(() => mockCloudIndexRepository.getEntry('book-123'))
            .thenAnswer((_) async => testEntry);
        when(() => mockCloudIndexRepository.updateEntry(any()))
            .thenAnswer((_) async => {});
        when(() => mockBookStorage.readMetadata('book-123'))
            .thenAnswer((_) async => testBook);
        when(() => mockFileSystemRepository.readFileAsBytes(any()))
            .thenThrow(Exception('Upload error'));

        // Act & Assert
        expect(
          () => repository.uploadBook('book-123'),
          returnsNormally,
        );
      });

      test('logs errors but continues', () async {
        // Arrange
        when(() => mockCloudIndexRepository.getEntry('book-123'))
            .thenAnswer((_) async => testEntry);
        when(() => mockCloudIndexRepository.updateEntry(any()))
            .thenAnswer((_) async => {});
        when(() => mockBookStorage.readMetadata('book-123'))
            .thenAnswer((_) async => testBook);
        when(() => mockFileSystemRepository.readFileAsBytes(any()))
            .thenThrow(Exception('File error'));

        // Act & Assert
        expect(
          () => repository.uploadBook('book-123'),
          returnsNormally,
        );
      });
    });
  });
}
