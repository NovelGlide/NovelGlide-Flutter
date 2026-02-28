import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:novel_glide/features/book_storage/data/repositories/cloud_book_storage.dart';
import 'package:novel_glide/features/book_storage/domain/entities/book_metadata.dart';
import 'package:novel_glide/features/book_storage/domain/entities/reading_state.dart';
import 'package:novel_glide/features/book_storage/domain/entities/bookmark_entry.dart';
import 'package:novel_glide/features/book_storage/domain/repositories/book_storage.dart';
import 'package:novel_glide/features/cloud/domain/entities/cloud_file.dart';
import 'package:novel_glide/features/cloud/domain/entities/cloud_providers.dart';
import 'package:novel_glide/features/cloud/domain/entities/drive_file_metadata.dart';
import 'package:novel_glide/features/cloud/domain/repositories/cloud_repository.dart';

class MockCloudRepository extends Mock implements CloudRepository {}

void main() {
  group('CloudBookStorage', () {
    late MockCloudRepository mockCloudRepository;
    late CloudBookStorage cloudBookStorage;

    const String bookId = 'test-book-id-123';
    const String booksPath = 'books';
    final String bookFolderPath = '$booksPath/$bookId';
    final String historyFolderPath = '$booksPath/$bookId/history';

    setUp(() {
      mockCloudRepository = MockCloudRepository();
      cloudBookStorage = CloudBookStorage(
        cloudRepository: mockCloudRepository,
      );

      // Register fallbacks for argument matchers
      registerFallbackValue(CloudProviders.google);
      registerFallbackValue(const CloudFile(
        identifier: '',
        name: '',
        length: 0,
        modifiedTime: null,
      ));
    });

    tearDown(() async {
      await cloudBookStorage.dispose();
    });

    group('Book content operations', () {
      group('exists', () {
        test('returns true when book.epub exists in folder', () async {
          final mockMetadata = DriveFileMetadata(
            fileId: 'file-123',
            name: 'book.epub',
            modifiedTime: DateTime.now(),
            isFile: true,
            isFolder: false,
          );

          when(() => mockCloudRepository.listFolderContents(
                CloudProviders.google,
                bookFolderPath,
              )).thenAnswer((_) => Future.value([mockMetadata]));

          final result = await cloudBookStorage.exists(bookId);

          expect(result, true);
          verify(() => mockCloudRepository.listFolderContents(
                CloudProviders.google,
                bookFolderPath,
              )).called(1);
        });

        test('returns false when book.epub does not exist', () async {
          when(() => mockCloudRepository.listFolderContents(
                CloudProviders.google,
                bookFolderPath,
              )).thenAnswer((_) => Future.value([]));

          final result = await cloudBookStorage.exists(bookId);

          expect(result, false);
        });

        test('returns false when folder does not exist', () async {
          when(() => mockCloudRepository.listFolderContents(
                CloudProviders.google,
                bookFolderPath,
              )).thenThrow(Exception('Folder not found'));

          final result = await cloudBookStorage.exists(bookId);

          expect(result, false);
        });

        test('throws BookStorageException on cloud error', () async {
          when(() => mockCloudRepository.listFolderContents(
                CloudProviders.google,
                bookFolderPath,
              )).thenThrow(Exception('Cloud authentication failed'));

          expect(
            () => cloudBookStorage.exists(bookId),
            throwsA(isA<BookStorageException>()),
          );
        });
      });

      group('readBytes', () {
        test('reads book bytes successfully', () async {
          final testBytes = [1, 2, 3, 4, 5];
          final mockMetadata = DriveFileMetadata(
            fileId: 'file-123',
            name: 'book.epub',
            modifiedTime: DateTime.now(),
            isFile: true,
            isFolder: false,
          );

          when(() => mockCloudRepository.listFolderContents(
                CloudProviders.google,
                bookFolderPath,
              )).thenAnswer((_) => Future.value([mockMetadata]));
          when(() => mockCloudRepository.downloadFile(
                CloudProviders.google,
                any(),
              )).thenAnswer(
                (_) => Stream.fromIterable([testBytes]),
              );

          final result = await cloudBookStorage.readBytes(bookId);

          expect(result, testBytes);
        });

        test('throws BookNotFoundException when book does not exist', () async {
          when(() => mockCloudRepository.listFolderContents(
                CloudProviders.google,
                bookFolderPath,
              )).thenAnswer((_) => Future.value([]));

          expect(
            () => cloudBookStorage.readBytes(bookId),
            throwsA(isA<BookNotFoundException>()),
          );
        });

        test('throws BookStorageException on download error', () async {
          when(() => mockCloudRepository.listFolderContents(
                CloudProviders.google,
                bookFolderPath,
              )).thenThrow(Exception('Download failed'));

          expect(
            () => cloudBookStorage.readBytes(bookId),
            throwsA(isA<BookStorageException>()),
          );
        });
      });

      group('writeBytes', () {
        test('writes book bytes successfully', () async {
          when(() => mockCloudRepository.uploadFileToPath(
                CloudProviders.google,
                any(),
                bookFolderPath,
              )).thenAnswer((_) => Future.value(null));

          await cloudBookStorage.writeBytes(bookId, [1, 2, 3, 4, 5]);

          verify(() => mockCloudRepository.uploadFileToPath(
                CloudProviders.google,
                any(),
                bookFolderPath,
              )).called(1);
        });

        test('emits change notification after successful write', () async {
          when(() => mockCloudRepository.uploadFileToPath(
                CloudProviders.google,
                any(),
                bookFolderPath,
              )).thenAnswer((_) => Future.value(null));

          final changes = cloudBookStorage.changeStream();
          final bookIds = <BookId>[];

          final subscription =
              changes.listen((bookIdValue) => bookIds.add(bookIdValue));

          await cloudBookStorage.writeBytes(bookId, [1, 2, 3]);

          await Future.delayed(const Duration(milliseconds: 100));

          expect(bookIds, contains(bookId));

          await subscription.cancel();
        });

        test('throws BookStorageException on upload error', () async {
          when(() => mockCloudRepository.uploadFileToPath(
                CloudProviders.google,
                any(),
                bookFolderPath,
              )).thenThrow(Exception('Upload failed'));

          expect(
            () => cloudBookStorage.writeBytes(bookId, [1, 2, 3]),
            throwsA(isA<BookStorageException>()),
          );
        });
      });

      group('delete', () {
        test('deletes book folder successfully', () async {
          final mockMetadata = DriveFileMetadata(
            fileId: 'folder-123',
            name: 'metadata.json',
            modifiedTime: DateTime.now(),
            isFile: true,
            isFolder: false,
          );

          when(() => mockCloudRepository.listFolderContents(
                CloudProviders.google,
                bookFolderPath,
              )).thenAnswer((_) => Future.value([mockMetadata]));
          when(() => mockCloudRepository.deleteFolder(
                CloudProviders.google,
                bookFolderPath,
              )).thenAnswer((_) => Future.value(null));

          await cloudBookStorage.delete(bookId);

          verify(() => mockCloudRepository.deleteFolder(
                CloudProviders.google,
                bookFolderPath,
              )).called(1);
        });

        test('is idempotent when book folder does not exist', () async {
          when(() => mockCloudRepository.listFolderContents(
                CloudProviders.google,
                bookFolderPath,
              )).thenThrow(Exception('Folder not found'));

          // Should not throw
          await cloudBookStorage.delete(bookId);

          verifyNever(() => mockCloudRepository.deleteFolder(
                CloudProviders.google,
                any(),
              ));
        });

        test('emits change notification after successful delete', () async {
          final mockMetadata = DriveFileMetadata(
            fileId: 'folder-123',
            name: 'metadata.json',
            modifiedTime: DateTime.now(),
            isFile: true,
            isFolder: false,
          );

          when(() => mockCloudRepository.listFolderContents(
                CloudProviders.google,
                bookFolderPath,
              )).thenAnswer((_) => Future.value([mockMetadata]));
          when(() => mockCloudRepository.deleteFolder(
                CloudProviders.google,
                bookFolderPath,
              )).thenAnswer((_) => Future.value(null));

          final changes = cloudBookStorage.changeStream();
          final bookIds = <BookId>[];

          final subscription =
              changes.listen((bookIdValue) => bookIds.add(bookIdValue));

          await cloudBookStorage.delete(bookId);

          await Future.delayed(const Duration(milliseconds: 100));

          expect(bookIds, contains(bookId));

          await subscription.cancel();
        });

        test('throws BookStorageException on deletion error', () async {
          final mockMetadata = DriveFileMetadata(
            fileId: 'folder-123',
            name: 'metadata.json',
            modifiedTime: DateTime.now(),
            isFile: true,
            isFolder: false,
          );

          when(() => mockCloudRepository.listFolderContents(
                CloudProviders.google,
                bookFolderPath,
              )).thenAnswer((_) => Future.value([mockMetadata]));
          when(() => mockCloudRepository.deleteFolder(
                CloudProviders.google,
                bookFolderPath,
              )).thenThrow(Exception('Delete failed'));

          expect(
            () => cloudBookStorage.delete(bookId),
            throwsA(isA<BookStorageException>()),
          );
        });
      });
    });

    group('Metadata operations', () {
      group('readMetadata', () {
        test('reads metadata successfully', () async {
          final now = DateTime.now();
          final jsonString =
              '{"originalFilename":"test.epub","title":"Test Book","dateAdded":"${now.toIso8601String()}","readingState":{"cfiPosition":"/6/4[chap01]!/4/2/16","progress":50.0,"lastReadTime":"${now.toIso8601String()}","totalSeconds":3600},"bookmarks":[]}';

          final mockMetadata = DriveFileMetadata(
            fileId: 'file-123',
            name: 'metadata.json',
            modifiedTime: DateTime.now(),
            isFile: true,
            isFolder: false,
          );

          when(() => mockCloudRepository.listFolderContents(
                CloudProviders.google,
                bookFolderPath,
              )).thenAnswer((_) => Future.value([mockMetadata]));
          when(() => mockCloudRepository.downloadFile(
                CloudProviders.google,
                any(),
              )).thenAnswer(
                (_) => Stream.fromIterable([jsonString.codeUnits]),
              );

          final result = await cloudBookStorage.readMetadata(bookId);

          expect(result, isNotNull);
          expect(result?.title, 'Test Book');
        });

        test('returns null when metadata.json does not exist', () async {
          when(() => mockCloudRepository.listFolderContents(
                CloudProviders.google,
                bookFolderPath,
              )).thenAnswer((_) => Future.value([]));

          final result = await cloudBookStorage.readMetadata(bookId);

          expect(result, isNull);
        });

        test('returns null when folder does not exist', () async {
          when(() => mockCloudRepository.listFolderContents(
                CloudProviders.google,
                bookFolderPath,
              )).thenThrow(Exception('Folder not found'));

          final result = await cloudBookStorage.readMetadata(bookId);

          expect(result, isNull);
        });

        test('throws BookStorageException on download error', () async {
          final mockMetadata = DriveFileMetadata(
            fileId: 'file-123',
            name: 'metadata.json',
            modifiedTime: DateTime.now(),
            isFile: true,
            isFolder: false,
          );

          when(() => mockCloudRepository.listFolderContents(
                CloudProviders.google,
                bookFolderPath,
              )).thenAnswer((_) => Future.value([mockMetadata]));
          when(() => mockCloudRepository.downloadFile(
                CloudProviders.google,
                any(),
              )).thenThrow(Exception('Download failed'));

          expect(
            () => cloudBookStorage.readMetadata(bookId),
            throwsA(isA<BookStorageException>()),
          );
        });
      });

      group('writeMetadata', () {
        test('writes metadata successfully and creates history snapshot', () async {
          final now = DateTime.now();
          final metadata = BookMetadata(
            originalFilename: 'test.epub',
            title: 'Test Book',
            dateAdded: now,
            readingState: ReadingState(
              cfiPosition: '/6/4[chap01]!/4/2/16',
              progress: 50.0,
              lastReadTime: now,
              totalSeconds: 3600,
            ),
            bookmarks: [],
          );

          when(() => mockCloudRepository.uploadFileToPath(
                CloudProviders.google,
                any(),
                any(),
              )).thenAnswer((_) => Future.value(null));

          await cloudBookStorage.writeMetadata(bookId, metadata);

          // Should be called twice: once for metadata.json, once for history snapshot
          verify(() => mockCloudRepository.uploadFileToPath(
                CloudProviders.google,
                any(),
                any(),
              )).called(2);
        });

        test('emits change notification after successful write', () async {
          final now = DateTime.now();
          final metadata = BookMetadata(
            originalFilename: 'test.epub',
            title: 'Test Book',
            dateAdded: now,
            readingState: ReadingState(
              cfiPosition: '/6/4[chap01]!/4/2/16',
              progress: 50.0,
              lastReadTime: now,
              totalSeconds: 3600,
            ),
            bookmarks: [],
          );

          when(() => mockCloudRepository.uploadFileToPath(
                CloudProviders.google,
                any(),
                any(),
              )).thenAnswer((_) => Future.value(null));

          final changes = cloudBookStorage.changeStream();
          final bookIds = <BookId>[];

          final subscription =
              changes.listen((bookIdValue) => bookIds.add(bookIdValue));

          await cloudBookStorage.writeMetadata(bookId, metadata);

          await Future.delayed(const Duration(milliseconds: 100));

          expect(bookIds, contains(bookId));

          await subscription.cancel();
        });

        test('throws BookStorageException on upload error', () async {
          final metadata = BookMetadata(
            originalFilename: 'test.epub',
            title: 'Test Book',
            dateAdded: DateTime.now(),
            readingState: ReadingState(
              cfiPosition: '/6/4[chap01]!/4/2/16',
              progress: 50.0,
              lastReadTime: DateTime.now(),
              totalSeconds: 3600,
            ),
            bookmarks: [],
          );

          when(() => mockCloudRepository.uploadFileToPath(
                CloudProviders.google,
                any(),
                bookFolderPath,
              )).thenThrow(Exception('Upload failed'));

          expect(
            () => cloudBookStorage.writeMetadata(bookId, metadata),
            throwsA(isA<BookStorageException>()),
          );
        });
      });
    });

    group('Listing operations', () {
      group('listBookIds', () {
        test('lists all book IDs from books folder', () async {
          final mockBook1 = DriveFileMetadata(
            fileId: 'folder-1',
            name: 'book-1',
            modifiedTime: DateTime.now(),
            isFile: false,
            isFolder: true,
          );

          final mockBook2 = DriveFileMetadata(
            fileId: 'folder-2',
            name: 'book-2',
            modifiedTime: DateTime.now(),
            isFile: false,
            isFolder: true,
          );

          final mockBook3 = DriveFileMetadata(
            fileId: 'folder-3',
            name: 'book-3',
            modifiedTime: DateTime.now(),
            isFile: false,
            isFolder: true,
          );

          when(() => mockCloudRepository.listFolderContents(
                CloudProviders.google,
                booksPath,
              )).thenAnswer(
                  (_) => Future.value([mockBook1, mockBook2, mockBook3]));

          final result = await cloudBookStorage.listBookIds();

          expect(result, containsAll(['book-1', 'book-2', 'book-3']));
          expect(result.length, 3);
        });

        test('returns empty list when books folder is empty', () async {
          when(() => mockCloudRepository.listFolderContents(
                CloudProviders.google,
                booksPath,
              )).thenAnswer((_) => Future.value([]));

          final result = await cloudBookStorage.listBookIds();

          expect(result, isEmpty);
        });

        test('filters out files from folder listing', () async {
          final mockBook1 = DriveFileMetadata(
            fileId: 'folder-1',
            name: 'book-1',
            modifiedTime: DateTime.now(),
            isFile: false,
            isFolder: true,
          );

          final mockFile = DriveFileMetadata(
            fileId: 'file-1',
            name: 'README.txt',
            modifiedTime: DateTime.now(),
            isFile: true,
            isFolder: false,
          );

          when(() => mockCloudRepository.listFolderContents(
                CloudProviders.google,
                booksPath,
              )).thenAnswer((_) => Future.value([mockBook1, mockFile]));

          final result = await cloudBookStorage.listBookIds();

          expect(result, ['book-1']);
          expect(result, isNot(contains('README.txt')));
        });

        test('throws BookStorageException on listing error', () async {
          when(() => mockCloudRepository.listFolderContents(
                CloudProviders.google,
                booksPath,
              )).thenThrow(Exception('Listing error'));

          expect(
            () => cloudBookStorage.listBookIds(),
            throwsA(isA<BookStorageException>()),
          );
        });
      });
    });

    group('Change stream notifications', () {
      test('emits bookId on content write', () async {
        when(() => mockCloudRepository.uploadFileToPath(
              CloudProviders.google,
              any(),
              bookFolderPath,
            )).thenAnswer((_) => Future.value(null));

        final changes = cloudBookStorage.changeStream();
        final bookIds = <BookId>[];

        final subscription =
            changes.listen((bookIdValue) => bookIds.add(bookIdValue));

        await cloudBookStorage.writeBytes(bookId, [1, 2, 3]);

        await Future.delayed(const Duration(milliseconds: 100));

        expect(bookIds, contains(bookId));

        await subscription.cancel();
      });

      test('emits bookId on metadata write', () async {
        final metadata = BookMetadata(
          originalFilename: 'test.epub',
          title: 'Test',
          dateAdded: DateTime.now(),
          readingState: ReadingState(
            cfiPosition: '/6/4[chap01]!/4/2/16',
            progress: 50.0,
            lastReadTime: DateTime.now(),
            totalSeconds: 3600,
          ),
          bookmarks: [],
        );

        when(() => mockCloudRepository.uploadFileToPath(
              CloudProviders.google,
              any(),
              any(),
            )).thenAnswer((_) => Future.value(null));

        final changes = cloudBookStorage.changeStream();
        final bookIds = <BookId>[];

        final subscription =
            changes.listen((bookIdValue) => bookIds.add(bookIdValue));

        await cloudBookStorage.writeMetadata(bookId, metadata);

        await Future.delayed(const Duration(milliseconds: 100));

        expect(bookIds, contains(bookId));

        await subscription.cancel();
      });

      test('emits bookId on delete', () async {
        final mockMetadata = DriveFileMetadata(
          fileId: 'folder-123',
          name: 'metadata.json',
          modifiedTime: DateTime.now(),
          isFile: true,
          isFolder: false,
        );

        when(() => mockCloudRepository.listFolderContents(
              CloudProviders.google,
              bookFolderPath,
            )).thenAnswer((_) => Future.value([mockMetadata]));
        when(() => mockCloudRepository.deleteFolder(
              CloudProviders.google,
              bookFolderPath,
            )).thenAnswer((_) => Future.value(null));

        final changes = cloudBookStorage.changeStream();
        final bookIds = <BookId>[];

        final subscription =
            changes.listen((bookIdValue) => bookIds.add(bookIdValue));

        await cloudBookStorage.delete(bookId);

        await Future.delayed(const Duration(milliseconds: 100));

        expect(bookIds, contains(bookId));

        await subscription.cancel();
      });

      test('stream can have multiple listeners', () async {
        when(() => mockCloudRepository.uploadFileToPath(
              CloudProviders.google,
              any(),
              bookFolderPath,
            )).thenAnswer((_) => Future.value(null));

        final changes = cloudBookStorage.changeStream();
        final bookIds1 = <BookId>[];
        final bookIds2 = <BookId>[];

        final subscription1 =
            changes.listen((bookIdValue) => bookIds1.add(bookIdValue));
        final subscription2 =
            changes.listen((bookIdValue) => bookIds2.add(bookIdValue));

        await cloudBookStorage.writeBytes(bookId, [1, 2, 3]);

        await Future.delayed(const Duration(milliseconds: 100));

        expect(bookIds1, contains(bookId));
        expect(bookIds2, contains(bookId));

        await subscription1.cancel();
        await subscription2.cancel();
      });
    });

    group('Edge cases', () {
      test('handles empty bookId', () async {
        when(() => mockCloudRepository.listFolderContents(
              CloudProviders.google,
              '$booksPath/',
            )).thenAnswer((_) => Future.value([]));

        final result = await cloudBookStorage.exists('');

        expect(result, false);
      });

      test('handles special characters in bookId', () async {
        const specialBookId = 'book-id-123';

        when(() => mockCloudRepository.listFolderContents(
              CloudProviders.google,
              '$booksPath/$specialBookId',
            )).thenAnswer((_) => Future.value([]));

        final result = await cloudBookStorage.exists(specialBookId);

        expect(result, false);
      });

      test('handles concurrent metadata writes', () async {
        final metadata1 = BookMetadata(
          originalFilename: 'test1.epub',
          title: 'Test 1',
          dateAdded: DateTime.now(),
          readingState: ReadingState(
            cfiPosition: '/6/4[chap01]!/4/2/16',
            progress: 50.0,
            lastReadTime: DateTime.now(),
            totalSeconds: 3600,
          ),
          bookmarks: [],
        );

        final metadata2 = BookMetadata(
          originalFilename: 'test2.epub',
          title: 'Test 2',
          dateAdded: DateTime.now(),
          readingState: ReadingState(
            cfiPosition: '/6/4[chap02]!/4/2/16',
            progress: 60.0,
            lastReadTime: DateTime.now(),
            totalSeconds: 5400,
          ),
          bookmarks: [],
        );

        when(() => mockCloudRepository.uploadFileToPath(
              CloudProviders.google,
              any(),
              any(),
            )).thenAnswer((_) => Future.value(null));

        await Future.wait([
          cloudBookStorage.writeMetadata(bookId, metadata1),
          cloudBookStorage.writeMetadata(bookId, metadata2),
        ]);

        verify(() => mockCloudRepository.uploadFileToPath(
              CloudProviders.google,
              any(),
              any(),
            )).called(4); // 2 writes × 2 calls each (metadata + history)
      });
    });
  });
}
