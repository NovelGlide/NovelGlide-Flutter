import 'package:flutter_test/flutter_test.dart';
import 'package:novel_glide/features/book_storage/domain/entities/bookmark_entry.dart';
import 'package:novel_glide/features/book_storage/domain/entities/reading_state.dart';
import 'package:novel_glide/features/cloud/domain/entities/book_cloud_metadata.dart';

void main() {
  group('BookCloudMetadata', () {
    late ReadingState testReadingState;
    late BookmarkEntry testAutoBookmark;
    late BookmarkEntry testManualBookmark1;
    late BookmarkEntry testManualBookmark2;
    late BookCloudMetadata testMetadata;

    setUp(() {
      testReadingState = ReadingState(
        cfiPosition: '/6/4[chap01]!/4/2/14,/1:0',
        progress: 45.5,
        lastReadTime: DateTime(2025, 1, 1, 10, 0),
        totalSeconds: 3600,
      );

      testAutoBookmark = BookmarkEntry(
        id: 'auto-bookmark-1',
        cfiPosition: '/6/4[chap01]!/4/2/14,/1:0',
        timestamp: DateTime(2025, 1, 1, 10, 0),
        type: BookmarkType.auto,
      );

      testManualBookmark1 = BookmarkEntry(
        id: 'manual-bookmark-1',
        cfiPosition: '/6/4[chap01]!/4/2/50,/1:0',
        timestamp: DateTime(2025, 1, 1, 8, 0),
        label: 'Important quote',
        type: BookmarkType.manual,
      );

      testManualBookmark2 = BookmarkEntry(
        id: 'manual-bookmark-2',
        cfiPosition: '/6/4[chap02]!/4/2/100,/1:0',
        timestamp: DateTime(2025, 1, 1, 9, 0),
        label: 'Plot twist',
        type: BookmarkType.manual,
      );

      testMetadata = BookCloudMetadata(
        bookId: 'book-123',
        readingState: testReadingState,
        bookmarks: <BookmarkEntry>[
          testAutoBookmark,
          testManualBookmark1,
          testManualBookmark2,
        ],
      );
    });

    group('JSON Serialization', () {
      test('toJson produces correct structure', () {
        final Map<String, dynamic> json = testMetadata.toJson();

        expect(json['bookId'], equals('book-123'));
        expect(json['readingState'], isNotNull);
        expect(json['bookmarks'], isA<List>());
        expect(json['bookmarks'].length, equals(3));
      });

      test('fromJson reconstructs metadata from JSON', () {
        final Map<String, dynamic> json = testMetadata.toJson();
        final BookCloudMetadata reconstructed =
            BookCloudMetadata.fromJson(json);

        expect(reconstructed.bookId, equals(testMetadata.bookId));
        expect(reconstructed.readingState.progress,
            equals(testMetadata.readingState.progress));
        expect(reconstructed.bookmarks.length, equals(3));
      });

      test('round-trip serialization preserves all fields', () {
        final Map<String, dynamic> json = testMetadata.toJson();
        final BookCloudMetadata reconstructed =
            BookCloudMetadata.fromJson(json);

        expect(reconstructed, equals(testMetadata));
      });

      test('JSON includes bookmark type field', () {
        final Map<String, dynamic> json = testMetadata.toJson();
        final List<dynamic> bookmarks = json['bookmarks'] as List<dynamic>;

        // Check auto bookmark
        final Map<String, dynamic> autoBookmark =
            bookmarks[0] as Map<String, dynamic>;
        expect(autoBookmark['type'], equals('auto'));

        // Check manual bookmarks
        final Map<String, dynamic> manualBookmark =
            bookmarks[1] as Map<String, dynamic>;
        expect(manualBookmark['type'], equals('manual'));
      });
    });

    group('Auto Bookmark Behavior', () {
      test('getAutoBookmark returns single auto bookmark', () {
        final BookmarkEntry? auto = testMetadata.getAutoBookmark();

        expect(auto, isNotNull);
        expect(auto?.type, equals(BookmarkType.auto));
        expect(auto?.id, equals('auto-bookmark-1'));
      });

      test('getAutoBookmark returns null when no auto bookmark', () {
        final BookCloudMetadata metaNoAuto = testMetadata.copyWith(
          bookmarks: testMetadata.bookmarks
              .where((BookmarkEntry b) => b.type != BookmarkType.auto)
              .toList(),
        );

        expect(metaNoAuto.getAutoBookmark(), isNull);
      });

      test('updateAutoBookmark replaces existing auto bookmark', () {
        final String newPosition = '/6/5[chap02]!/4/2/14,/1:0';
        final BookCloudMetadata updated =
            testMetadata.updateAutoBookmark(newPosition);

        final BookmarkEntry? autoBookmark = updated.getAutoBookmark();
        expect(autoBookmark, isNotNull);
        expect(autoBookmark?.cfiPosition, equals(newPosition));
        // Should still have only 1 auto bookmark
        expect(
          updated.bookmarks
              .where((BookmarkEntry b) => b.type == BookmarkType.auto)
              .length,
          equals(1),
        );
      });

      test('updateAutoBookmark with custom timestamp', () {
        final String newPosition = '/6/5[chap02]!/4/2/14,/1:0';
        final DateTime customTime = DateTime(2025, 1, 2, 12, 0);

        final BookCloudMetadata updated =
            testMetadata.updateAutoBookmark(newPosition, timestamp: customTime);

        final BookmarkEntry? autoBookmark = updated.getAutoBookmark();
        expect(autoBookmark?.timestamp, equals(customTime));
      });

      test('updateAutoBookmark removes old auto bookmark', () {
        final int originalCount = testMetadata.bookmarks.length;
        final BookCloudMetadata updated =
            testMetadata.updateAutoBookmark('/6/5[chap03]!/4/2/14,/1:0');

        // Should have same number of bookmarks
        expect(updated.bookmarks.length, equals(originalCount));
      });
    });

    group('Manual Bookmark Behavior', () {
      test('getManualBookmarks returns all manual bookmarks', () {
        final List<BookmarkEntry> manuals =
            testMetadata.getManualBookmarks();

        expect(manuals.length, equals(2));
        expect(
          manuals.every((BookmarkEntry b) => b.type == BookmarkType.manual),
          isTrue,
        );
      });

      test('getManualBookmarks returns empty list when none exist', () {
        final BookCloudMetadata metaNoManual = testMetadata.copyWith(
          bookmarks: testMetadata.bookmarks
              .where((BookmarkEntry b) => b.type != BookmarkType.manual)
              .toList(),
        );

        expect(metaNoManual.getManualBookmarks(), isEmpty);
      });

      test('getManualBookmarks sorts by timestamp (oldest first)', () {
        final List<BookmarkEntry> manuals =
            testMetadata.getManualBookmarks();

        // testManualBookmark1 has earlier timestamp (8:00)
        // testManualBookmark2 has later timestamp (9:00)
        expect(manuals[0].timestamp.isBefore(manuals[1].timestamp), isTrue);
        expect(manuals[0].label, equals('Important quote'));
        expect(manuals[1].label, equals('Plot twist'));
      });

      test('addManualBookmark appends to bookmarks list', () {
        final BookmarkEntry newManual = BookmarkEntry(
          id: 'manual-bookmark-3',
          cfiPosition: '/6/4[chap03]!/4/2/50,/1:0',
          timestamp: DateTime(2025, 1, 1, 11, 0),
          label: 'Key insight',
          type: BookmarkType.manual,
        );

        final BookCloudMetadata updated =
            testMetadata.addManualBookmark(newManual);

        expect(updated.bookmarks.length, equals(testMetadata.bookmarks.length + 1));
        expect(
          updated.bookmarks
              .where((BookmarkEntry b) => b.id == 'manual-bookmark-3')
              .isNotEmpty,
          isTrue,
        );
      });

      test('addManualBookmark sets type to manual', () {
        final BookmarkEntry bookmark = BookmarkEntry(
          id: 'bookmark-test',
          cfiPosition: '/6/4[chap01]!/4/2/14,/1:0',
          timestamp: DateTime.now(),
          type: BookmarkType.auto, // Try to add as auto
        );

        final BookCloudMetadata updated =
            testMetadata.addManualBookmark(bookmark);

        final BookmarkEntry? added =
            updated.bookmarks.firstWhere((BookmarkEntry b) => b.id == 'bookmark-test');
        expect(added!.type, equals(BookmarkType.manual));
      });

      test('removeBookmark removes by ID', () {
        final BookCloudMetadata updated =
            testMetadata.removeBookmark('manual-bookmark-1');

        expect(
          updated.bookmarks
              .where((BookmarkEntry b) => b.id == 'manual-bookmark-1')
              .isEmpty,
          isTrue,
        );
        expect(updated.bookmarks.length,
            equals(testMetadata.bookmarks.length - 1));
      });

      test('removeBookmark returns unchanged if ID not found', () {
        final BookCloudMetadata updated =
            testMetadata.removeBookmark('nonexistent-id');

        expect(updated.bookmarks.length, equals(testMetadata.bookmarks.length));
      });
    });

    group('Edge Cases', () {
      test('metadata with empty bookmarks list', () {
        final BookCloudMetadata emptyMeta = BookCloudMetadata(
          bookId: 'book-456',
          readingState: testReadingState,
          bookmarks: const <BookmarkEntry>[],
        );

        expect(emptyMeta.getAutoBookmark(), isNull);
        expect(emptyMeta.getManualBookmarks(), isEmpty);
      });

      test('metadata with only auto bookmark', () {
        final BookCloudMetadata onlyAuto = BookCloudMetadata(
          bookId: 'book-789',
          readingState: testReadingState,
          bookmarks: <BookmarkEntry>[testAutoBookmark],
        );

        expect(onlyAuto.getAutoBookmark(), isNotNull);
        expect(onlyAuto.getManualBookmarks(), isEmpty);
      });

      test('metadata with only manual bookmarks', () {
        final BookCloudMetadata onlyManual = BookCloudMetadata(
          bookId: 'book-xyz',
          readingState: testReadingState,
          bookmarks: <BookmarkEntry>[testManualBookmark1, testManualBookmark2],
        );

        expect(onlyManual.getAutoBookmark(), isNull);
        expect(onlyManual.getManualBookmarks().length, equals(2));
      });

      test('bookmark with null label', () {
        final BookmarkEntry bookmarkNoLabel = BookmarkEntry(
          id: 'bookmark-no-label',
          cfiPosition: '/6/4[chap01]!/4/2/14,/1:0',
          timestamp: DateTime.now(),
          type: BookmarkType.manual,
        );

        final BookCloudMetadata meta = BookCloudMetadata(
          bookId: 'book-label-test',
          readingState: testReadingState,
          bookmarks: <BookmarkEntry>[bookmarkNoLabel],
        );

        final Map<String, dynamic> json = meta.toJson();
        final BookCloudMetadata reconstructed =
            BookCloudMetadata.fromJson(json);

        expect(reconstructed.bookmarks.first.label, isNull);
      });

      test('reading state with zero reading time', () {
        final ReadingState zeroTime = ReadingState(
          cfiPosition: '/6/4[chap01]!/4/2/14,/1:0',
          progress: 0.0,
          lastReadTime: DateTime(2025, 1, 1),
          totalSeconds: 0,
        );

        final BookCloudMetadata meta = BookCloudMetadata(
          bookId: 'book-zero-time',
          readingState: zeroTime,
          bookmarks: const <BookmarkEntry>[],
        );

        final Map<String, dynamic> json = meta.toJson();
        final BookCloudMetadata reconstructed =
            BookCloudMetadata.fromJson(json);

        expect(reconstructed.readingState.totalSeconds, equals(0));
      });
    });

    group('Immutability & Equality', () {
      test('metadata is immutable (copyWith creates new instance)', () {
        final BookCloudMetadata updated =
            testMetadata.copyWith(bookId: 'book-999');

        expect(updated.bookId, equals('book-999'));
        expect(testMetadata.bookId, equals('book-123'));
        expect(identical(updated, testMetadata), isFalse);
      });

      test('two metadata with same values are equal', () {
        final BookCloudMetadata copy = BookCloudMetadata(
          bookId: testMetadata.bookId,
          readingState: testMetadata.readingState,
          bookmarks: testMetadata.bookmarks,
        );

        expect(copy, equals(testMetadata));
      });

      test('two metadata with different values are not equal', () {
        final BookCloudMetadata different = testMetadata.copyWith(
          bookId: 'different-id',
        );

        expect(different, isNot(equals(testMetadata)));
      });
    });
  });
}
