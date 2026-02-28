import 'package:flutter_test/flutter_test.dart';
import 'package:novel_glide/features/book_storage/domain/entities/reading_state.dart';

void main() {
  group('ReadingState', () {
    final DateTime now = DateTime.now();
    final DateTime oneHourAgo = now.subtract(const Duration(hours: 1));

    test('creates an instance with all required fields', () {
      final readingState = ReadingState(
        cfiPosition: '/6/4[chap01]!/4/2/16',
        progress: 45.5,
        lastReadTime: oneHourAgo,
        totalSeconds: 3600,
      );

      expect(readingState.cfiPosition, '/6/4[chap01]!/4/2/16');
      expect(readingState.progress, 45.5);
      expect(readingState.lastReadTime, oneHourAgo);
      expect(readingState.totalSeconds, 3600);
    });

    test('creates an instance with zero progress and totalSeconds', () {
      final readingState = ReadingState(
        cfiPosition: '/6/4[chap01]!/4/2/1',
        progress: 0.0,
        lastReadTime: now,
        totalSeconds: 0,
      );

      expect(readingState.progress, 0.0);
      expect(readingState.totalSeconds, 0);
    });

    test('creates an instance with 100% progress', () {
      final readingState = ReadingState(
        cfiPosition: '/6/4[chap99]!/4/2/1024',
        progress: 100.0,
        lastReadTime: now,
        totalSeconds: 36000,
      );

      expect(readingState.progress, 100.0);
    });

    group('JSON serialization/deserialization', () {
      test('toJson serializes all fields correctly', () {
        final readingState = ReadingState(
          cfiPosition: '/6/4[chap01]!/4/2/16',
          progress: 45.5,
          lastReadTime: now,
          totalSeconds: 7200,
        );

        final json = readingState.toJson();

        expect(json['cfiPosition'], '/6/4[chap01]!/4/2/16');
        expect(json['progress'], 45.5);
        expect(json['lastReadTime'], now.toIso8601String());
        expect(json['totalSeconds'], 7200);
      });

      test('fromJson deserializes all fields correctly', () {
        final json = {
          'cfiPosition': '/6/4[chap02]!/4/2/32',
          'progress': 62.3,
          'lastReadTime': now.toIso8601String(),
          'totalSeconds': 5400,
        };

        final readingState = ReadingState.fromJson(json);

        expect(readingState.cfiPosition, '/6/4[chap02]!/4/2/32');
        expect(readingState.progress, 62.3);
        expect(readingState.lastReadTime.toIso8601String(), now.toIso8601String());
        expect(readingState.totalSeconds, 5400);
      });

      test('round-trip serialization preserves all data', () {
        final original = ReadingState(
          cfiPosition: '/6/4[chap05]!/4/2/64',
          progress: 50.0,
          lastReadTime: oneHourAgo,
          totalSeconds: 9000,
        );

        final json = original.toJson();
        final deserialized = ReadingState.fromJson(json);

        expect(deserialized, original);
      });

      test('fromJson with zero progress', () {
        final json = {
          'cfiPosition': '/6/4[chap01]!/4/2/1',
          'progress': 0.0,
          'lastReadTime': now.toIso8601String(),
          'totalSeconds': 0,
        };

        final readingState = ReadingState.fromJson(json);

        expect(readingState.progress, 0.0);
        expect(readingState.totalSeconds, 0);
      });

      test('fromJson with 100% progress', () {
        final json = {
          'cfiPosition': '/6/4[chap99]!/4/2/1024',
          'progress': 100.0,
          'lastReadTime': now.toIso8601String(),
          'totalSeconds': 86400,
        };

        final readingState = ReadingState.fromJson(json);

        expect(readingState.progress, 100.0);
      });
    });

    group('Equality comparison (freezed equality)', () {
      test('two instances with same values are equal', () {
        final state1 = ReadingState(
          cfiPosition: '/6/4[chap01]!/4/2/16',
          progress: 45.5,
          lastReadTime: now,
          totalSeconds: 3600,
        );

        final state2 = ReadingState(
          cfiPosition: '/6/4[chap01]!/4/2/16',
          progress: 45.5,
          lastReadTime: now,
          totalSeconds: 3600,
        );

        expect(state1, state2);
      });

      test('two instances with different cfiPosition are not equal', () {
        final state1 = ReadingState(
          cfiPosition: '/6/4[chap01]!/4/2/16',
          progress: 45.5,
          lastReadTime: now,
          totalSeconds: 3600,
        );

        final state2 = ReadingState(
          cfiPosition: '/6/4[chap02]!/4/2/16',
          progress: 45.5,
          lastReadTime: now,
          totalSeconds: 3600,
        );

        expect(state1, isNot(state2));
      });

      test('two instances with different progress are not equal', () {
        final state1 = ReadingState(
          cfiPosition: '/6/4[chap01]!/4/2/16',
          progress: 45.5,
          lastReadTime: now,
          totalSeconds: 3600,
        );

        final state2 = ReadingState(
          cfiPosition: '/6/4[chap01]!/4/2/16',
          progress: 50.0,
          lastReadTime: now,
          totalSeconds: 3600,
        );

        expect(state1, isNot(state2));
      });

      test('two instances with different lastReadTime are not equal', () {
        final state1 = ReadingState(
          cfiPosition: '/6/4[chap01]!/4/2/16',
          progress: 45.5,
          lastReadTime: now,
          totalSeconds: 3600,
        );

        final state2 = ReadingState(
          cfiPosition: '/6/4[chap01]!/4/2/16',
          progress: 45.5,
          lastReadTime: oneHourAgo,
          totalSeconds: 3600,
        );

        expect(state1, isNot(state2));
      });

      test('two instances with different totalSeconds are not equal', () {
        final state1 = ReadingState(
          cfiPosition: '/6/4[chap01]!/4/2/16',
          progress: 45.5,
          lastReadTime: now,
          totalSeconds: 3600,
        );

        final state2 = ReadingState(
          cfiPosition: '/6/4[chap01]!/4/2/16',
          progress: 45.5,
          lastReadTime: now,
          totalSeconds: 7200,
        );

        expect(state1, isNot(state2));
      });

      test('hashCode is consistent for equal instances', () {
        final state1 = ReadingState(
          cfiPosition: '/6/4[chap01]!/4/2/16',
          progress: 45.5,
          lastReadTime: now,
          totalSeconds: 3600,
        );

        final state2 = ReadingState(
          cfiPosition: '/6/4[chap01]!/4/2/16',
          progress: 45.5,
          lastReadTime: now,
          totalSeconds: 3600,
        );

        expect(state1.hashCode, state2.hashCode);
      });
    });

    group('toString() representation', () {
      test('toString contains relevant information', () {
        final readingState = ReadingState(
          cfiPosition: '/6/4[chap01]!/4/2/16',
          progress: 45.5,
          lastReadTime: now,
          totalSeconds: 3600,
        );

        final stringRep = readingState.toString();

        expect(stringRep, isNotEmpty);
        expect(stringRep, contains('ReadingState'));
      });
    });

    group('Edge cases', () {
      test('handles empty cfiPosition string', () {
        final readingState = ReadingState(
          cfiPosition: '',
          progress: 0.0,
          lastReadTime: now,
          totalSeconds: 0,
        );

        expect(readingState.cfiPosition, '');
      });

      test('handles very long cfiPosition string', () {
        final longCfi = 'a' * 1000;

        final readingState = ReadingState(
          cfiPosition: longCfi,
          progress: 50.0,
          lastReadTime: now,
          totalSeconds: 3600,
        );

        expect(readingState.cfiPosition, longCfi);
      });

      test('handles decimal progress values', () {
        final readingState = ReadingState(
          cfiPosition: '/6/4[chap01]!/4/2/16',
          progress: 33.333333,
          lastReadTime: now,
          totalSeconds: 1234,
        );

        expect(readingState.progress, closeTo(33.333333, 0.000001));
      });

      test('handles large totalSeconds values', () {
        final readingState = ReadingState(
          cfiPosition: '/6/4[chap01]!/4/2/16',
          progress: 100.0,
          lastReadTime: now,
          totalSeconds: 31536000, // 1 year in seconds
        );

        expect(readingState.totalSeconds, 31536000);
      });

      test('handles progress slightly above 100 (edge case)', () {
        final readingState = ReadingState(
          cfiPosition: '/6/4[chap01]!/4/2/16',
          progress: 100.1,
          lastReadTime: now,
          totalSeconds: 3600,
        );

        expect(readingState.progress, 100.1);
      });

      test('handles negative progress (edge case)', () {
        final readingState = ReadingState(
          cfiPosition: '/6/4[chap01]!/4/2/16',
          progress: -5.0,
          lastReadTime: now,
          totalSeconds: 3600,
        );

        expect(readingState.progress, -5.0);
      });

      test('handles negative totalSeconds (edge case)', () {
        final readingState = ReadingState(
          cfiPosition: '/6/4[chap01]!/4/2/16',
          progress: 50.0,
          lastReadTime: now,
          totalSeconds: -100,
        );

        expect(readingState.totalSeconds, -100);
      });

      test('handles very old lastReadTime', () {
        final veryOld = DateTime(1900, 1, 1);

        final readingState = ReadingState(
          cfiPosition: '/6/4[chap01]!/4/2/16',
          progress: 50.0,
          lastReadTime: veryOld,
          totalSeconds: 3600,
        );

        expect(readingState.lastReadTime, veryOld);
      });

      test('handles future lastReadTime', () {
        final future = now.add(const Duration(days: 365));

        final readingState = ReadingState(
          cfiPosition: '/6/4[chap01]!/4/2/16',
          progress: 50.0,
          lastReadTime: future,
          totalSeconds: 3600,
        );

        expect(readingState.lastReadTime, future);
      });
    });
  });
}
