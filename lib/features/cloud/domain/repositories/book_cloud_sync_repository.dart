/// Sync status for a single book.
///
/// Indicates the current synchronization state between local and cloud.
enum SyncStatus {
  /// Book is fully synced between local and cloud.
  synced,

  /// Book has pending changes waiting to sync.
  pending,

  /// Book is currently syncing (upload or download in progress).
  syncing,

  /// Sync failed with an error (will retry automatically).
  error,

  /// Local and cloud versions have conflicting changes.
  conflict,

  /// Book exists only in cloud (not downloaded locally yet).
  cloudOnly,

  /// Book exists only locally (not synced to cloud).
  localOnly,
}

/// Repository interface for per-book cloud synchronization.
///
/// Handles sync operations for individual books, including upload,
/// download, change detection, conflict handling, and local eviction.
/// Works with BookCloudSyncRepository for metadata sync and
/// CloudIndexRepository for registry updates.
abstract class BookCloudSyncRepository {
  /// Synchronizes all aspects of a book (EPUB + metadata).
  ///
  /// Detects local changes via hash comparison and syncs only what's
  /// needed. Updates the index with current sync status. Handles conflicts
  /// deterministically (see conflict detection below).
  ///
  /// Conflict detection:
  /// - Local EPUB hash != index.localFileHash: local file changed
  /// - Cloud metadata newer (lastReadTime): other device made changes
  /// - Sets status to "conflict" when detected
  ///
  /// Parameters:
  ///   bookId: The stable UUID of the book to sync.
  ///
  /// Throws: Never throws. Errors are logged internally.
  Future<void> syncBook(String bookId);

  /// Syncs only the metadata for a book.
  ///
  /// Useful for fast updates without syncing the large EPUB file.
  /// Updates reading state and bookmarks independently from the EPUB.
  ///
  /// Parameters:
  ///   bookId: The stable UUID of the book.
  ///
  /// Throws: Never throws. Errors are logged internally.
  Future<void> syncMetadata(String bookId);

  /// Downloads a book from cloud to local storage.
  ///
  /// Retrieves both EPUB and metadata from cloud. Useful for
  /// syncing books from other devices or recovering deleted local copies.
  ///
  /// Parameters:
  ///   bookId: The stable UUID of the book to download.
  ///
  /// Throws: Never throws. Errors are logged internally.
  Future<void> downloadBook(String bookId);

  /// Uploads a book to cloud storage.
  ///
  /// Uploads both EPUB and metadata. Skips EPUB if hash hasn't changed.
  /// Updates the index entry with new file IDs and hashes.
  ///
  /// Parameters:
  ///   bookId: The stable UUID of the book to upload.
  ///
  /// Throws: Never throws. Errors are logged internally.
  Future<void> uploadBook(String bookId);

  /// Deletes the local copy of a book while keeping cloud version.
  ///
  /// Useful for freeing local storage while preserving cloud backup.
  /// The book can be re-downloaded later.
  ///
  /// Parameters:
  ///   bookId: The stable UUID of the book to evict.
  ///
  /// Throws: Never throws. Errors are logged internally.
  Future<void> evictLocalCopy(String bookId);

  /// Gets the current sync status of a book.
  ///
  /// Returns the detailed sync state (synced, pending, syncing, error, etc).
  /// Useful for UI display and determining if user intervention is needed.
  ///
  /// Parameters:
  ///   bookId: The stable UUID of the book.
  ///
  /// Returns: The current SyncStatus of the book.
  Future<SyncStatus> getSyncStatus(String bookId);
}
