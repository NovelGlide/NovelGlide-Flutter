import 'package:flutter_test/flutter_test.dart';
import 'package:novel_glide/features/cloud/domain/entities/index_entry.dart';
import 'package:novel_glide/features/cloud/domain/entities/sync_status.dart';

void main() {
  group('IndexEntry immutability and equality', () {
    late IndexEntry entry1;
    late IndexEntry entry2;

    setUp(() {
      final DateTime now = DateTime.now();
      entry1 = IndexEntry(
        bookId: 'book-uuid-1',
        fileName: 'example.epub',
        cloudFileId: 'google-drive-id-1',
        metadataCloudFileId: 'metadata-id-1',
        localFileHash: 'hash-abc123',
        lastSyncedAt: now,
        syncStatus: SyncStatus.synced,
        deletedAt: null,
      );

      entry2 = IndexEntry(
        bookId: 'book-uuid-1',
        fileName: 'example.epub',
        cloudFileId: 'google-drive-id-1',
        metadataCloudFileId: 'metadata-id-1',
        localFileHash: 'hash-abc123',
        lastSyncedAt: now,
        syncStatus: SyncStatus.synced,
        deletedAt: null,
      );
    });

    test('identical entries are equal', () {
      expect(entry1, equals(entry2));
    });

    test('entries with different bookId are not equal', () {
      final IndexEntry different = entry1.copyWith(
        bookId: 'book-uuid-2',
      );
      expect(entry1, isNot(equals(different)));
    });

    test('entries with different fileName are not equal', () {
      final IndexEntry different = entry1.copyWith(
        fileName: 'different.epub',
      );
      expect(entry1, isNot(equals(different)));
    });

    test('entries with different sync status are not equal', () {
      final IndexEntry different = entry1.copyWith(
        syncStatus: SyncStatus.pending,
      );
      expect(entry1, isNot(equals(different)));
    });

    test('copyWith creates new instance with same values', () {
      final IndexEntry copy = entry1.copyWith();
      expect(copy, equals(entry1));
      expect(identical(copy, entry1), false);
    });

    test('original entry cannot be modified', () {
      // This test verifies immutability - the entry is a value type
      // and should not be modifiable after creation
      final IndexEntry original = entry1;
      final IndexEntry modified = original.copyWith(
        syncStatus: SyncStatus.pending,
      );
      expect(original.syncStatus, equals(SyncStatus.synced));
      expect(modified.syncStatus, equals(SyncStatus.pending));
    });
  });

  group('IndexEntry JSON serialization', () {
    late IndexEntry entry;
    late DateTime syncTime;

    setUp(() {
      syncTime = DateTime(2026, 3, 1, 10, 30, 0);
      entry = IndexEntry(
        bookId: 'book-uuid-1',
        fileName: 'test-book.epub',
        cloudFileId: 'cloud-file-123',
        metadataCloudFileId: 'metadata-file-456',
        localFileHash: 'sha256-hash-value',
        lastSyncedAt: syncTime,
        syncStatus: SyncStatus.synced,
        deletedAt: null,
      );
    });

    test('entry can be serialized to JSON', () {
      final Map<String, dynamic> json = entry.toJson();
      expect(json, isA<Map<String, dynamic>>());
      expect(json.containsKey('bookId'), true);
      expect(json.containsKey('fileName'), true);
      expect(json.containsKey('cloudFileId'), true);
      expect(json.containsKey('metadataCloudFileId'), true);
      expect(json.containsKey('localFileHash'), true);
      expect(json.containsKey('lastSyncedAt'), true);
      expect(json.containsKey('syncStatus'), true);
    });

    test('entry can be deserialized from JSON', () {
      final Map<String, dynamic> json = entry.toJson();
      final IndexEntry deserialized = IndexEntry.fromJson(json);
      expect(deserialized, equals(entry));
    });

    test('round-trip serialization preserves all fields', () {
      final Map<String, dynamic> json = entry.toJson();
      final IndexEntry restored = IndexEntry.fromJson(json);

      expect(restored.bookId, equals(entry.bookId));
      expect(restored.fileName, equals(entry.fileName));
      expect(restored.cloudFileId, equals(entry.cloudFileId));
      expect(restored.metadataCloudFileId, equals(entry.metadataCloudFileId));
      expect(restored.localFileHash, equals(entry.localFileHash));
      expect(restored.lastSyncedAt, equals(entry.lastSyncedAt));
      expect(restored.syncStatus, equals(entry.syncStatus));
      expect(restored.deletedAt, equals(entry.deletedAt));
    });

    test('sync status is correctly serialized', () {
      final Map<String, dynamic> json = entry.toJson();
      expect(json['syncStatus'], equals('synced'));
    });

    test('deletedAt is included in JSON when null', () {
      final Map<String, dynamic> json = entry.toJson();
      expect(json.containsKey('deletedAt'), true);
      expect(json['deletedAt'], isNull);
    });

    test('deletedAt is correctly serialized when set', () {
      final DateTime deleteTime = DateTime(2026, 3, 2, 15, 0, 0);
      final IndexEntry deletedEntry = entry.copyWith(
        deletedAt: deleteTime,
      );
      final Map<String, dynamic> json = deletedEntry.toJson();
      final IndexEntry restored = IndexEntry.fromJson(json);

      expect(restored.deletedAt, isNotNull);
      expect(restored.deletedAt, equals(deleteTime));
    });
  });

  group('IndexEntry tombstone-based deletion', () {
    late IndexEntry entry;

    setUp(() {
      entry = IndexEntry(
        bookId: 'book-uuid-1',
        fileName: 'test.epub',
        cloudFileId: 'cloud-id',
        metadataCloudFileId: 'metadata-id',
        localFileHash: 'hash',
        lastSyncedAt: DateTime.now(),
        syncStatus: SyncStatus.synced,
        deletedAt: null,
      );
    });

    test('active entry has null deletedAt', () {
      expect(entry.deletedAt, isNull);
    });

    test('deleted entry has deletedAt timestamp', () {
      final DateTime deleteTime = DateTime.now();
      final IndexEntry deleted = entry.copyWith(
        deletedAt: deleteTime,
      );
      expect(deleted.deletedAt, equals(deleteTime));
    });

    test('deleted entry retains all other fields', () {
      final DateTime deleteTime = DateTime.now();
      final IndexEntry deleted = entry.copyWith(
        deletedAt: deleteTime,
      );

      expect(deleted.bookId, equals(entry.bookId));
      expect(deleted.fileName, equals(entry.fileName));
      expect(deleted.cloudFileId, equals(entry.cloudFileId));
      expect(deleted.localFileHash, equals(entry.localFileHash));
    });

    test('entry can transition from active to deleted', () {
      expect(entry.deletedAt, isNull);
      final DateTime deleteTime = DateTime.now();
      final IndexEntry deleted = entry.copyWith(
        deletedAt: deleteTime,
      );
      expect(deleted.deletedAt, isNotNull);
    });
  });

  group('IndexEntry edge cases', () {
    test('entry with empty bookId creates valid object', () {
      final IndexEntry entry = IndexEntry(
        bookId: '',
        fileName: 'test.epub',
        cloudFileId: 'cloud-id',
        metadataCloudFileId: 'metadata-id',
        localFileHash: 'hash',
        lastSyncedAt: DateTime.now(),
        syncStatus: SyncStatus.synced,
        deletedAt: null,
      );
      expect(entry.bookId, equals(''));
    });

    test('entry with very long fileName', () {
      final String longName = 'very_' * 100 + 'long_file_name.epub';
      final IndexEntry entry = IndexEntry(
        bookId: 'book-uuid',
        fileName: longName,
        cloudFileId: 'cloud-id',
        metadataCloudFileId: 'metadata-id',
        localFileHash: 'hash',
        lastSyncedAt: DateTime.now(),
        syncStatus: SyncStatus.synced,
        deletedAt: null,
      );
      expect(entry.fileName, equals(longName));
    });

    test('entry with all SyncStatus values creates valid object', () {
      for (final SyncStatus status in SyncStatus.values) {
        final IndexEntry entry = IndexEntry(
          bookId: 'book-uuid',
          fileName: 'test.epub',
          cloudFileId: 'cloud-id',
          metadataCloudFileId: 'metadata-id',
          localFileHash: 'hash',
          lastSyncedAt: DateTime.now(),
          syncStatus: status,
          deletedAt: null,
        );
        expect(entry.syncStatus, equals(status));
      }
    });

    test('null deletedAt is preserved in copyWith', () {
      final IndexEntry entry = IndexEntry(
        bookId: 'book-uuid',
        fileName: 'test.epub',
        cloudFileId: 'cloud-id',
        metadataCloudFileId: 'metadata-id',
        localFileHash: 'hash',
        lastSyncedAt: DateTime.now(),
        syncStatus: SyncStatus.synced,
        deletedAt: null,
      );

      final IndexEntry copy = entry.copyWith(
        syncStatus: SyncStatus.pending,
      );
      expect(copy.deletedAt, isNull);
    });

    test('lastSyncedAt timestamp is precise', () {
      final DateTime precise = DateTime(2026, 3, 1, 10, 30, 45, 123);
      final IndexEntry entry = IndexEntry(
        bookId: 'book-uuid',
        fileName: 'test.epub',
        cloudFileId: 'cloud-id',
        metadataCloudFileId: 'metadata-id',
        localFileHash: 'hash',
        lastSyncedAt: precise,
        syncStatus: SyncStatus.synced,
        deletedAt: null,
      );
      expect(entry.lastSyncedAt, equals(precise));
    });
  });
}
