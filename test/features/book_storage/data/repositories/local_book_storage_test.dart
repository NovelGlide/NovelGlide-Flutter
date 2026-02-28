import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:novel_glide/core/file_system/domain/repositories/file_system_repository.dart';
import 'package:novel_glide/core/file_system/domain/repositories/json_repository.dart';
import 'package:novel_glide/core/path_provider/domain/repositories/app_path_provider.dart';
import 'package:novel_glide/features/book_storage/data/repositories/local_book_storage.dart';
import 'package:novel_glide/features/book_storage/domain/entities/book_metadata.dart';
import 'package:novel_glide/features/book_storage/domain/entities/reading_state.dart';
import 'package:novel_glide/features/book_storage/domain/entities/bookmark_entry.dart';
import 'package:novel_glide/features/book_storage/domain/repositories/book_storage.dart';

class MockAppPathProvider extends Mock implements AppPathProvider {}

class MockFileSystemRepository extends Mock implements FileSystemRepository {}

class MockJsonRepository extends Mock implements JsonRepository {}

void main() {
  group('LocalBookStorage', () {
    late MockAppPathProvider mockAppPathProvider;
    late MockFileSystemRepository mockFileSystemRepository;
    late MockJsonRepository mockJsonRepository;
    late LocalBookStorage localBookStorage;

    const String libraryPath = '/test/library';
    const String bookId = 'test-book-id-123';

    setUp(() {
      mockAppPathProvider = MockAppPathProvider();
      mockFileSystemRepository = MockFileSystemRepository();
      mockJsonRepository = MockJsonRepository();

      when(() => mockAppPathProvider.libraryPath)
          .thenAnswer((_) => Future.value(libraryPath));

      localBookStorage = LocalBookStorage(
        appPathProvider: mockAppPathProvider,
        fileSystemRepository: mockFileSystemRepository,
        jsonRepository: mockJsonRepository,
      );
    });

    tearDown(() async {
      await localBookStorage.dispose();
    });

    group('Book content operations', () {
      group('exists', () {
        test('returns true when book folder exists', () async {
          when(() =>
                  mockFileSystemRepository.existsDirectory('$libraryPath/$bookId'))
              .thenAnswer((_) => Future.value(true));

          final result = await localBookStorage.exists(bookId);

          expect(result, true);
          verify(() =>
                  mockFileSystemRepository.existsDirectory('$libraryPath/$bookId'))
              .called(1);
        });

        test('returns false when book folder does not exist', () async {
          when(() =>
                  mockFileSystemRepository.existsDirectory('$libraryPath/$bookId'))
              .thenAnswer((_) => Future.value(false));

          final result = await localBookStorage.exists(bookId);

          expect(result, false);
        });

        test('throws BookStorageException on filesystem error', () async {
          when(() =>
                  mockFileSystemRepository.existsDirectory('$libraryPath/$bookId'))
              .thenThrow(Exception('Filesystem error'));

          expect(
            () => localBookStorage.exists(bookId),
            throwsA(isA<BookStorageException>()),
          );
        });
      });

      group('readBytes', () {
        test('reads book bytes successfully', () async {
          final testBytes = Uint8List.fromList([1, 2, 3, 4, 5]);

          when(() =>
                  mockFileSystemRepository.existsDirectory('$libraryPath/$bookId'))
              .thenAnswer((_) => Future.value(true));
          when(() => mockFileSystemRepository
                  .readFileAsBytes('$libraryPath/$bookId/book.epub'))
              .thenAnswer((_) => Future.value(testBytes));

          final result = await localBookStorage.readBytes(bookId);

          expect(result, testBytes);
          verify(() =>
                  mockFileSystemRepository.existsDirectory('$libraryPath/$bookId'))
              .called(1);
          verify(() => mockFileSystemRepository
                  .readFileAsBytes('$libraryPath/$bookId/book.epub'))
              .called(1);
        });

        test('throws BookNotFoundException when book does not exist', () async {
          when(() =>
                  mockFileSystemRepository.existsDirectory('$libraryPath/$bookId'))
              .thenAnswer((_) => Future.value(false));

          expect(
            () => localBookStorage.readBytes(bookId),
            throwsA(isA<BookNotFoundException>()),
          );
        });

        test('throws BookStorageException on filesystem error', () async {
          when(() =>
                  mockFileSystemRepository.existsDirectory('$libraryPath/$bookId'))
              .thenAnswer((_) => Future.value(true));
          when(() => mockFileSystemRepository
                  .readFileAsBytes('$libraryPath/$bookId/book.epub'))
              .thenThrow(Exception('Read error'));

          expect(
            () => localBookStorage.readBytes(bookId),
            throwsA(isA<BookStorageException>()),
          );
        });
      });

      group('writeBytes', () {
        test('writes book bytes and creates directory if needed', () async {
          final testBytes = [10, 20, 30, 40, 50];

          when(() =>
                  mockFileSystemRepository.createDirectory('$libraryPath/$bookId'))
              .thenAnswer((_) => Future.value(null));
          when(() => mockFileSystemRepository.writeFileAsBytes(
                  '$libraryPath/$bookId/book.epub', any()))
              .thenAnswer((_) => Future.value(null));

          await localBookStorage.writeBytes(bookId, testBytes);

          verify(() =>
                  mockFileSystemRepository.createDirectory('$libraryPath/$bookId'))
              .called(1);
          verify(() => mockFileSystemRepository.writeFileAsBytes(
                  '$libraryPath/$bookId/book.epub', any()))
              .called(1);
        });

        test('emits change notification after successful write', () async {
          final testBytes = [1, 2, 3];

          when(() =>
                  mockFileSystemRepository.createDirectory('$libraryPath/$bookId'))
              .thenAnswer((_) => Future.value(null));
          when(() => mockFileSystemRepository.writeFileAsBytes(
                  '$libraryPath/$bookId/book.epub', any()))
              .thenAnswer((_) => Future.value(null));

          final changes = localBookStorage.changeStream();
          final bookIdNotification = <BookId>[];

          final subscription =
              changes.listen((bookIdValue) => bookIdNotification.add(bookIdValue));

          await localBookStorage.writeBytes(bookId, testBytes);

          await Future.delayed(const Duration(milliseconds: 100));

          expect(bookIdNotification, contains(bookId));

          await subscription.cancel();
        });

        test('throws BookStorageException on write failure', () async {
          when(() =>
                  mockFileSystemRepository.createDirectory('$libraryPath/$bookId'))
              .thenThrow(Exception('Directory creation failed'));

          expect(
            () => localBookStorage.writeBytes(bookId, [1, 2, 3]),
            throwsA(isA<BookStorageException>()),
          );
        });
      });

      group('delete', () {
        test('deletes book folder when it exists', () async {
          when(() =>
                  mockFileSystemRepository.existsDirectory('$libraryPath/$bookId'))
              .thenAnswer((_) => Future.value(true));
          when(() =>
                  mockFileSystemRepository.deleteDirectory('$libraryPath/$bookId'))
              .thenAnswer((_) => Future.value(null));

          await localBookStorage.delete(bookId);

          verify(() =>
                  mockFileSystemRepository.existsDirectory('$libraryPath/$bookId'))
              .called(1);
          verify(() =>
                  mockFileSystemRepository.deleteDirectory('$libraryPath/$bookId'))
              .called(1);
        });

        test('is idempotent when book does not exist', () async {
          when(() =>
                  mockFileSystemRepository.existsDirectory('$libraryPath/$bookId'))
              .thenAnswer((_) => Future.value(false));

          // Should not throw
          await localBookStorage.delete(bookId);

          verify(() =>
                  mockFileSystemRepository.existsDirectory('$libraryPath/$bookId'))
              .called(1);
          verifyNever(() => mockFileSystemRepository.deleteDirectory(any()));
        });

        test('emits change notification after successful delete', () async {
          when(() =>
                  mockFileSystemRepository.existsDirectory('$libraryPath/$bookId'))
              .thenAnswer((_) => Future.value(true));
          when(() =>
                  mockFileSystemRepository.deleteDirectory('$libraryPath/$bookId'))
              .thenAnswer((_) => Future.value(null));

          final changes = localBookStorage.changeStream();
          final bookIdNotifications = <BookId>[];

          final subscription = changes
              .listen((bookIdValue) => bookIdNotifications.add(bookIdValue));

          await localBookStorage.delete(bookId);

          await Future.delayed(const Duration(milliseconds: 100));

          expect(bookIdNotifications, contains(bookId));

          await subscription.cancel();
        });

        test('throws BookStorageException on delete failure', () async {
          when(() =>
                  mockFileSystemRepository.existsDirectory('$libraryPath/$bookId'))
              .thenAnswer((_) => Future.value(true));
          when(() =>
                  mockFileSystemRepository.deleteDirectory('$libraryPath/$bookId'))
              .thenThrow(Exception('Delete failed'));

          expect(
            () => localBookStorage.delete(bookId),
            throwsA(isA<BookStorageException>()),
          );
        });
      });
    });

    group('Metadata operations', () {
      group('readMetadata', () {
        test('reads metadata successfully', () async {
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

          final jsonData = metadata.toJson();

          when(() =>
                  mockFileSystemRepository.existsFile('$libraryPath/$bookId/metadata.json'))
              .thenAnswer((_) => Future.value(true));
          when(() =>
                  mockJsonRepository.readJson(path: '$libraryPath/$bookId/metadata.json'))
              .thenAnswer((_) => Future.value(jsonData));

          final result = await localBookStorage.readMetadata(bookId);

          expect(result?.title, 'Test Book');
          verify(() =>
                  mockFileSystemRepository.existsFile('$libraryPath/$bookId/metadata.json'))
              .called(1);
        });

        test('returns null when metadata file does not exist', () async {
          when(() =>
                  mockFileSystemRepository.existsFile('$libraryPath/$bookId/metadata.json'))
              .thenAnswer((_) => Future.value(false));

          final result = await localBookStorage.readMetadata(bookId);

          expect(result, isNull);
        });

        test('throws BookStorageException on read failure', () async {
          when(() =>
                  mockFileSystemRepository.existsFile('$libraryPath/$bookId/metadata.json'))
              .thenAnswer((_) => Future.value(true));
          when(() =>
                  mockJsonRepository.readJson(path: '$libraryPath/$bookId/metadata.json'))
              .thenThrow(Exception('JSON read error'));

          expect(
            () => localBookStorage.readMetadata(bookId),
            throwsA(isA<BookStorageException>()),
          );
        });
      });

      group('writeMetadata', () {
        test('writes metadata successfully', () async {
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

          when(() =>
                  mockFileSystemRepository.createDirectory('$libraryPath/$bookId'))
              .thenAnswer((_) => Future.value(null));
          when(() => mockJsonRepository.writeJson(
                  path: '$libraryPath/$bookId/metadata.json', data: any()))
              .thenAnswer((_) => Future.value(null));

          await localBookStorage.writeMetadata(bookId, metadata);

          verify(() =>
                  mockFileSystemRepository.createDirectory('$libraryPath/$bookId'))
              .called(1);
          verify(() => mockJsonRepository.writeJson(
                  path: '$libraryPath/$bookId/metadata.json', data: any()))
              .called(1);
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

          when(() =>
                  mockFileSystemRepository.createDirectory('$libraryPath/$bookId'))
              .thenAnswer((_) => Future.value(null));
          when(() => mockJsonRepository.writeJson(
                  path: '$libraryPath/$bookId/metadata.json', data: any()))
              .thenAnswer((_) => Future.value(null));

          final changes = localBookStorage.changeStream();
          final bookIdNotifications = <BookId>[];

          final subscription = changes
              .listen((bookIdValue) => bookIdNotifications.add(bookIdValue));

          await localBookStorage.writeMetadata(bookId, metadata);

          await Future.delayed(const Duration(milliseconds: 100));

          expect(bookIdNotifications, contains(bookId));

          await subscription.cancel();
        });

        test('throws BookStorageException on write failure', () async {
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

          when(() =>
                  mockFileSystemRepository.createDirectory('$libraryPath/$bookId'))
              .thenThrow(Exception('Directory creation failed'));

          expect(
            () => localBookStorage.writeMetadata(bookId, metadata),
            throwsA(isA<BookStorageException>()),
          );
        });
      });
    });

    group('Listing operations', () {
      group('listBookIds', () {
        test('lists all book IDs when books exist', () async {
          final mockDir1 = MockDirectory('$libraryPath/book-1');
          final mockDir2 = MockDirectory('$libraryPath/book-2');
          final mockDir3 = MockDirectory('$libraryPath/book-3');

          when(() =>
                  mockFileSystemRepository.existsDirectory(libraryPath))
              .thenAnswer((_) => Future.value(true));
          when(() =>
                  mockFileSystemRepository.listDirectory(libraryPath))
              .thenAnswer(
                (_) => Stream.fromIterable([mockDir1, mockDir2, mockDir3]),
              );

          final result = await localBookStorage.listBookIds();

          expect(result, containsAll(['book-1', 'book-2', 'book-3']));
          expect(result.length, 3);
        });

        test('returns empty list when library directory does not exist', () async {
          when(() =>
                  mockFileSystemRepository.existsDirectory(libraryPath))
              .thenAnswer((_) => Future.value(false));

          final result = await localBookStorage.listBookIds();

          expect(result, isEmpty);
        });

        test('returns empty list when library is empty', () async {
          when(() =>
                  mockFileSystemRepository.existsDirectory(libraryPath))
              .thenAnswer((_) => Future.value(true));
          when(() =>
                  mockFileSystemRepository.listDirectory(libraryPath))
              .thenAnswer((_) => Stream.fromIterable([]));

          final result = await localBookStorage.listBookIds();

          expect(result, isEmpty);
        });

        test('throws BookStorageException on listing error', () async {
          when(() =>
                  mockFileSystemRepository.existsDirectory(libraryPath))
              .thenAnswer((_) => Future.value(true));
          when(() =>
                  mockFileSystemRepository.listDirectory(libraryPath))
              .thenThrow(Exception('Listing error'));

          expect(
            () => localBookStorage.listBookIds(),
            throwsA(isA<BookStorageException>()),
          );
        });
      });
    });

    group('Change stream notifications', () {
      test('emits bookId on content write', () async {
        when(() =>
                mockFileSystemRepository.createDirectory('$libraryPath/$bookId'))
            .thenAnswer((_) => Future.value(null));
        when(() => mockFileSystemRepository.writeFileAsBytes(
                '$libraryPath/$bookId/book.epub', any()))
            .thenAnswer((_) => Future.value(null));

        final changes = localBookStorage.changeStream();
        final bookIds = <BookId>[];

        final subscription =
            changes.listen((bookIdValue) => bookIds.add(bookIdValue));

        await localBookStorage.writeBytes(bookId, [1, 2, 3]);

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

        when(() =>
                mockFileSystemRepository.createDirectory('$libraryPath/$bookId'))
            .thenAnswer((_) => Future.value(null));
        when(() => mockJsonRepository.writeJson(
                path: '$libraryPath/$bookId/metadata.json', data: any()))
            .thenAnswer((_) => Future.value(null));

        final changes = localBookStorage.changeStream();
        final bookIds = <BookId>[];

        final subscription =
            changes.listen((bookIdValue) => bookIds.add(bookIdValue));

        await localBookStorage.writeMetadata(bookId, metadata);

        await Future.delayed(const Duration(milliseconds: 100));

        expect(bookIds, contains(bookId));

        await subscription.cancel();
      });

      test('emits bookId on delete', () async {
        when(() =>
                mockFileSystemRepository.existsDirectory('$libraryPath/$bookId'))
            .thenAnswer((_) => Future.value(true));
        when(() =>
                mockFileSystemRepository.deleteDirectory('$libraryPath/$bookId'))
            .thenAnswer((_) => Future.value(null));

        final changes = localBookStorage.changeStream();
        final bookIds = <BookId>[];

        final subscription =
            changes.listen((bookIdValue) => bookIds.add(bookIdValue));

        await localBookStorage.delete(bookId);

        await Future.delayed(const Duration(milliseconds: 100));

        expect(bookIds, contains(bookId));

        await subscription.cancel();
      });

      test('stream can have multiple listeners', () async {
        when(() =>
                mockFileSystemRepository.createDirectory('$libraryPath/$bookId'))
            .thenAnswer((_) => Future.value(null));
        when(() => mockFileSystemRepository.writeFileAsBytes(
                '$libraryPath/$bookId/book.epub', any()))
            .thenAnswer((_) => Future.value(null));

        final changes = localBookStorage.changeStream();
        final bookIds1 = <BookId>[];
        final bookIds2 = <BookId>[];

        final subscription1 =
            changes.listen((bookIdValue) => bookIds1.add(bookIdValue));
        final subscription2 =
            changes.listen((bookIdValue) => bookIds2.add(bookIdValue));

        await localBookStorage.writeBytes(bookId, [1, 2, 3]);

        await Future.delayed(const Duration(milliseconds: 100));

        expect(bookIds1, contains(bookId));
        expect(bookIds2, contains(bookId));

        await subscription1.cancel();
        await subscription2.cancel();
      });
    });

    group('Edge cases', () {
      test('handles empty bookId', () async {
        when(() =>
                mockFileSystemRepository.existsDirectory('$libraryPath/'))
            .thenAnswer((_) => Future.value(false));

        final result = await localBookStorage.exists('');

        expect(result, false);
      });

      test('handles special characters in bookId', () async {
        const specialBookId = 'book-id-with-special-chars';

        when(() => mockFileSystemRepository
                .existsDirectory('$libraryPath/$specialBookId'))
            .thenAnswer((_) => Future.value(true));

        final result = await localBookStorage.exists(specialBookId);

        expect(result, true);
      });

      test('handles very long bookId', () async {
        final longBookId = 'a' * 100;

        when(() => mockFileSystemRepository
                .existsDirectory('$libraryPath/$longBookId'))
            .thenAnswer((_) => Future.value(false));

        final result = await localBookStorage.exists(longBookId);

        expect(result, false);
      });

      test('handles concurrent operations with same bookId', () async {
        when(() =>
                mockFileSystemRepository.createDirectory('$libraryPath/$bookId'))
            .thenAnswer((_) => Future.value(null));
        when(() => mockFileSystemRepository.writeFileAsBytes(
                '$libraryPath/$bookId/book.epub', any()))
            .thenAnswer((_) => Future.value(null));

        final futures = [
          localBookStorage.writeBytes(bookId, [1, 2, 3]),
          localBookStorage.writeBytes(bookId, [4, 5, 6]),
          localBookStorage.writeBytes(bookId, [7, 8, 9]),
        ];

        await Future.wait(futures);

        verify(() =>
                mockFileSystemRepository.createDirectory('$libraryPath/$bookId'))
            .called(3);
        verify(() => mockFileSystemRepository.writeFileAsBytes(
                '$libraryPath/$bookId/book.epub', any()))
            .called(3);
      });
    });
  });
}

class MockDirectory extends Mock implements Directory {
  MockDirectory(this._path);
  final String _path;

  @override
  String get path => _path;
}
