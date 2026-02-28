import 'package:flutter_test/flutter_test.dart';
import 'package:novel_glide/features/book_storage/domain/entities/bookmark_entry.dart';

void main() {
  group('BookmarkEntry', () {
    final DateTime now = DateTime.now();
    final DateTime yesterday = now.subtract(const Duration(days: 1));

    test('creates an instance with all fields including label', () {
      final bookmark = BookmarkEntry(
        id: 'bookmark-123',
        cfiPosition: '/6/4[chap02]!/4/2/32',
        timestamp: yesterday,
        label: 'Important passage',
      );

      expect(bookmark.id, 'bookmark-123');
      expect(bookmark.cfiPosition, '/6/4[chap02]!/4/2/32');
      expect(bookmark.timestamp, yesterday);
      expect(bookmark.label, 'Important passage');
    });

    test('creates an instance without label (null)', () {
      final bookmark = BookmarkEntry(
        id: 'bookmark-456',
        cfiPosition: '/6/4[chap03]!/4/2/48',
        timestamp: now,
      );

      expect(bookmark.id, 'bookmark-456');
      expect(bookmark.cfiPosition, '/6/4[chap03]!/4/2/48');
      expect(bookmark.timestamp, now);
      expect(bookmark.label, isNull);
    });

    test('creates an instance with empty label string', () {
      final bookmark = BookmarkEntry(
        id: 'bookmark-789',
        cfiPosition: '/6/4[chap04]!/4/2/64',
        timestamp: now,
        label: '',
      );

      expect(bookmark.label, '');
    });

    group('JSON serialization/deserialization', () {
      test('toJson serializes all fields correctly with label', () {
        final bookmark = BookmarkEntry(
          id: 'bookmark-1',
          cfiPosition: '/6/4[chap02]!/4/2/32',
          timestamp: now,
          label: 'Marked section',
        );

        final json = bookmark.toJson();

        expect(json['id'], 'bookmark-1');
        expect(json['cfiPosition'], '/6/4[chap02]!/4/2/32');
        expect(json['timestamp'], now.toIso8601String());
        expect(json['label'], 'Marked section');
      });

      test('toJson serializes without label (null)', () {
        final bookmark = BookmarkEntry(
          id: 'bookmark-2',
          cfiPosition: '/6/4[chap03]!/4/2/48',
          timestamp: now,
        );

        final json = bookmark.toJson();

        expect(json['id'], 'bookmark-2');
        expect(json['cfiPosition'], '/6/4[chap03]!/4/2/48');
        expect(json['timestamp'], now.toIso8601String());
        expect(json['label'], isNull);
      });

      test('fromJson deserializes all fields correctly with label', () {
        final json = {
          'id': 'bookmark-1',
          'cfiPosition': '/6/4[chap02]!/4/2/32',
          'timestamp': now.toIso8601String(),
          'label': 'Important note',
        };

        final bookmark = BookmarkEntry.fromJson(json);

        expect(bookmark.id, 'bookmark-1');
        expect(bookmark.cfiPosition, '/6/4[chap02]!/4/2/32');
        expect(bookmark.timestamp.toIso8601String(), now.toIso8601String());
        expect(bookmark.label, 'Important note');
      });

      test('fromJson deserializes without label (null)', () {
        final json = {
          'id': 'bookmark-2',
          'cfiPosition': '/6/4[chap03]!/4/2/48',
          'timestamp': now.toIso8601String(),
        };

        final bookmark = BookmarkEntry.fromJson(json);

        expect(bookmark.id, 'bookmark-2');
        expect(bookmark.label, isNull);
      });

      test('fromJson deserializes with null label explicitly', () {
        final json = {
          'id': 'bookmark-3',
          'cfiPosition': '/6/4[chap04]!/4/2/64',
          'timestamp': now.toIso8601String(),
          'label': null,
        };

        final bookmark = BookmarkEntry.fromJson(json);

        expect(bookmark.label, isNull);
      });

      test('round-trip serialization preserves all data with label', () {
        final original = BookmarkEntry(
          id: 'bookmark-uuid-1',
          cfiPosition: '/6/4[chap05]!/4/2/80',
          timestamp: yesterday,
          label: 'Quote to remember',
        );

        final json = original.toJson();
        final deserialized = BookmarkEntry.fromJson(json);

        expect(deserialized, original);
      });

      test('round-trip serialization preserves all data without label', () {
        final original = BookmarkEntry(
          id: 'bookmark-uuid-2',
          cfiPosition: '/6/4[chap06]!/4/2/96',
          timestamp: yesterday,
        );

        final json = original.toJson();
        final deserialized = BookmarkEntry.fromJson(json);

        expect(deserialized, original);
      });
    });

    group('Equality comparison (freezed equality)', () {
      test('two instances with same values are equal', () {
        final bookmark1 = BookmarkEntry(
          id: 'bookmark-1',
          cfiPosition: '/6/4[chap02]!/4/2/32',
          timestamp: now,
          label: 'Note',
        );

        final bookmark2 = BookmarkEntry(
          id: 'bookmark-1',
          cfiPosition: '/6/4[chap02]!/4/2/32',
          timestamp: now,
          label: 'Note',
        );

        expect(bookmark1, bookmark2);
      });

      test('two instances with different ids are not equal', () {
        final bookmark1 = BookmarkEntry(
          id: 'bookmark-1',
          cfiPosition: '/6/4[chap02]!/4/2/32',
          timestamp: now,
          label: 'Note',
        );

        final bookmark2 = BookmarkEntry(
          id: 'bookmark-2',
          cfiPosition: '/6/4[chap02]!/4/2/32',
          timestamp: now,
          label: 'Note',
        );

        expect(bookmark1, isNot(bookmark2));
      });

      test('two instances with different cfiPositions are not equal', () {
        final bookmark1 = BookmarkEntry(
          id: 'bookmark-1',
          cfiPosition: '/6/4[chap02]!/4/2/32',
          timestamp: now,
          label: 'Note',
        );

        final bookmark2 = BookmarkEntry(
          id: 'bookmark-1',
          cfiPosition: '/6/4[chap03]!/4/2/48',
          timestamp: now,
          label: 'Note',
        );

        expect(bookmark1, isNot(bookmark2));
      });

      test('two instances with different timestamps are not equal', () {
        final bookmark1 = BookmarkEntry(
          id: 'bookmark-1',
          cfiPosition: '/6/4[chap02]!/4/2/32',
          timestamp: now,
          label: 'Note',
        );

        final bookmark2 = BookmarkEntry(
          id: 'bookmark-1',
          cfiPosition: '/6/4[chap02]!/4/2/32',
          timestamp: yesterday,
          label: 'Note',
        );

        expect(bookmark1, isNot(bookmark2));
      });

      test('two instances with different labels are not equal', () {
        final bookmark1 = BookmarkEntry(
          id: 'bookmark-1',
          cfiPosition: '/6/4[chap02]!/4/2/32',
          timestamp: now,
          label: 'Note 1',
        );

        final bookmark2 = BookmarkEntry(
          id: 'bookmark-1',
          cfiPosition: '/6/4[chap02]!/4/2/32',
          timestamp: now,
          label: 'Note 2',
        );

        expect(bookmark1, isNot(bookmark2));
      });

      test('two instances with one null label and one non-null are not equal', () {
        final bookmark1 = BookmarkEntry(
          id: 'bookmark-1',
          cfiPosition: '/6/4[chap02]!/4/2/32',
          timestamp: now,
        );

        final bookmark2 = BookmarkEntry(
          id: 'bookmark-1',
          cfiPosition: '/6/4[chap02]!/4/2/32',
          timestamp: now,
          label: 'Note',
        );

        expect(bookmark1, isNot(bookmark2));
      });

      test('two instances with both null labels are equal', () {
        final bookmark1 = BookmarkEntry(
          id: 'bookmark-1',
          cfiPosition: '/6/4[chap02]!/4/2/32',
          timestamp: now,
        );

        final bookmark2 = BookmarkEntry(
          id: 'bookmark-1',
          cfiPosition: '/6/4[chap02]!/4/2/32',
          timestamp: now,
        );

        expect(bookmark1, bookmark2);
      });

      test('hashCode is consistent for equal instances', () {
        final bookmark1 = BookmarkEntry(
          id: 'bookmark-1',
          cfiPosition: '/6/4[chap02]!/4/2/32',
          timestamp: now,
          label: 'Note',
        );

        final bookmark2 = BookmarkEntry(
          id: 'bookmark-1',
          cfiPosition: '/6/4[chap02]!/4/2/32',
          timestamp: now,
          label: 'Note',
        );

        expect(bookmark1.hashCode, bookmark2.hashCode);
      });
    });

    group('toString() representation', () {
      test('toString contains relevant information', () {
        final bookmark = BookmarkEntry(
          id: 'bookmark-1',
          cfiPosition: '/6/4[chap02]!/4/2/32',
          timestamp: now,
          label: 'My note',
        );

        final stringRep = bookmark.toString();

        expect(stringRep, isNotEmpty);
        expect(stringRep, contains('BookmarkEntry'));
      });
    });

    group('Edge cases', () {
      test('handles empty id string', () {
        final bookmark = BookmarkEntry(
          id: '',
          cfiPosition: '/6/4[chap02]!/4/2/32',
          timestamp: now,
        );

        expect(bookmark.id, '');
      });

      test('handles empty cfiPosition string', () {
        final bookmark = BookmarkEntry(
          id: 'bookmark-1',
          cfiPosition: '',
          timestamp: now,
        );

        expect(bookmark.cfiPosition, '');
      });

      test('handles very long label string', () {
        final longLabel = 'a' * 10000;

        final bookmark = BookmarkEntry(
          id: 'bookmark-1',
          cfiPosition: '/6/4[chap02]!/4/2/32',
          timestamp: now,
          label: longLabel,
        );

        expect(bookmark.label, longLabel);
      });

      test('handles special characters in id', () {
        final bookmark = BookmarkEntry(
          id: 'bookmark-@#\$%^&*()',
          cfiPosition: '/6/4[chap02]!/4/2/32',
          timestamp: now,
        );

        expect(bookmark.id, 'bookmark-@#\$%^&*()');
      });

      test('handles special characters in label', () {
        final bookmark = BookmarkEntry(
          id: 'bookmark-1',
          cfiPosition: '/6/4[chap02]!/4/2/32',
          timestamp: now,
          label: 'Note with special chars: @#\$%^&*()',
        );

        expect(bookmark.label, 'Note with special chars: @#\$%^&*()');
      });

      test('handles unicode characters in label', () {
        final bookmark = BookmarkEntry(
          id: 'bookmark-1',
          cfiPosition: '/6/4[chap02]!/4/2/32',
          timestamp: now,
          label: '重要な注記 🔖 Important note',
        );

        expect(bookmark.label, '重要な注記 🔖 Important note');
      });

      test('handles very old timestamp', () {
        final veryOld = DateTime(1900, 1, 1);

        final bookmark = BookmarkEntry(
          id: 'bookmark-1',
          cfiPosition: '/6/4[chap02]!/4/2/32',
          timestamp: veryOld,
        );

        expect(bookmark.timestamp, veryOld);
      });

      test('handles future timestamp', () {
        final future = now.add(const Duration(days: 365));

        final bookmark = BookmarkEntry(
          id: 'bookmark-1',
          cfiPosition: '/6/4[chap02]!/4/2/32',
          timestamp: future,
        );

        expect(bookmark.timestamp, future);
      });

      test('handles UUID v4 format id', () {
        const uuidId = '550e8400-e29b-41d4-a716-446655440000';

        final bookmark = BookmarkEntry(
          id: uuidId,
          cfiPosition: '/6/4[chap02]!/4/2/32',
          timestamp: now,
        );

        expect(bookmark.id, uuidId);
      });

      test('handles complex CFI path', () {
        const complexCfi = '/6/4[chap01_01xhtml]!/4/2[_idParaDest-1]/1:0';

        final bookmark = BookmarkEntry(
          id: 'bookmark-1',
          cfiPosition: complexCfi,
          timestamp: now,
        );

        expect(bookmark.cfiPosition, complexCfi);
      });

      test('handles newlines in label', () {
        final bookmark = BookmarkEntry(
          id: 'bookmark-1',
          cfiPosition: '/6/4[chap02]!/4/2/32',
          timestamp: now,
          label: 'Line 1\nLine 2\nLine 3',
        );

        expect(bookmark.label, contains('\n'));
      });

      test('handles tabs in label', () {
        final bookmark = BookmarkEntry(
          id: 'bookmark-1',
          cfiPosition: '/6/4[chap02]!/4/2/32',
          timestamp: now,
          label: 'Note\twith\ttabs',
        );

        expect(bookmark.label, contains('\t'));
      });
    });
  });
}
