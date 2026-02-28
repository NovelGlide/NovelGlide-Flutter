import 'package:flutter_test/flutter_test.dart';

import 'package:novel_glide/features/book_storage/domain/entities/bookmark_entry.dart';
import 'package:novel_glide/features/bookmark/domain/entities/bookmark_item.dart';

void main() {
  group('BookmarkItem', () {
    final DateTime now = DateTime.now();
    const String bookId = 'book-123';
    const String bookTitle = 'The Great Gatsby';
    const String id = 'bm-456';
    const String cfiPosition =
        'epubcfi(/6/4[chap01]!/4/2/16,1:10)';
    const String? label = 'Important passage';

    group('Freezed immutability', () {
      test('creates an immutable instance', () {
        final BookmarkItem item = BookmarkItem(
          id: id,
          bookId: bookId,
          bookTitle: bookTitle,
          position: cfiPosition,
          label: label,
          createdAt: now,
        );

        expect(item.id, equals(id));
        expect(item.bookId, equals(bookId));
        expect(item.bookTitle, equals(bookTitle));
        expect(item.position, equals(cfiPosition));
        expect(item.label, equals(label));
        expect(item.createdAt, equals(now));
      });

      test('copyWith creates a new instance with updated values', () {
        final BookmarkItem original = BookmarkItem(
          id: id,
          bookId: bookId,
          bookTitle: bookTitle,
          position: cfiPosition,
          label: label,
          createdAt: now,
        );

        final BookmarkItem updated = original.copyWith(
          label: 'Updated label',
        );

        expect(updated.id, equals(original.id));
        expect(updated.bookId, equals(original.bookId));
        expect(updated.bookTitle, equals(original.bookTitle));
        expect(updated.position, equals(original.position));
        expect(updated.label, equals('Updated label'));
        expect(updated.createdAt, equals(original.createdAt));
      });

      test('equality works correctly', () {
        final BookmarkItem item1 = BookmarkItem(
          id: id,
          bookId: bookId,
          bookTitle: bookTitle,
          position: cfiPosition,
          label: label,
          createdAt: now,
        );

        final BookmarkItem item2 = BookmarkItem(
          id: id,
          bookId: bookId,
          bookTitle: bookTitle,
          position: cfiPosition,
          label: label,
          createdAt: now,
        );

        expect(item1, equals(item2));
      });

      test('hash code is consistent', () {
        final BookmarkItem item1 = BookmarkItem(
          id: id,
          bookId: bookId,
          bookTitle: bookTitle,
          position: cfiPosition,
          label: label,
          createdAt: now,
        );

        final BookmarkItem item2 = BookmarkItem(
          id: id,
          bookId: bookId,
          bookTitle: bookTitle,
          position: cfiPosition,
          label: label,
          createdAt: now,
        );

        expect(item1.hashCode, equals(item2.hashCode));
      });
    });

    group('fromBookmarkEntry factory', () {
      test('creates BookmarkItem from BookmarkEntry', () {
        final BookmarkEntry entry = BookmarkEntry(
          id: id,
          cfiPosition: cfiPosition,
          timestamp: now,
          label: label,
        );

        final BookmarkItem item =
            BookmarkItem.fromBookmarkEntry(
          entry,
          bookTitle,
          bookId,
        );

        expect(item.id, equals(id));
        expect(item.bookId, equals(bookId));
        expect(item.bookTitle, equals(bookTitle));
        expect(item.position, equals(cfiPosition));
        expect(item.label, equals(label));
        expect(item.createdAt, equals(now));
      });

      test('handles null label in BookmarkEntry', () {
        final BookmarkEntry entry = BookmarkEntry(
          id: id,
          cfiPosition: cfiPosition,
          timestamp: now,
          label: null,
        );

        final BookmarkItem item =
            BookmarkItem.fromBookmarkEntry(
          entry,
          bookTitle,
          bookId,
        );

        expect(item.label, isNull);
      });

      test('preserves special characters in label', () {
        const String specialLabel =
            'Quote: "To be or not to be" [Act III]';
        final BookmarkEntry entry = BookmarkEntry(
          id: id,
          cfiPosition: cfiPosition,
          timestamp: now,
          label: specialLabel,
        );

        final BookmarkItem item =
            BookmarkItem.fromBookmarkEntry(
          entry,
          bookTitle,
          bookId,
        );

        expect(item.label, equals(specialLabel));
      });
    });

    group('Position format handling', () {
      test('supports CFI position format', () {
        const String cfiBased =
            'epubcfi(/6/4[chap01]!/4/2/16,1:10)';

        final BookmarkItem item = BookmarkItem(
          id: id,
          bookId: bookId,
          bookTitle: bookTitle,
          position: cfiBased,
          label: label,
          createdAt: now,
        );

        expect(item.position, equals(cfiBased));
      });

      test('supports chapter identifier format', () {
        const String chapterFormat = 'chapter-01';

        final BookmarkItem item = BookmarkItem(
          id: id,
          bookId: bookId,
          bookTitle: bookTitle,
          position: chapterFormat,
          label: label,
          createdAt: now,
        );

        expect(item.position, equals(chapterFormat));
      });

      test('supports numeric chapter format', () {
        const String numericChapter = '001';

        final BookmarkItem item = BookmarkItem(
          id: id,
          bookId: bookId,
          bookTitle: bookTitle,
          position: numericChapter,
          label: label,
          createdAt: now,
        );

        expect(item.position, equals(numericChapter));
      });
    });

    group('JSON serialization', () {
      test('converts to JSON correctly', () {
        final BookmarkItem item = BookmarkItem(
          id: id,
          bookId: bookId,
          bookTitle: bookTitle,
          position: cfiPosition,
          label: label,
          createdAt: now,
        );

        final Map<String, dynamic> json = item.toJson();

        expect(json['id'], equals(id));
        expect(json['bookId'], equals(bookId));
        expect(json['bookTitle'], equals(bookTitle));
        expect(json['position'], equals(cfiPosition));
        expect(json['label'], equals(label));
        expect(
          json['createdAt'],
          equals(now.toIso8601String()),
        );
      });

      test('creates from JSON correctly', () {
        final Map<String, dynamic> json = <String, dynamic>{
          'id': id,
          'bookId': bookId,
          'bookTitle': bookTitle,
          'position': cfiPosition,
          'label': label,
          'createdAt': now.toIso8601String(),
        };

        final BookmarkItem item = BookmarkItem.fromJson(json);

        expect(item.id, equals(id));
        expect(item.bookId, equals(bookId));
        expect(item.bookTitle, equals(bookTitle));
        expect(item.position, equals(cfiPosition));
        expect(item.label, equals(label));
        expect(item.createdAt, equals(now));
      });

      test('round-trip JSON serialization', () {
        final BookmarkItem original = BookmarkItem(
          id: id,
          bookId: bookId,
          bookTitle: bookTitle,
          position: cfiPosition,
          label: label,
          createdAt: now,
        );

        final Map<String, dynamic> json = original.toJson();
        final BookmarkItem restored =
            BookmarkItem.fromJson(json);

        expect(restored, equals(original));
      });

      test('handles null label in JSON', () {
        final Map<String, dynamic> json = <String, dynamic>{
          'id': id,
          'bookId': bookId,
          'bookTitle': bookTitle,
          'position': cfiPosition,
          'label': null,
          'createdAt': now.toIso8601String(),
        };

        final BookmarkItem item = BookmarkItem.fromJson(json);

        expect(item.label, isNull);
      });

      test('handles missing label in JSON', () {
        final Map<String, dynamic> json = <String, dynamic>{
          'id': id,
          'bookId': bookId,
          'bookTitle': bookTitle,
          'position': cfiPosition,
          'createdAt': now.toIso8601String(),
        };

        final BookmarkItem item = BookmarkItem.fromJson(json);

        expect(item.label, isNull);
      });
    });

    group('Edge cases', () {
      test('handles empty label string', () {
        final BookmarkItem item = BookmarkItem(
          id: id,
          bookId: bookId,
          bookTitle: bookTitle,
          position: cfiPosition,
          label: '',
          createdAt: now,
        );

        expect(item.label, equals(''));
      });

      test('handles very long label text', () {
        final String longLabel =
            'a' * 500; // 500 character label

        final BookmarkItem item = BookmarkItem(
          id: id,
          bookId: bookId,
          bookTitle: bookTitle,
          position: cfiPosition,
          label: longLabel,
          createdAt: now,
        );

        expect(item.label, equals(longLabel));
      });

      test('handles book title with special characters', () {
        const String specialTitle =
            'Café & Restaurant: "The Blue Door" (Updated)';

        final BookmarkItem item = BookmarkItem(
          id: id,
          bookId: bookId,
          bookTitle: specialTitle,
          position: cfiPosition,
          label: label,
          createdAt: now,
        );

        expect(item.bookTitle, equals(specialTitle));
      });

      test('handles UUID format IDs', () {
        const String uuidId =
            '550e8400-e29b-41d4-a716-446655440000';

        final BookmarkItem item = BookmarkItem(
          id: uuidId,
          bookId: bookId,
          bookTitle: bookTitle,
          position: cfiPosition,
          label: label,
          createdAt: now,
        );

        expect(item.id, equals(uuidId));
      });

      test('maintains precise timestamp', () {
        final DateTime precise =
            DateTime(2026, 2, 28, 22, 30, 45, 123, 456);

        final BookmarkItem item = BookmarkItem(
          id: id,
          bookId: bookId,
          bookTitle: bookTitle,
          position: cfiPosition,
          label: label,
          createdAt: precise,
        );

        expect(item.createdAt, equals(precise));
      });
    });

    group('toString and debugging', () {
      test('toString provides readable representation', () {
        final BookmarkItem item = BookmarkItem(
          id: id,
          bookId: bookId,
          bookTitle: bookTitle,
          position: cfiPosition,
          label: label,
          createdAt: now,
        );

        final String str = item.toString();

        expect(str, contains('BookmarkItem'));
        expect(str, contains(id));
        expect(str, contains(bookTitle));
      });
    });
  });
}
