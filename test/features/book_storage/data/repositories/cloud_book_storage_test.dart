import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:novel_glide/features/book_storage/data/repositories/cloud_book_storage.dart';
import 'package:novel_glide/features/book_storage/domain/entities/book_metadata.dart';
import 'package:novel_glide/features/book_storage/domain/entities/bookmark_entry.dart';
import 'package:novel_glide/features/book_storage/domain/entities/reading_state.dart';
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
    const String bookFolderPath = '$booksPath/$bookId';

    setUp(() {
      mockCloudRepository = MockCloudRepository();
      cloudBookStorage = CloudBookStorage(
        cloudRepository: mockCloudRepository,
      );

      // Register fallbacks for argument matchers
      registerFallbackValue(CloudProviders.google);
      registerFallbackValue(CloudFile(
        identifier: '',
        name: '',
        length: 0,
        modifiedTime: DateTime.now(),
      ));
    });

    tearDown(() async {
      await cloudBookStorage.dispose();
    });

    group('Book content operations', () {
      group('exists', () {
        test('returns true when book.epub exists in folder', () async {
          final DriveFileMetadata mockMetadata = DriveFileMetadata(
            fileId: 'file-123',
            name: 'book.epub',
            mimeType: 'application/epub+zip',
            modifiedTime: DateTime.now(),
          );

          when(() => mockCloudRepository.listFolderContents(
                    CloudProviders.google,
                    bookFolderPath,
                  ))
              .thenAnswer(
                  (_) => Future.value(<DriveFileMetadata>[mockMetadata]));

          final bool result = await cloudBookStorage.exists(bookId);

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
              )).thenAnswer((_) => Future.value(<DriveFileMetadata>[]));

          final bool result = await cloudBookStorage.exists(bookId);

          expect(result, false);
        });

        test('returns false when folder does not exist', () async {
          when(() => mockCloudRepository.listFolderContents(
                CloudProviders.google,
                bookFolderPath,
              )).thenThrow(Exception('Folder not found'));

          final bool result = await cloudBookStorage.exists(bookId);

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
          final Uint8List testBytes = Uint8List.fromList(<int>[1, 2, 3, 4, 5]);
          final DriveFileMetadata mockMetadata = DriveFileMetadata(
            fileId: 'file-123',
            name: 'book.epub',
            mimeType: 'application/epub+zip',
            modifiedTime: DateTime.now(),
          );

          when(() => mockCloudRepository.listFolderContents(
                    CloudProviders.google,
                    bookFolderPath,
                  ))
              .thenAnswer(
                  (_) => Future.value(<DriveFileMetadata>[mockMetadata]));
          when(() => mockCloudRepository.downloadFile(
                CloudProviders.google,
                any(),
              )).thenAnswer(
            (_) => Stream.fromIterable(<Uint8List>[testBytes]),
          );

          final List<int> result = await cloudBookStorage.readBytes(bookId);

          expect(result, testBytes);
        });

        test('throws BookNotFoundException when book does not exist', () async {
          when(() => mockCloudRepository.listFolderContents(
                CloudProviders.google,
                bookFolderPath,
              )).thenAnswer((_) => Future.value(<DriveFileMetadata>[]));

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
              )).thenAnswer((_) async => '');

          await cloudBookStorage.writeBytes(bookId, <int>[1, 2, 3, 4, 5]);

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
              )).thenAnswer((_) async => '');

          final Stream<BookId> changes = cloudBookStorage.changeStream();
          final List<BookId> bookIds = <BookId>[];

          final StreamSubscription<BookId> subscription =
              changes.listen((BookId bookIdValue) => bookIds.add(bookIdValue));

          await cloudBookStorage.writeBytes(bookId, <int>[1, 2, 3]);

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
            () => cloudBookStorage.writeBytes(bookId, <int>[1, 2, 3]),
            throwsA(isA<BookStorageException>()),
          );
        });
      });

      group('delete', () {
        test('deletes book folder successfully', () async {
          final DriveFileMetadata mockMetadata = DriveFileMetadata(
            fileId: 'folder-123',
            name: 'metadata.json',
            mimeType: 'application/json',
            modifiedTime: DateTime.now(),
          );

          when(() => mockCloudRepository.listFolderContents(
                    CloudProviders.google,
                    bookFolderPath,
                  ))
              .thenAnswer(
                  (_) => Future.value(<DriveFileMetadata>[mockMetadata]));
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
          final DriveFileMetadata mockMetadata = DriveFileMetadata(
            fileId: 'folder-123',
            name: 'metadata.json',
            mimeType: 'application/json',
            modifiedTime: DateTime.now(),
          );

          when(() => mockCloudRepository.listFolderContents(
                    CloudProviders.google,
                    bookFolderPath,
                  ))
              .thenAnswer(
                  (_) => Future.value(<DriveFileMetadata>[mockMetadata]));
          when(() => mockCloudRepository.deleteFolder(
                CloudProviders.google,
                bookFolderPath,
              )).thenAnswer((_) => Future.value(null));

          final Stream<BookId> changes = cloudBookStorage.changeStream();
          final List<BookId> bookIds = <BookId>[];

          final StreamSubscription<BookId> subscription =
              changes.listen((BookId bookIdValue) => bookIds.add(bookIdValue));

          await cloudBookStorage.delete(bookId);

          await Future.delayed(const Duration(milliseconds: 100));

          expect(bookIds, contains(bookId));

          await subscription.cancel();
        });

        test('throws BookStorageException on deletion error', () async {
          final DriveFileMetadata mockMetadata = DriveFileMetadata(
            fileId: 'folder-123',
            name: 'metadata.json',
            mimeType: 'application/json',
            modifiedTime: DateTime.now(),
          );

          when(() => mockCloudRepository.listFolderContents(
                    CloudProviders.google,
                    bookFolderPath,
                  ))
              .thenAnswer(
                  (_) => Future.value(<DriveFileMetadata>[mockMetadata]));
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
          final DateTime now = DateTime.now();
          final String jsonString =
              '{"originalFilename":"test.epub","title":"Test Book","dateAdded":"${now.toIso8601String()}","readingState":{"cfiPosition":"/6/4[chap01]!/4/2/16","progress":50.0,"lastReadTime":"${now.toIso8601String()}","totalSeconds":3600},"bookmarks":[]}';

          final DriveFileMetadata mockMetadata = DriveFileMetadata(
            fileId: 'file-123',
            name: 'metadata.json',
            mimeType: 'application/json',
            modifiedTime: DateTime.now(),
          );

          when(() => mockCloudRepository.listFolderContents(
                    CloudProviders.google,
                    bookFolderPath,
                  ))
              .thenAnswer(
                  (_) => Future.value(<DriveFileMetadata>[mockMetadata]));
          when(() => mockCloudRepository.downloadFile(
                CloudProviders.google,
                any(),
              )).thenAnswer(
            (_) => Stream.fromIterable(
                <Uint8List>[Uint8List.fromList(jsonString.codeUnits)]),
          );

          final BookMetadata? result =
              await cloudBookStorage.readMetadata(bookId);

          expect(result, isNotNull);
          expect(result?.title, 'Test Book');
        });

        test('returns null when metadata.json does not exist', () async {
          when(() => mockCloudRepository.listFolderContents(
                CloudProviders.google,
                bookFolderPath,
              )).thenAnswer((_) => Future.value(<DriveFileMetadata>[]));

          final BookMetadata? result =
              await cloudBookStorage.readMetadata(bookId);

          expect(result, isNull);
        });

        test('returns null when folder does not exist', () async {
          when(() => mockCloudRepository.listFolderContents(
                CloudProviders.google,
                bookFolderPath,
              )).thenThrow(Exception('Folder not found'));

          final BookMetadata? result =
              await cloudBookStorage.readMetadata(bookId);

          expect(result, isNull);
        });

        test('throws BookStorageException on download error', () async {
          final DriveFileMetadata mockMetadata = DriveFileMetadata(
            fileId: 'file-123',
            name: 'metadata.json',
            mimeType: 'application/json',
            modifiedTime: DateTime.now(),
          );

          when(() => mockCloudRepository.listFolderContents(
                    CloudProviders.google,
                    bookFolderPath,
                  ))
              .thenAnswer(
                  (_) => Future.value(<DriveFileMetadata>[mockMetadata]));
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
        test('writes metadata successfully and creates history snapshot',
            () async {
          final DateTime now = DateTime.now();
          final BookMetadata metadata = BookMetadata(
            originalFilename: 'test.epub',
            title: 'Test Book',
            dateAdded: now,
            readingState: ReadingState(
              cfiPosition: '/6/4[chap01]!/4/2/16',
              progress: 50.0,
              lastReadTime: now,
              totalSeconds: 3600,
            ),
            bookmarks: <BookmarkEntry>[],
          );

          when(() => mockCloudRepository.uploadFileToPath(
                CloudProviders.google,
                any(),
                any(),
              )).thenAnswer((_) async => '');

          await cloudBookStorage.writeMetadata(bookId, metadata);

          // Should be called twice: once for metadata.json, once for history snapshot
          verify(() => mockCloudRepository.uploadFileToPath(
                CloudProviders.google,
                any(),
                any(),
              )).called(2);
        });

        test('emits change notification after successful write', () async {
          final DateTime now = DateTime.now();
          final BookMetadata metadata = BookMetadata(
            originalFilename: 'test.epub',
            title: 'Test Book',
            dateAdded: now,
            readingState: ReadingState(
              cfiPosition: '/6/4[chap01]!/4/2/16',
              progress: 50.0,
              lastReadTime: now,
              totalSeconds: 3600,
            ),
            bookmarks: <BookmarkEntry>[],
          );

          when(() => mockCloudRepository.uploadFileToPath(
                CloudProviders.google,
                any(),
                any(),
              )).thenAnswer((_) async => '');

          final Stream<BookId> changes = cloudBookStorage.changeStream();
          final List<BookId> bookIds = <BookId>[];

          final StreamSubscription<BookId> subscription =
              changes.listen((BookId bookIdValue) => bookIds.add(bookIdValue));

          await cloudBookStorage.writeMetadata(bookId, metadata);

          await Future.delayed(const Duration(milliseconds: 100));

          expect(bookIds, contains(bookId));

          await subscription.cancel();
        });

        test('throws BookStorageException on upload error', () async {
          final BookMetadata metadata = BookMetadata(
            originalFilename: 'test.epub',
            title: 'Test Book',
            dateAdded: DateTime.now(),
            readingState: ReadingState(
              cfiPosition: '/6/4[chap01]!/4/2/16',
              progress: 50.0,
              lastReadTime: DateTime.now(),
              totalSeconds: 3600,
            ),
            bookmarks: <BookmarkEntry>[],
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
          final DriveFileMetadata mockBook1 = DriveFileMetadata(
            fileId: 'folder-1',
            name: 'book-1',
            mimeType: 'application/vnd.google-apps.folder',
            modifiedTime: DateTime.now(),
          );

          final DriveFileMetadata mockBook2 = DriveFileMetadata(
            fileId: 'folder-2',
            name: 'book-2',
            mimeType: 'application/vnd.google-apps.folder',
            modifiedTime: DateTime.now(),
          );

          final DriveFileMetadata mockBook3 = DriveFileMetadata(
            fileId: 'folder-3',
            name: 'book-3',
            mimeType: 'application/vnd.google-apps.folder',
            modifiedTime: DateTime.now(),
          );

          when(() => mockCloudRepository.listFolderContents(
                    CloudProviders.google,
                    booksPath,
                  ))
              .thenAnswer((_) => Future.value(
                  <DriveFileMetadata>[mockBook1, mockBook2, mockBook3]));

          final List<BookId> result = await cloudBookStorage.listBookIds();

          expect(result, containsAll(<dynamic>['book-1', 'book-2', 'book-3']));
          expect(result.length, 3);
        });

        test('returns empty list when books folder is empty', () async {
          when(() => mockCloudRepository.listFolderContents(
                CloudProviders.google,
                booksPath,
              )).thenAnswer((_) => Future.value(<DriveFileMetadata>[]));

          final List<BookId> result = await cloudBookStorage.listBookIds();

          expect(result, isEmpty);
        });

        test('filters out files from folder listing', () async {
          final DriveFileMetadata mockBook1 = DriveFileMetadata(
            fileId: 'folder-1',
            name: 'book-1',
            mimeType: 'application/vnd.google-apps.folder',
            modifiedTime: DateTime.now(),
          );

          final DriveFileMetadata mockFile = DriveFileMetadata(
            fileId: 'file-1',
            name: 'README.txt',
            mimeType: 'text/plain',
            modifiedTime: DateTime.now(),
          );

          when(() => mockCloudRepository.listFolderContents(
                    CloudProviders.google,
                    booksPath,
                  ))
              .thenAnswer((_) =>
                  Future.value(<DriveFileMetadata>[mockBook1, mockFile]));

          final List<BookId> result = await cloudBookStorage.listBookIds();

          expect(result, <String>['book-1']);
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
            )).thenAnswer((_) async => '');

        final Stream<BookId> changes = cloudBookStorage.changeStream();
        final List<BookId> bookIds = <BookId>[];

        final StreamSubscription<BookId> subscription =
            changes.listen((BookId bookIdValue) => bookIds.add(bookIdValue));

        await cloudBookStorage.writeBytes(bookId, <int>[1, 2, 3]);

        await Future.delayed(const Duration(milliseconds: 100));

        expect(bookIds, contains(bookId));

        await subscription.cancel();
      });

      test('emits bookId on metadata write', () async {
        final BookMetadata metadata = BookMetadata(
          originalFilename: 'test.epub',
          title: 'Test',
          dateAdded: DateTime.now(),
          readingState: ReadingState(
            cfiPosition: '/6/4[chap01]!/4/2/16',
            progress: 50.0,
            lastReadTime: DateTime.now(),
            totalSeconds: 3600,
          ),
          bookmarks: <BookmarkEntry>[],
        );

        when(() => mockCloudRepository.uploadFileToPath(
              CloudProviders.google,
              any(),
              any(),
            )).thenAnswer((_) async => '');

        final Stream<BookId> changes = cloudBookStorage.changeStream();
        final List<BookId> bookIds = <BookId>[];

        final StreamSubscription<BookId> subscription =
            changes.listen((BookId bookIdValue) => bookIds.add(bookIdValue));

        await cloudBookStorage.writeMetadata(bookId, metadata);

        await Future<void>.delayed(const Duration(milliseconds: 100));

        expect(bookIds, contains(bookId));

        await subscription.cancel();
      });

      test('emits bookId on delete', () async {
        final DriveFileMetadata mockMetadata = DriveFileMetadata(
          fileId: 'folder-123',
          name: 'metadata.json',
          mimeType: 'application/json',
          modifiedTime: DateTime.now(),
        );

        when(() => mockCloudRepository.listFolderContents(
              CloudProviders.google,
              bookFolderPath,
            )).thenAnswer((_) async => <DriveFileMetadata>[mockMetadata]);
        when(() => mockCloudRepository.deleteFolder(
              CloudProviders.google,
              bookFolderPath,
            )).thenAnswer((_) async => '');

        final Stream<BookId> changes = cloudBookStorage.changeStream();
        final List<BookId> bookIds = <BookId>[];

        final StreamSubscription<BookId> subscription =
            changes.listen((BookId bookIdValue) => bookIds.add(bookIdValue));

        await cloudBookStorage.delete(bookId);

        await Future<void>.delayed(const Duration(milliseconds: 100));

        expect(bookIds, contains(bookId));

        await subscription.cancel();
      });

      test('stream can have multiple listeners', () async {
        when(() => mockCloudRepository.uploadFileToPath(
              CloudProviders.google,
              any(),
              bookFolderPath,
            )).thenAnswer((_) async => '');

        final Stream<BookId> changes = cloudBookStorage.changeStream();
        final List<BookId> bookIds1 = <BookId>[];
        final List<BookId> bookIds2 = <BookId>[];

        final StreamSubscription<BookId> subscription1 =
            changes.listen((BookId bookIdValue) => bookIds1.add(bookIdValue));
        final StreamSubscription<BookId> subscription2 =
            changes.listen((BookId bookIdValue) => bookIds2.add(bookIdValue));

        await cloudBookStorage.writeBytes(bookId, <int>[1, 2, 3]);

        await Future<void>.delayed(const Duration(milliseconds: 100));

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
            )).thenAnswer((_) => Future.value(<DriveFileMetadata>[]));

        final bool result = await cloudBookStorage.exists('');

        expect(result, false);
      });

      test('handles special characters in bookId', () async {
        const String specialBookId = 'book-id-123';

        when(() => mockCloudRepository.listFolderContents(
              CloudProviders.google,
              '$booksPath/$specialBookId',
            )).thenAnswer((_) => Future.value(<DriveFileMetadata>[]));

        final bool result = await cloudBookStorage.exists(specialBookId);

        expect(result, false);
      });

      test('handles concurrent metadata writes', () async {
        final BookMetadata metadata1 = BookMetadata(
          originalFilename: 'test1.epub',
          title: 'Test 1',
          dateAdded: DateTime.now(),
          readingState: ReadingState(
            cfiPosition: '/6/4[chap01]!/4/2/16',
            progress: 50.0,
            lastReadTime: DateTime.now(),
            totalSeconds: 3600,
          ),
          bookmarks: <BookmarkEntry>[],
        );

        final BookMetadata metadata2 = BookMetadata(
          originalFilename: 'test2.epub',
          title: 'Test 2',
          dateAdded: DateTime.now(),
          readingState: ReadingState(
            cfiPosition: '/6/4[chap02]!/4/2/16',
            progress: 60.0,
            lastReadTime: DateTime.now(),
            totalSeconds: 5400,
          ),
          bookmarks: <BookmarkEntry>[],
        );

        when(() => mockCloudRepository.uploadFileToPath(
              CloudProviders.google,
              any(),
              any(),
            )).thenAnswer((_) async => '');

        await Future.wait(<Future<void>>[
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
