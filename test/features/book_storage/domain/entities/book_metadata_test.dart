import 'package:flutter_test/flutter_test.dart';
import 'package:novel_glide/features/book_storage/domain/entities/book_metadata.dart';
import 'package:novel_glide/features/book_storage/domain/entities/reading_state.dart';
import 'package:novel_glide/features/book_storage/domain/entities/bookmark_entry.dart';

void main() {
  group('BookMetadata', () {
    final DateTime now = DateTime.now();
    final DateTime yesterday = now.subtract(const Duration(days: 1));

    final readingState = ReadingState(
      cfiPosition: '/6/4[chap01]!/4/2/16',
      progress: 45.5,
      lastReadTime: yesterday,
      totalSeconds: 3600,
    );

    final bookmark1 = BookmarkEntry(
      id: 'bookmark-1',
      cfiPosition: '/6/4[chap02]!/4/2/32',
      timestamp: yesterday.add(const Duration(hours: 1)),
      label: 'Important passage',
    );

    final bookmark2 = BookmarkEntry(
      id: 'bookmark-2',
      cfiPosition: '/6/4[chap03]!/4/2/48',
      timestamp: yesterday.add(const Duration(hours: 2)),
    );

    test('creates an instance with all required fields', () {
      final metadata = BookMetadata(
        originalFilename: 'test_book.epub',
        title: 'Test Book Title',
        dateAdded: now,
        readingState: readingState,
        bookmarks: [bookmark1, bookmark2],
      );

      expect(metadata.originalFilename, 'test_book.epub');
      expect(metadata.title, 'Test Book Title');
      expect(metadata.dateAdded, now);
      expect(metadata.readingState, readingState);
      expect(metadata.bookmarks, [bookmark1, bookmark2]);
    });

    test('creates an instance with empty bookmarks list', () {
      final metadata = BookMetadata(
        originalFilename: 'empty_bookmarks.epub',
        title: 'Book Without Bookmarks',
        dateAdded: now,
        readingState: readingState,
        bookmarks: [],
      );

      expect(metadata.bookmarks.isEmpty, true);
    });

    group('JSON serialization/deserialization', () {
      test('fromJson deserializes all fields correctly', () {
        final json = {
          'originalFilename': 'book.epub',
          'title': 'Book Title',
          'dateAdded': now.toIso8601String(),
          'readingState': {
            'cfiPosition': '/6/4[chap01]!/4/2/16',
            'progress': 45.5,
            'lastReadTime': yesterday.toIso8601String(),
            'totalSeconds': 3600,
          },
          'bookmarks': [
            {
              'id': 'bookmark-1',
              'cfiPosition': '/6/4[chap02]!/4/2/32',
              'timestamp': yesterday.add(const Duration(hours: 1)).toIso8601String(),
              'label': 'Important passage',
            }
          ],
        };

        final metadata = BookMetadata.fromJson(json);

        expect(metadata.originalFilename, 'book.epub');
        expect(metadata.title, 'Book Title');
        expect(metadata.dateAdded.toIso8601String(), now.toIso8601String());
        expect(metadata.readingState.cfiPosition, '/6/4[chap01]!/4/2/16');
        expect(metadata.readingState.progress, 45.5);
        expect(metadata.bookmarks.length, 1);
        expect(metadata.bookmarks[0].label, 'Important passage');
      });

      test('toJson serializes fields correctly', () {
        final metadata = BookMetadata(
          originalFilename: 'book.epub',
          title: 'Book Title',
          dateAdded: now,
          readingState: readingState,
          bookmarks: [bookmark1],
        );

        final json = metadata.toJson();

        expect(json['originalFilename'], 'book.epub');
        expect(json['title'], 'Book Title');
        expect(json['dateAdded'], now.toIso8601String());
        // readingState might be a Map or an object depending on json_serializable config
        expect(json['readingState'], isNotNull);
        expect(json['bookmarks'], isNotNull);
        expect(json['bookmarks'], isA<List>());
      });

      test('manual serialization and deserialization', () {
        final original = BookMetadata(
          originalFilename: 'test.epub',
          title: 'Test Book',
          dateAdded: now,
          readingState: readingState,
          bookmarks: [bookmark1],
        );

        // Manually serialize nested objects
        final json = {
          'originalFilename': original.originalFilename,
          'title': original.title,
          'dateAdded': original.dateAdded.toIso8601String(),
          'readingState': original.readingState.toJson(),
          'bookmarks': original.bookmarks.map((b) => b.toJson()).toList(),
        };

        final deserialized = BookMetadata.fromJson(json);

        expect(deserialized.originalFilename, original.originalFilename);
        expect(deserialized.title, original.title);
        expect(deserialized.readingState.cfiPosition, original.readingState.cfiPosition);
        expect(deserialized.bookmarks.length, original.bookmarks.length);
      });

      test('fromJson with empty bookmarks list', () {
        final json = {
          'originalFilename': 'no_bookmarks.epub',
          'title': 'Book Without Bookmarks',
          'dateAdded': now.toIso8601String(),
          'readingState': {
            'cfiPosition': '/6/4[chap01]!/4/2/16',
            'progress': 0.0,
            'lastReadTime': now.toIso8601String(),
            'totalSeconds': 0,
          },
          'bookmarks': [],
        };

        final metadata = BookMetadata.fromJson(json);

        expect(metadata.bookmarks.isEmpty, true);
      });
    });

    group('Equality comparison (freezed equality)', () {
      test('two instances with same values are equal', () {
        final metadata1 = BookMetadata(
          originalFilename: 'book.epub',
          title: 'Same Book',
          dateAdded: now,
          readingState: readingState,
          bookmarks: [bookmark1],
        );

        final metadata2 = BookMetadata(
          originalFilename: 'book.epub',
          title: 'Same Book',
          dateAdded: now,
          readingState: readingState,
          bookmarks: [bookmark1],
        );

        expect(metadata1, metadata2);
      });

      test('two instances with different filenames are not equal', () {
        final metadata1 = BookMetadata(
          originalFilename: 'book1.epub',
          title: 'Same Title',
          dateAdded: now,
          readingState: readingState,
          bookmarks: [],
        );

        final metadata2 = BookMetadata(
          originalFilename: 'book2.epub',
          title: 'Same Title',
          dateAdded: now,
          readingState: readingState,
          bookmarks: [],
        );

        expect(metadata1, isNot(metadata2));
      });

      test('two instances with different bookmarks are not equal', () {
        final metadata1 = BookMetadata(
          originalFilename: 'book.epub',
          title: 'Title',
          dateAdded: now,
          readingState: readingState,
          bookmarks: [bookmark1],
        );

        final metadata2 = BookMetadata(
          originalFilename: 'book.epub',
          title: 'Title',
          dateAdded: now,
          readingState: readingState,
          bookmarks: [bookmark1, bookmark2],
        );

        expect(metadata1, isNot(metadata2));
      });

      test('hashCode is consistent for equal instances', () {
        final metadata1 = BookMetadata(
          originalFilename: 'book.epub',
          title: 'Book',
          dateAdded: now,
          readingState: readingState,
          bookmarks: [],
        );

        final metadata2 = BookMetadata(
          originalFilename: 'book.epub',
          title: 'Book',
          dateAdded: now,
          readingState: readingState,
          bookmarks: [],
        );

        expect(metadata1.hashCode, metadata2.hashCode);
      });
    });

    group('toString() representation', () {
      test('toString contains relevant information', () {
        final metadata = BookMetadata(
          originalFilename: 'book.epub',
          title: 'Test Book',
          dateAdded: now,
          readingState: readingState,
          bookmarks: [bookmark1],
        );

        final stringRep = metadata.toString();

        expect(stringRep, isNotEmpty);
        expect(stringRep, contains('BookMetadata'));
        expect(stringRep, contains('book.epub'));
      });
    });

    group('Edge cases', () {
      test('handles empty filename', () {
        final metadata = BookMetadata(
          originalFilename: '',
          title: 'Title',
          dateAdded: now,
          readingState: readingState,
          bookmarks: [],
        );

        expect(metadata.originalFilename, '');
      });

      test('handles empty title', () {
        final metadata = BookMetadata(
          originalFilename: 'file.epub',
          title: '',
          dateAdded: now,
          readingState: readingState,
          bookmarks: [],
        );

        expect(metadata.title, '');
      });

      test('handles very long filenames and titles', () {
        final longFilename = 'a' * 1000 + '.epub';
        final longTitle = 'b' * 1000;

        final metadata = BookMetadata(
          originalFilename: longFilename,
          title: longTitle,
          dateAdded: now,
          readingState: readingState,
          bookmarks: [],
        );

        expect(metadata.originalFilename, longFilename);
        expect(metadata.title, longTitle);
      });

      test('handles zero progress', () {
        final zeroReadingState = ReadingState(
          cfiPosition: '/6/4[chap01]!/4/2/16',
          progress: 0.0,
          lastReadTime: now,
          totalSeconds: 0,
        );

        final metadata = BookMetadata(
          originalFilename: 'book.epub',
          title: 'New Book',
          dateAdded: now,
          readingState: zeroReadingState,
          bookmarks: [],
        );

        expect(metadata.readingState.progress, 0.0);
        expect(metadata.readingState.totalSeconds, 0);
      });

      test('handles 100% progress', () {
        final completeReadingState = ReadingState(
          cfiPosition: '/6/4[chap99]!/4/2/1024',
          progress: 100.0,
          lastReadTime: now,
          totalSeconds: 36000,
        );

        final metadata = BookMetadata(
          originalFilename: 'book.epub',
          title: 'Completed Book',
          dateAdded: now,
          readingState: completeReadingState,
          bookmarks: [bookmark1, bookmark2],
        );

        expect(metadata.readingState.progress, 100.0);
      });

      test('handles many bookmarks', () {
        final bookmarks = <BookmarkEntry>[
          for (int i = 0; i < 100; i++)
            BookmarkEntry(
              id: 'bookmark-$i',
              cfiPosition: '/6/4[chap${i}]!/4/2/${i * 16}',
              timestamp: now.subtract(Duration(hours: i)),
            )
        ];

        final metadata = BookMetadata(
          originalFilename: 'book.epub',
          title: 'Heavily Bookmarked Book',
          dateAdded: now,
          readingState: readingState,
          bookmarks: bookmarks,
        );

        expect(metadata.bookmarks.length, 100);
      });
    });
  });
}
