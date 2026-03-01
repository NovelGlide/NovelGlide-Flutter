import 'package:flutter_test/flutter_test.dart';
import 'package:migration_implementation/features/migration/domain/entities/skipped_book.dart';

void main() {
  group('SkippedBook', () {
    group('Creation and Immutability', () {
      test('creates SkippedBook with all fields', () {
        final time = DateTime(2026, 3, 1, 10, 30, 0);
        final book = SkippedBook(
          originalFileName: 'corrupt.epub',
          reason: 'Corrupt EPUB',
          attemptedAt: time,
        );

        expect(book.originalFileName, 'corrupt.epub');
        expect(book.reason, 'Corrupt EPUB');
        expect(book.attemptedAt, time);
      });

      test('is immutable (fields cannot be modified)', () {
        final book = SkippedBook(
          originalFileName: 'test.epub',
          reason: 'Test reason',
          attemptedAt: DateTime(2026, 3, 1),
        );

        // Dart's freezed ensures immutability; attempting to assign
        // will fail at compile time. This test documents the property.
        expect(book.originalFileName, 'test.epub');
      });
    });

    group('Equality', () {
      test('two SkippedBooks with same data are equal', () {
        final time = DateTime(2026, 3, 1, 10, 30, 0);
        final book1 = SkippedBook(
          originalFileName: 'corrupt.epub',
          reason: 'Corrupt EPUB',
          attemptedAt: time,
        );

        final book2 = SkippedBook(
          originalFileName: 'corrupt.epub',
          reason: 'Corrupt EPUB',
          attemptedAt: time,
        );

        expect(book1, equals(book2));
      });

      test('two SkippedBooks with different filenames are not equal', () {
        final time = DateTime(2026, 3, 1, 10, 30, 0);
        final book1 = SkippedBook(
          originalFileName: 'corrupt1.epub',
          reason: 'Corrupt EPUB',
          attemptedAt: time,
        );

        final book2 = SkippedBook(
          originalFileName: 'corrupt2.epub',
          reason: 'Corrupt EPUB',
          attemptedAt: time,
        );

        expect(book1, isNot(equals(book2)));
      });

      test('two SkippedBooks with different reasons are not equal', () {
        final time = DateTime(2026, 3, 1, 10, 30, 0);
        final book1 = SkippedBook(
          originalFileName: 'corrupt.epub',
          reason: 'Corrupt EPUB',
          attemptedAt: time,
        );

        final book2 = SkippedBook(
          originalFileName: 'corrupt.epub',
          reason: 'Unreadable metadata',
          attemptedAt: time,
        );

        expect(book1, isNot(equals(book2)));
      });

      test('two SkippedBooks with different times are not equal', () {
        final time1 = DateTime(2026, 3, 1, 10, 30, 0);
        final time2 = DateTime(2026, 3, 1, 10, 31, 0);

        final book1 = SkippedBook(
          originalFileName: 'corrupt.epub',
          reason: 'Corrupt EPUB',
          attemptedAt: time1,
        );

        final book2 = SkippedBook(
          originalFileName: 'corrupt.epub',
          reason: 'Corrupt EPUB',
          attemptedAt: time2,
        );

        expect(book1, isNot(equals(book2)));
      });
    });

    group('JSON Serialization', () {
      test('serializes to JSON correctly', () {
        final time = DateTime(2026, 3, 1, 10, 30, 0);
        final book = SkippedBook(
          originalFileName: 'corrupt.epub',
          reason: 'Corrupt EPUB',
          attemptedAt: time,
        );

        final json = book.toJson();
        expect(json['originalFileName'], 'corrupt.epub');
        expect(json['reason'], 'Corrupt EPUB');
        expect(json['attemptedAt'], time.toIso8601String());
      });

      test('deserializes from JSON correctly', () {
        final json = {
          'originalFileName': 'unreadable.epub',
          'reason': 'Unreadable metadata',
          'attemptedAt': '2026-03-01T10:30:00.000Z',
        };

        final book = SkippedBook.fromJson(json);
        expect(book.originalFileName, 'unreadable.epub');
        expect(book.reason, 'Unreadable metadata');
      });

      test('round-trip serialization preserves all data', () {
        final original = SkippedBook(
          originalFileName: 'missing.epub',
          reason: 'Missing file',
          attemptedAt: DateTime(2026, 3, 1, 15, 45, 30),
        );

        final json = original.toJson();
        final restored = SkippedBook.fromJson(json);

        expect(restored.originalFileName, original.originalFileName);
        expect(restored.reason, original.reason);
        expect(restored.attemptedAt, original.attemptedAt);
      });

      test('handles various reason strings in serialization', () {
        final reasons = [
          'Corrupt EPUB',
          'Unreadable metadata',
          'Missing file',
          'Invalid CFI',
          'File locked by another process',
          'Insufficient permissions',
        ];

        for (final reason in reasons) {
          final book = SkippedBook(
            originalFileName: 'test.epub',
            reason: reason,
            attemptedAt: DateTime(2026, 3, 1),
          );

          final json = book.toJson();
          final restored = SkippedBook.fromJson(json);

          expect(restored.reason, reason);
        }
      });
    });

    group('Collections and Storage', () {
      test('can be stored in a list', () {
        final books = [
          SkippedBook(
            originalFileName: 'corrupt1.epub',
            reason: 'Corrupt EPUB',
            attemptedAt: DateTime(2026, 3, 1, 10, 0),
          ),
          SkippedBook(
            originalFileName: 'corrupt2.epub',
            reason: 'Unreadable metadata',
            attemptedAt: DateTime(2026, 3, 1, 10, 5),
          ),
        ];

        expect(books.length, 2);
        expect(books[0].originalFileName, 'corrupt1.epub');
      });

      test('can be stored in a map', () {
        final booksMap = {
          'corrupt.epub': SkippedBook(
            originalFileName: 'corrupt.epub',
            reason: 'Corrupt EPUB',
            attemptedAt: DateTime(2026, 3, 1, 10, 0),
          ),
        };

        expect(booksMap['corrupt.epub']?.reason, 'Corrupt EPUB');
      });

      test('list equality works correctly', () {
        final list1 = [
          SkippedBook(
            originalFileName: 'test.epub',
            reason: 'Test',
            attemptedAt: DateTime(2026, 3, 1),
          ),
        ];

        final list2 = [
          SkippedBook(
            originalFileName: 'test.epub',
            reason: 'Test',
            attemptedAt: DateTime(2026, 3, 1),
          ),
        ];

        expect(list1, equals(list2));
      });
    });

    group('Practical Use Cases', () {
      test('represents typical corrupt EPUB case', () {
        final book = SkippedBook(
          originalFileName: 'corrupted_book.epub',
          reason: 'Corrupt EPUB',
          attemptedAt: DateTime(2026, 3, 1, 12, 15),
        );

        expect(book.originalFileName, contains('.epub'));
        expect(book.reason, isNotEmpty);
      });

      test('represents typical unreadable metadata case', () {
        final book = SkippedBook(
          originalFileName: 'unreadable.epub',
          reason: 'Unreadable metadata',
          attemptedAt: DateTime(2026, 3, 1, 12, 20),
        );

        expect(book.reason, contains('metadata'));
      });

      test('multiple skipped books with different reasons', () {
        final skipped = [
          SkippedBook(
            originalFileName: 'corrupt.epub',
            reason: 'Corrupt EPUB',
            attemptedAt: DateTime(2026, 3, 1, 10, 0),
          ),
          SkippedBook(
            originalFileName: 'unreadable.epub',
            reason: 'Unreadable metadata',
            attemptedAt: DateTime(2026, 3, 1, 10, 5),
          ),
          SkippedBook(
            originalFileName: 'missing.epub',
            reason: 'Missing file',
            attemptedAt: DateTime(2026, 3, 1, 10, 10),
          ),
        ];

        expect(skipped.length, 3);
        expect(skipped.map((b) => b.reason), isNotEmpty);
      });
    });
  });
}
