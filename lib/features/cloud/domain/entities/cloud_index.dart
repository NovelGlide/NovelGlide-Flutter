import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:novel_glide/features/cloud/domain/entities/index_entry.dart';

part 'cloud_index.freezed.dart';
part 'cloud_index.g.dart';

/// Converter for serializing/deserializing IndexEntry lists.
class IndexEntryListConverter
    implements JsonConverter<List<IndexEntry>, List<dynamic>> {
  const IndexEntryListConverter();

  @override
  List<IndexEntry> fromJson(List<dynamic> json) {
    return json
        .map((dynamic e) => IndexEntry.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  List<dynamic> toJson(List<IndexEntry> object) {
    return object.map((IndexEntry e) => e.toJson()).toList();
  }
}

/// The complete cloud index registry for all synced books.
///
/// Acts as a centralized registry mapping bookIds to cloud metadata.
/// Stored as index.json in cloud storage and cached locally.
/// Supports deterministic merging for conflict resolution across
/// multiple devices.
@freezed
abstract class CloudIndex with _$CloudIndex {
  const factory CloudIndex({
    /// Schema version for future compatibility.
    ///
    /// Incremented when breaking changes are made to the index format.
    /// Allows graceful handling of incompatible versions.
    required int version,

    /// Timestamp of the last modification to this index.
    ///
    /// Used in merge conflicts: newer index wins if schemas match.
    /// Helps detect stale local copies vs newer cloud versions.
    required DateTime lastUpdatedAt,

    /// List of all book entries in the index.
    ///
    /// May include deleted entries (with deletedAt timestamp set).
    /// Deleted entries are retained for merge safety, not hard-deleted.
    @IndexEntryListConverter() required List<IndexEntry> books,
  }) = _CloudIndex;

  const CloudIndex._();

  factory CloudIndex.fromJson(Map<String, dynamic> json) =>
      _$CloudIndexFromJson(json);

  /// Retrieves a specific book entry by bookId.
  ///
  /// Returns null if the bookId is not found or has been deleted.
  ///
  /// Parameters:
  ///   bookId: The stable UUID of the book to look up.
  ///
  /// Returns:
  ///   The IndexEntry if found and active, null otherwise.
  IndexEntry? getEntry(String bookId) {
    for (final IndexEntry entry in books) {
      if (entry.bookId == bookId && entry.deletedAt == null) {
        return entry;
      }
    }
    return null;
  }

  /// Updates or creates an entry in the index.
  ///
  /// If an entry with the same bookId exists, it is replaced.
  /// Automatically updates [lastUpdatedAt] to now.
  ///
  /// Parameters:
  ///   entry: The IndexEntry to add or update.
  ///
  /// Returns:
  ///   A new CloudIndex with the updated entry.
  CloudIndex updateEntry(IndexEntry entry) {
    final List<IndexEntry> updatedBooks = <IndexEntry>[
      ...books.where((IndexEntry e) => e.bookId != entry.bookId),
      entry,
    ];

    return copyWith(
      books: updatedBooks,
      lastUpdatedAt: DateTime.now(),
    );
  }

  /// Soft-deletes a book from the index.
  ///
  /// Sets the deletedAt timestamp instead of removing the entry.
  /// This preserves the entry for merge safety across devices.
  /// The deleted entry remains in the index but is logically inactive.
  ///
  /// Parameters:
  ///   bookId: The stable UUID of the book to delete.
  ///
  /// Returns:
  ///   A new CloudIndex with the entry marked as deleted.
  ///   Returns unchanged if bookId not found.
  CloudIndex removeBook(String bookId) {
    final IndexEntry? entry = getEntry(bookId);
    if (entry == null) {
      return this;
    }

    return updateEntry(
      entry.copyWith(deletedAt: DateTime.now()),
    );
  }

  /// Deterministic merge of two cloud index versions.
  ///
  /// Resolves conflicts by union of all entries (active and deleted),
  /// with newer [lastSyncedAt] timestamps winning for conflicting
  /// bookIds. This ensures eventual consistency across devices without
  /// user intervention.
  ///
  /// Merge strategy:
  /// 1. Collect all unique bookIds from both indices.
  /// 2. For each bookId, keep the entry with the newer lastSyncedAt.
  /// 3. Preserve deleted entries (with deletedAt timestamps) for safety.
  /// 4. The overall lastUpdatedAt becomes max(local, cloud).
  /// 5. Schema version follows: max(local, cloud).
  ///
  /// Parameters:
  ///   other: The other CloudIndex to merge with.
  ///
  /// Returns:
  ///   A new merged CloudIndex with combined entries.
  CloudIndex mergeTwoVersions(CloudIndex other) {
    // Combine all entries from both indices, keyed by bookId
    final Map<String, IndexEntry> mergedMap = <String, IndexEntry>{};

    for (final IndexEntry entry in books) {
      mergedMap[entry.bookId] = entry;
    }

    for (final IndexEntry otherEntry in other.books) {
      final IndexEntry? existing = mergedMap[otherEntry.bookId];
      if (existing == null ||
          otherEntry.lastSyncedAt.isAfter(existing.lastSyncedAt)) {
        mergedMap[otherEntry.bookId] = otherEntry;
      }
    }

    return CloudIndex(
      version: version > other.version ? version : other.version,
      lastUpdatedAt: lastUpdatedAt.isAfter(other.lastUpdatedAt)
          ? lastUpdatedAt
          : other.lastUpdatedAt,
      books: mergedMap.values.toList(),
    );
  }
}
