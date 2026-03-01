/// Enum representing each step in the migration process.
///
/// The migration wizard executes these steps sequentially:
/// 1. [downloadCloudBackup] - Download Library.zip from Google Drive
/// 2. [enumerateBooks] - List all books from local + cloud sources
/// 3. [buildNewFolderStructure] - Create new BookId-based folders
/// 4. [migrateCollections] - Update collection references to BookIds
/// 5. [clearSupersededData] - Delete old data files
/// 6. [rebuildBookmarkCache] - Rebuild bookmark cache from metadata
/// 7. [renameCloudBackup] - Archive old Library.zip on Drive
/// 8. [enableCloudSync] - Upload migrated books to cloud
/// 9. [markComplete] - Write migration completion marker
enum MigrationStep {
  /// Download Library.zip backup from Google Drive to temp location.
  downloadCloudBackup,

  /// Enumerate all books from local Library/ and downloaded zip.
  enumerateBooks,

  /// Build new Library/{bookId}/ folder structure with metadata.
  buildNewFolderStructure,

  /// Update collection.json to reference BookIds instead of filenames.
  migrateCollections,

  /// Delete old .tmp files, bookmark.json, and temp extraction folder.
  clearSupersededData,

  /// Rebuild bookmark_cache.json from all book metadata files.
  rebuildBookmarkCache,

  /// Rename Library.zip to Library.zip.bak on Google Drive.
  renameCloudBackup,

  /// Enable cloud sync by uploading all books to Drive in background.
  enableCloudSync,

  /// Mark migration as complete and delete state file.
  markComplete,
}
