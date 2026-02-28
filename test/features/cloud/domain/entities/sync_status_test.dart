import 'package:flutter_test/flutter_test.dart';
import 'package:novel_glide/features/cloud/domain/entities/sync_status.dart';

void main() {
  group('SyncStatus enum', () {
    test('all enum values are defined', () {
      expect(SyncStatus.values, hasLength(7));
      expect(SyncStatus.values, contains(SyncStatus.synced));
      expect(SyncStatus.values, contains(SyncStatus.pending));
      expect(SyncStatus.values, contains(SyncStatus.syncing));
      expect(SyncStatus.values, contains(SyncStatus.error));
      expect(SyncStatus.values, contains(SyncStatus.conflict));
      expect(SyncStatus.values, contains(SyncStatus.cloudOnly));
      expect(SyncStatus.values, contains(SyncStatus.localOnly));
    });
  });

  group('SyncStatusDisplay extension - icon property', () {
    test('synced status has correct icon', () {
      expect(SyncStatus.synced.icon, equals('✅'));
    });

    test('pending status has correct icon', () {
      expect(SyncStatus.pending.icon, equals('⏳'));
    });

    test('syncing status has correct icon', () {
      expect(SyncStatus.syncing.icon, equals('🔄'));
    });

    test('error status has correct icon', () {
      expect(SyncStatus.error.icon, equals('❌'));
    });

    test('conflict status has correct icon', () {
      expect(SyncStatus.conflict.icon, equals('⚠️'));
    });

    test('cloudOnly status has correct icon', () {
      expect(SyncStatus.cloudOnly.icon, equals('☁️'));
    });

    test('localOnly status has correct icon', () {
      expect(SyncStatus.localOnly.icon, equals('🔒'));
    });
  });

  group('SyncStatusDisplay extension - colorHex property', () {
    test('synced status has green color', () {
      expect(SyncStatus.synced.colorHex, equals('#4CAF50'));
    });

    test('pending status has orange color', () {
      expect(SyncStatus.pending.colorHex, equals('#FF9800'));
    });

    test('syncing status has blue color', () {
      expect(SyncStatus.syncing.colorHex, equals('#2196F3'));
    });

    test('error status has red color', () {
      expect(SyncStatus.error.colorHex, equals('#F44336'));
    });

    test('conflict status has red color', () {
      expect(SyncStatus.conflict.colorHex, equals('#F44336'));
    });

    test('cloudOnly status has blue color', () {
      expect(SyncStatus.cloudOnly.colorHex, equals('#2196F3'));
    });

    test('localOnly status has gray color', () {
      expect(SyncStatus.localOnly.colorHex, equals('#9E9E9E'));
    });
  });

  group('SyncStatusDisplay extension - label property', () {
    test('synced status returns correct label', () {
      expect(SyncStatus.synced.label, equals('Synced'));
    });

    test('pending status returns correct label', () {
      expect(SyncStatus.pending.label, equals('Pending'));
    });

    test('syncing status returns correct label', () {
      expect(SyncStatus.syncing.label, equals('Syncing'));
    });

    test('error status returns correct label', () {
      expect(SyncStatus.error.label, equals('Error'));
    });

    test('conflict status returns correct label', () {
      expect(SyncStatus.conflict.label, equals('Conflict'));
    });

    test('cloudOnly status returns correct label', () {
      expect(SyncStatus.cloudOnly.label, equals('Cloud Only'));
    });

    test('localOnly status returns correct label', () {
      expect(SyncStatus.localOnly.label, equals('Local Only'));
    });
  });

  group('SyncStatusDisplay extension - statusMessage property', () {
    test('synced status returns descriptive message', () {
      final String message = SyncStatus.synced.statusMessage;
      expect(message, contains('synced'));
      expect(message, contains('automatically'));
    });

    test('pending status returns descriptive message', () {
      final String message = SyncStatus.pending.statusMessage;
      expect(message, contains('queued'));
    });

    test('syncing status returns descriptive message', () {
      final String message = SyncStatus.syncing.statusMessage;
      expect(message, contains('Syncing'));
    });

    test('error status returns descriptive message', () {
      final String message = SyncStatus.error.statusMessage;
      expect(message, contains('failed'));
      expect(message, contains('retry'));
    });

    test('conflict status returns descriptive message', () {
      final String message = SyncStatus.conflict.statusMessage;
      expect(message, contains('Local'));
      expect(message, contains('cloud'));
      expect(message, contains('differ'));
    });

    test('cloudOnly status returns descriptive message', () {
      final String message = SyncStatus.cloudOnly.statusMessage;
      expect(message, contains('cloud'));
      expect(message, contains('download'));
    });

    test('localOnly status returns descriptive message', () {
      final String message = SyncStatus.localOnly.statusMessage;
      expect(message, contains('local'));
      expect(message, contains('won\'t sync'));
    });
  });
}
