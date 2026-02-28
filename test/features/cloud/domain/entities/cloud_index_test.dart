import 'package:flutter_test/flutter_test.dart';
import 'package:novel_glide/features/cloud/domain/entities/cloud_index.dart';
import 'package:novel_glide/features/cloud/domain/entities/index_entry.dart';
import 'package:novel_glide/features/cloud/domain/entities/sync_status.dart';

void main() {
  group('CloudIndex immutability and equality', () {
    late CloudIndex index1;
    late CloudIndex index2;

    setUp(() {
      final DateTime now = DateTime.now();
      index1 = CloudIndex(
        version: 1,
        lastUpdatedAt: now,
        books: <IndexEntry>[],
      );

      index2 = CloudIndex(
        version: 1,
        lastUpdatedAt: now,
        books: <IndexEntry>[],
      );
    });

    test('identical empty indices are equal', () {
      expect(index1, equals(index2));
    });

    test('indices with different versions are not equal', () {
      final CloudIndex different = index1.copyWith(version: 2);
      expect(index1, isNot(equals(different)));
    });

    test('copyWith creates new instance', () {
      final CloudIndex copy = index1.copyWith();
      expect(copy, equals(index1));
      expect(identical(copy, index1), false);
    });
  });

  group('CloudIndex JSON serialization', () {
    late CloudIndex index;
    late DateTime updateTime;

    setUp(() {
      updateTime = DateTime(2026, 3, 1, 10, 30, 0);
      index = CloudIndex(
        version: 1,
        lastUpdatedAt: updateTime,
        books: <IndexEntry>[],
      );
    });

    test('empty index can be serialized to JSON', () {
      final Map<String, dynamic> json = index.toJson();
      expect(json, isA<Map<String, dynamic>>());
      expect(json.containsKey('version'), true);
      expect(json.containsKey('lastUpdatedAt'), true);
      expect(json.containsKey('books'), true);
    });

    test('empty index can be deserialized from JSON', () {
      final Map<String, dynamic> json = index.toJson();
      final CloudIndex deserialized = CloudIndex.fromJson(json);
      expect(deserialized, equals(index));
    });

    test('round-trip serialization preserves all fields', () {
      final Map<String, dynamic> json = index.toJson();
      final CloudIndex restored = CloudIndex.fromJson(json);

      expect(restored.version, equals(index.version));
      expect(restored.lastUpdatedAt, equals(index.lastUpdatedAt));
      expect(restored.books, equals(index.books));
    });

    test('index with entries can be serialized and deserialized', () {
      final DateTime syncTime = DateTime(2026, 3, 1, 9, 0, 0);
      final IndexEntry entry = IndexEntry(
        bookId: 'book-uuid-1',
        fileName: 'test.epub',
        cloudFileId: 'cloud-id',
        metadataCloudFileId: 'metadata-id',
        localFileHash: 'hash',
        lastSyncedAt: syncTime,
        syncStatus: SyncStatus.synced,
        deletedAt: null,
      );

      final CloudIndex indexWithEntry = CloudIndex(
        version: 1,
        lastUpdatedAt: updateTime,
        books: <IndexEntry>[entry],
      );

      final Map<String, dynamic> json = indexWithEntry.toJson();
      final CloudIndex restored = CloudIndex.fromJson(json);

      expect(restored.books, hasLength(1));
      expect(restored.books[0], equals(entry));
    });
  });

  group('CloudIndex entry lookup (getEntry)', () {
    late CloudIndex index;
    late IndexEntry entry1;
    late IndexEntry entry2;

    setUp(() {
      final DateTime now = DateTime.now();
      entry1 = IndexEntry(
        bookId: 'book-uuid-1',
        fileName: 'book1.epub',
        cloudFileId: 'cloud-id-1',
        metadataCloudFileId: 'metadata-id-1',
        localFileHash: 'hash1',
        lastSyncedAt: now,
        syncStatus: SyncStatus.synced,
        deletedAt: null,
      );

      entry2 = IndexEntry(
        bookId: 'book-uuid-2',
        fileName: 'book2.epub',
        cloudFileId: 'cloud-id-2',
        metadataCloudFileId: 'metadata-id-2',
        localFileHash: 'hash2',
        lastSyncedAt: now,
        syncStatus: SyncStatus.synced,
        deletedAt: null,
      );

      index = CloudIndex(
        version: 1,
        lastUpdatedAt: now,
        books: <IndexEntry>[entry1, entry2],
      );
    });

    test('getEntry returns entry by bookId', () {
      final IndexEntry? found = index.getEntry('book-uuid-1');
      expect(found, equals(entry1));
    });

    test('getEntry returns null for non-existent bookId', () {
      final IndexEntry? found = index.getEntry('non-existent');
      expect(found, isNull);
    });

    test('getEntry returns null for deleted entry', () {
      final CloudIndex indexWithDeleted = index.copyWith(
        books: <IndexEntry>[
          entry1,
          entry2.copyWith(deletedAt: DateTime.now()),
        ],
      );
      final IndexEntry? found = indexWithDeleted.getEntry('book-uuid-2');
      expect(found, isNull);
    });

    test('getEntry works on empty index', () {
      final CloudIndex emptyIndex = CloudIndex(
        version: 1,
        lastUpdatedAt: DateTime.now(),
        books: <IndexEntry>[],
      );
      final IndexEntry? found = emptyIndex.getEntry('any-id');
      expect(found, isNull);
    });
  });

  group('CloudIndex entry updates (updateEntry)', () {
    late CloudIndex index;
    late IndexEntry entry1;

    setUp(() {
      final DateTime now = DateTime.now();
      entry1 = IndexEntry(
        bookId: 'book-uuid-1',
        fileName: 'book1.epub',
        cloudFileId: 'cloud-id-1',
        metadataCloudFileId: 'metadata-id-1',
        localFileHash: 'hash1',
        lastSyncedAt: now,
        syncStatus: SyncStatus.synced,
        deletedAt: null,
      );

      index = CloudIndex(
        version: 1,
        lastUpdatedAt: now,
        books: <IndexEntry>[entry1],
      );
    });

    test('updateEntry adds new entry to index', () {
      final DateTime now = DateTime.now();
      final IndexEntry newEntry = IndexEntry(
        bookId: 'book-uuid-2',
        fileName: 'book2.epub',
        cloudFileId: 'cloud-id-2',
        metadataCloudFileId: 'metadata-id-2',
        localFileHash: 'hash2',
        lastSyncedAt: now,
        syncStatus: SyncStatus.synced,
        deletedAt: null,
      );

      final CloudIndex updated = index.updateEntry(newEntry);
      expect(updated.books, hasLength(2));
      expect(updated.getEntry('book-uuid-2'), equals(newEntry));
    });

    test('updateEntry replaces existing entry', () {
      final IndexEntry updated = entry1.copyWith(
        syncStatus: SyncStatus.pending,
      );

      final CloudIndex indexUpdated = index.updateEntry(updated);
      expect(indexUpdated.books, hasLength(1));
      expect(indexUpdated.getEntry('book-uuid-1'), equals(updated));
      expect(indexUpdated.getEntry('book-uuid-1')?.syncStatus,
          equals(SyncStatus.pending));
    });

    test('updateEntry updates lastUpdatedAt', () {
      final DateTime beforeUpdate = index.lastUpdatedAt;
      final IndexEntry updated = entry1.copyWith(
        syncStatus: SyncStatus.pending,
      );
      final CloudIndex indexUpdated = index.updateEntry(updated);

      expect(indexUpdated.lastUpdatedAt.isAfter(beforeUpdate), true);
    });

    test('updateEntry does not modify original index', () {
      final IndexEntry newEntry = IndexEntry(
        bookId: 'book-uuid-2',
        fileName: 'book2.epub',
        cloudFileId: 'cloud-id-2',
        metadataCloudFileId: 'metadata-id-2',
        localFileHash: 'hash2',
        lastSyncedAt: DateTime.now(),
        syncStatus: SyncStatus.synced,
        deletedAt: null,
      );

      final CloudIndex updated = index.updateEntry(newEntry);
      expect(index.books, hasLength(1));
      expect(updated.books, hasLength(2));
    });
  });

  group('CloudIndex soft deletion (removeBook)', () {
    late CloudIndex index;
    late IndexEntry entry1;

    setUp(() {
      final DateTime now = DateTime.now();
      entry1 = IndexEntry(
        bookId: 'book-uuid-1',
        fileName: 'book1.epub',
        cloudFileId: 'cloud-id-1',
        metadataCloudFileId: 'metadata-id-1',
        localFileHash: 'hash1',
        lastSyncedAt: now,
        syncStatus: SyncStatus.synced,
        deletedAt: null,
      );

      index = CloudIndex(
        version: 1,
        lastUpdatedAt: now,
        books: <IndexEntry>[entry1],
      );
    });

    test('removeBook sets deletedAt timestamp', () {
      final CloudIndex removed = index.removeBook('book-uuid-1');
      final IndexEntry? entry = removed.books.firstWhere(
        (IndexEntry e) => e.bookId == 'book-uuid-1',
      );
      expect(entry?.deletedAt, isNotNull);
    });

    test('removeBook does not hard-delete entry', () {
      final CloudIndex removed = index.removeBook('book-uuid-1');
      expect(removed.books, hasLength(1));
    });

    test('removeBook makes entry inaccessible via getEntry', () {
      final CloudIndex removed = index.removeBook('book-uuid-1');
      final IndexEntry? found = removed.getEntry('book-uuid-1');
      expect(found, isNull);
    });

    test('removeBook returns unchanged index for non-existent bookId', () {
      final CloudIndex unchanged = index.removeBook('non-existent');
      expect(unchanged, equals(index));
    });

    test('removeBook does not modify original index', () {
      final CloudIndex removed = index.removeBook('book-uuid-1');
      expect(index.getEntry('book-uuid-1'), isNotNull);
      expect(removed.getEntry('book-uuid-1'), isNull);
    });
  });

  group('CloudIndex merge (mergeTwoVersions)', () {
    test('merge combines entries from both indices', () {
      final DateTime time1 = DateTime(2026, 3, 1, 9, 0, 0);
      final DateTime time2 = DateTime(2026, 3, 1, 10, 0, 0);

      final IndexEntry entry1 = IndexEntry(
        bookId: 'book-1',
        fileName: 'book1.epub',
        cloudFileId: 'cloud-1',
        metadataCloudFileId: 'metadata-1',
        localFileHash: 'hash1',
        lastSyncedAt: time1,
        syncStatus: SyncStatus.synced,
        deletedAt: null,
      );

      final IndexEntry entry2 = IndexEntry(
        bookId: 'book-2',
        fileName: 'book2.epub',
        cloudFileId: 'cloud-2',
        metadataCloudFileId: 'metadata-2',
        localFileHash: 'hash2',
        lastSyncedAt: time1,
        syncStatus: SyncStatus.synced,
        deletedAt: null,
      );

      final CloudIndex local = CloudIndex(
        version: 1,
        lastUpdatedAt: time1,
        books: <IndexEntry>[entry1],
      );

      final CloudIndex cloud = CloudIndex(
        version: 1,
        lastUpdatedAt: time2,
        books: <IndexEntry>[entry2],
      );

      final CloudIndex merged = local.mergeTwoVersions(cloud);
      expect(merged.books, hasLength(2));
      expect(merged.getEntry('book-1'), isNotNull);
      expect(merged.getEntry('book-2'), isNotNull);
    });

    test('merge uses newer lastSyncedAt to resolve conflicts', () {
      final DateTime olderTime = DateTime(2026, 3, 1, 9, 0, 0);
      final DateTime newerTime = DateTime(2026, 3, 1, 10, 0, 0);

      final IndexEntry olderEntry = IndexEntry(
        bookId: 'book-1',
        fileName: 'old_name.epub',
        cloudFileId: 'old-cloud-id',
        metadataCloudFileId: 'old-metadata-id',
        localFileHash: 'old-hash',
        lastSyncedAt: olderTime,
        syncStatus: SyncStatus.synced,
        deletedAt: null,
      );

      final IndexEntry newerEntry = IndexEntry(
        bookId: 'book-1',
        fileName: 'new_name.epub',
        cloudFileId: 'new-cloud-id',
        metadataCloudFileId: 'new-metadata-id',
        localFileHash: 'new-hash',
        lastSyncedAt: newerTime,
        syncStatus: SyncStatus.synced,
        deletedAt: null,
      );

      final CloudIndex local = CloudIndex(
        version: 1,
        lastUpdatedAt: olderTime,
        books: <IndexEntry>[olderEntry],
      );

      final CloudIndex cloud = CloudIndex(
        version: 1,
        lastUpdatedAt: newerTime,
        books: <IndexEntry>[newerEntry],
      );

      final CloudIndex merged = local.mergeTwoVersions(cloud);
      final IndexEntry? result = merged.getEntry('book-1');
      expect(result?.fileName, equals('new_name.epub'));
      expect(result?.lastSyncedAt, equals(newerTime));
    });

    test('merge preserves deleted entries', () {
      final DateTime time1 = DateTime(2026, 3, 1, 9, 0, 0);
      final DateTime time2 = DateTime(2026, 3, 1, 10, 0, 0);
      final DateTime deleteTime = DateTime(2026, 3, 1, 8, 0, 0);

      final IndexEntry deletedEntry = IndexEntry(
        bookId: 'book-1',
        fileName: 'book1.epub',
        cloudFileId: 'cloud-1',
        metadataCloudFileId: 'metadata-1',
        localFileHash: 'hash1',
        lastSyncedAt: deleteTime,
        syncStatus: SyncStatus.synced,
        deletedAt: deleteTime,
      );

      final IndexEntry activeEntry = IndexEntry(
        bookId: 'book-2',
        fileName: 'book2.epub',
        cloudFileId: 'cloud-2',
        metadataCloudFileId: 'metadata-2',
        localFileHash: 'hash2',
        lastSyncedAt: time1,
        syncStatus: SyncStatus.synced,
        deletedAt: null,
      );

      final CloudIndex local = CloudIndex(
        version: 1,
        lastUpdatedAt: time1,
        books: <IndexEntry>[deletedEntry],
      );

      final CloudIndex cloud = CloudIndex(
        version: 1,
        lastUpdatedAt: time2,
        books: <IndexEntry>[activeEntry],
      );

      final CloudIndex merged = local.mergeTwoVersions(cloud);
      expect(merged.books, hasLength(2));
      expect(merged.getEntry('book-1'), isNull);
      expect(merged.getEntry('book-2'), isNotNull);
    });

    test('merge updates schema version to max', () {
      final DateTime now = DateTime.now();
      final CloudIndex local = CloudIndex(
        version: 2,
        lastUpdatedAt: now,
        books: <IndexEntry>[],
      );

      final CloudIndex cloud = CloudIndex(
        version: 3,
        lastUpdatedAt: now,
        books: <IndexEntry>[],
      );

      final CloudIndex merged = local.mergeTwoVersions(cloud);
      expect(merged.version, equals(3));
    });

    test('merge is deterministic', () {
      final DateTime time1 = DateTime(2026, 3, 1, 9, 0, 0);
      final DateTime time2 = DateTime(2026, 3, 1, 10, 0, 0);

      final IndexEntry entry1 = IndexEntry(
        bookId: 'book-1',
        fileName: 'book1.epub',
        cloudFileId: 'cloud-1',
        metadataCloudFileId: 'metadata-1',
        localFileHash: 'hash1',
        lastSyncedAt: time1,
        syncStatus: SyncStatus.synced,
        deletedAt: null,
      );

      final CloudIndex local = CloudIndex(
        version: 1,
        lastUpdatedAt: time1,
        books: <IndexEntry>[entry1],
      );

      final CloudIndex cloud = CloudIndex(
        version: 1,
        lastUpdatedAt: time2,
        books: <IndexEntry>[entry1],
      );

      final CloudIndex merge1 = local.mergeTwoVersions(cloud);
      final CloudIndex merge2 = local.mergeTwoVersions(cloud);

      expect(merge1, equals(merge2));
      expect(merge1.books.length, equals(merge2.books.length));
    });
  });

  group('CloudIndex edge cases', () {
    test('empty index can be merged', () {
      final DateTime now = DateTime.now();
      final CloudIndex empty1 = CloudIndex(
        version: 1,
        lastUpdatedAt: now,
        books: <IndexEntry>[],
      );

      final CloudIndex empty2 = CloudIndex(
        version: 1,
        lastUpdatedAt: now,
        books: <IndexEntry>[],
      );

      final CloudIndex merged = empty1.mergeTwoVersions(empty2);
      expect(merged.books, isEmpty);
    });

    test('duplicate bookIds in same index use latest entry', () {
      final DateTime time1 = DateTime(2026, 3, 1, 9, 0, 0);
      final DateTime time2 = DateTime(2026, 3, 1, 10, 0, 0);

      final IndexEntry older = IndexEntry(
        bookId: 'book-1',
        fileName: 'old.epub',
        cloudFileId: 'old-cloud',
        metadataCloudFileId: 'old-metadata',
        localFileHash: 'old-hash',
        lastSyncedAt: time1,
        syncStatus: SyncStatus.synced,
        deletedAt: null,
      );

      final IndexEntry newer = IndexEntry(
        bookId: 'book-1',
        fileName: 'new.epub',
        cloudFileId: 'new-cloud',
        metadataCloudFileId: 'new-metadata',
        localFileHash: 'new-hash',
        lastSyncedAt: time2,
        syncStatus: SyncStatus.synced,
        deletedAt: null,
      );

      final CloudIndex local = CloudIndex(
        version: 1,
        lastUpdatedAt: time1,
        books: <IndexEntry>[older],
      );

      final CloudIndex cloud = CloudIndex(
        version: 1,
        lastUpdatedAt: time2,
        books: <IndexEntry>[newer],
      );

      final CloudIndex merged = local.mergeTwoVersions(cloud);
      final IndexEntry? result = merged.getEntry('book-1');
      expect(result?.localFileHash, equals('new-hash'));
    });
  });
}
