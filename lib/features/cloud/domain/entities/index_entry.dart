import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:novel_glide/features/cloud/domain/entities/sync_status.dart';

part 'index_entry.freezed.dart';
part 'index_entry.g.dart';

/// A single book entry in the cloud index registry.
///
/// The index entry maps a stable book ID to its cloud location and metadata,
/// enabling reliable synchronization across devices even if local filenames
/// or Google Drive IDs change. Each entry tracks sync status, file hashes,
/// and deletion state (via tombstone pattern).
@freezed
abstract class IndexEntry with _$IndexEntry {
  const factory IndexEntry({
    /// Stable UUID identifying this book across all devices.
    ///
    /// Generated once when the book is first added to the library.
    /// Never changes, even if the local filename or cloud ID changes.
    required String bookId,

    /// Local filename of the EPUB file.
    ///
    /// May change if the book is renamed locally, but bookId remains
    /// the same. Used primarily for display and local file lookup.
    required String fileName,

    /// Google Drive opaque file ID of the uploaded EPUB.
    ///
    /// Provided by Google Drive API during upload. Never changes
    /// once set. Used to identify and download the EPUB from cloud.
    required String cloudFileId,

    /// Google Drive opaque file ID of the metadata JSON for this book.
    ///
    /// Stored separately from the EPUB for granular sync control.
    /// Metadata can be synced independently of the full EPUB file.
    required String metadataCloudFileId,

    /// SHA256 hash of the local EPUB file.
    ///
    /// Used to detect local changes without re-uploading unchanged
    /// files, reducing bandwidth usage. Updated whenever the EPUB
    /// is modified or re-downloaded.
    required String localFileHash,

    /// Timestamp of the last successful sync operation.
    ///
    /// Used to determine which version wins in merge conflicts
    /// (newer timestamp always wins, deterministically).
    required DateTime lastSyncedAt,

    /// Current synchronization status of this book.
    ///
    /// Guides UI display and sync orchestration. Must be checked
    /// before performing sync operations.
    required SyncStatus syncStatus,

    /// Tombstone timestamp marking this book as deleted.
    ///
    /// If null, the book is active. If set to a DateTime, the book
    /// is logically deleted but retained in the index for merge
    /// safety. During merge operations, older deletions are applied,
    /// preserving eventual consistency.
    DateTime? deletedAt,
  }) = _IndexEntry;

  const IndexEntry._();

  factory IndexEntry.fromJson(Map<String, dynamic> json) =>
      _$IndexEntryFromJson(json);
}
