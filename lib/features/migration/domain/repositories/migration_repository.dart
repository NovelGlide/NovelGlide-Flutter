import '../entities/migration_context.dart';
import '../entities/migration_scenario.dart';
import '../entities/migration_state.dart';

/// Abstract repository interface for the library migration feature.
///
/// This defines the contract for all migration operations, from checking
/// if migration is needed to executing each of the 9 migration steps.
///
/// All methods must handle errors gracefully and provide meaningful
/// error messages for debugging and user reporting.
abstract class MigrationRepository {
  /// Checks if a migration is required.
  ///
  /// Returns true if:
  /// - [migration_v1.done] marker file does NOT exist, AND
  /// - Either old Library/ folder OR Library.zip on Drive exists
  ///
  /// Returns false if migration marker file exists (already migrated).
  ///
  /// Throws exception on file system errors.
  Future<bool> isMigrationNeeded();

  /// Marks the migration as complete.
  ///
  /// Writes the [migration_v1.done] marker file to the Data directory.
  /// This prevents the migration wizard from running again on future
  /// launches.
  ///
  /// Throws exception on file system errors.
  Future<void> markMigrationComplete();

  /// Detects the migration scenario based on current app state.
  ///
  /// Checks for:
  /// - Local Library/ folder exists
  /// - Library.zip exists on Google Drive
  ///
  /// Returns:
  /// - [MigrationScenario.localAndCloud] if both exist
  /// - [MigrationScenario.localOnly] if only local exists
  /// - [MigrationScenario.cloudOnly] if only cloud backup exists
  /// - [MigrationScenario.none] if neither exists
  ///
  /// Throws exception on file system or network errors.
  Future<MigrationScenario> detectScenario();

  /// Gets the current deferral count from persistent storage.
  ///
  /// The deferral system allows users to postpone migration up to 3 times.
  /// After 3 deferrals, the "Remind me later" button is hidden and
  /// migration must complete.
  ///
  /// Returns: 0-3 (or higher if user manually edited prefs)
  Future<int> getDeferralCount();

  /// Increments the deferral count in persistent storage.
  ///
  /// Called when user chooses "Remind me later" on the introduction
  /// screen. Once this reaches 3, the deferral button is hidden and
  /// migration is forced to complete on next launch.
  ///
  /// Returns: New deferral count after increment
  Future<int> incrementDeferralCount();

  /// Resets the deferral count to 0.
  ///
  /// Called after successful migration completion to reset the counter
  /// for future feature migrations.
  Future<void> resetDeferralCount();

  /// Loads the last saved migration state from persistent storage.
  ///
  /// Returns null if no prior migration state exists (fresh start).
  /// Otherwise returns the complete state including current step,
  /// books processed so far, mappings, and skipped books.
  ///
  /// Used for resuming interrupted migrations.
  ///
  /// Throws exception on file system or JSON parse errors.
  Future<MigrationState?> getLastMigrationState();

  /// Saves migration state to persistent storage.
  ///
  /// Called after each major step or book processed to enable resumption
  /// from last successful checkpoint if migration is interrupted.
  ///
  /// Writes to Data/migration_state.json with full serialization.
  ///
  /// Throws exception on file system errors.
  Future<void> saveMigrationState(MigrationState state);

  /// Deletes the migration state file.
  ///
  /// Called at the very end of migration (step 9) to clean up
  /// after marking complete. Prevents resumption attempts.
  ///
  /// Safe to call if file doesn't exist (no-op).
  Future<void> deleteMigrationState();

  // ===== MIGRATION STEPS (1-9) =====

  /// **Step 1: Download Cloud Backup**
  ///
  /// If [context.scenario] is [MigrationScenario.localAndCloud] or
  /// [MigrationScenario.cloudOnly]:
  /// - Download Library.zip from Google Drive
  /// - Extract to [context.tempExtractionPath] using temp directory
  /// - Parse extracted EPUB filenames and store in [MigrationState.downloadedBooks]
  ///
  /// If scenario is [MigrationScenario.localOnly] or [MigrationScenario.none]:
  /// - Skip this step (no cloud backup to download)
  ///
  /// On network error:
  /// - Throw exception (allows retry via UI "Retry" button)
  /// - Do NOT modify state on failure
  ///
  /// On success:
  /// - Update [state] with downloaded books list
  /// - Call [saveState] to persist progress
  ///
  /// [state]: Current migration state, updated on success
  /// [context]: Shared migration context
  /// [saveState]: Callback to save state after step completes
  ///
  /// Throws: NetworkException on download failure, FileSystemException
  /// on extraction failure, FormatException on corrupt zip
  Future<void> downloadCloudBackup(
    MigrationState state,
    MigrationContext context,
    Future<void> Function(MigrationState) saveState,
  );

  /// **Step 2: Enumerate Books**
  ///
  /// Build a unified list of all books from local and cloud sources:
  /// - List all .epub files in local Library/ folder → [localBooks]
  /// - Extract .epub filenames from downloaded zip folder
  ///   (if zip was downloaded)
  /// - Deduplicate by filename (local copy preferred if duplicate)
  /// - Count total unique books
  ///
  /// If both local and cloud contain the same filename:
  /// - Keep local copy (may have more recent reading state)
  /// - Discard cloud copy
  ///
  /// Update [state] with:
  /// - [downloadedBooks]: Filenames from zip (if applicable)
  /// - [localBooks]: Filenames from local Library/
  /// - [totalBooks]: Total unique count after deduplication
  ///
  /// Call [saveState] to persist enumeration results.
  ///
  /// Throws: FileSystemException on read errors, FormatException
  /// on invalid EPUB file structure
  Future<void> enumerateBooks(
    MigrationState state,
    MigrationContext context,
    Future<void> Function(MigrationState) saveState,
  );

  /// **Step 3: Build New Folder Structure**
  ///
  /// For each unique book filename from step 2:
  /// 1. Generate a new BookId (UUID v4)
  /// 2. Create Library/{bookId}/ directory
  /// 3. Copy or move EPUB to Library/{bookId}/book.epub
  ///    (from local Library/ or extracted zip, local preferred)
  /// 4. Extract book title from EPUB metadata (fall back to filename)
  /// 5. Read reading state from Cache/locations/{filename}.tmp
  ///    (contains CFI and position)
  /// 6. Find bookmarks in old bookmark.json for this filename:
  ///    - If bookmark has [startCfi]: use as-is for position
  ///    - Else if has [chapterIdentifier]: build chapter-level position
  ///    - Use [savedTime] as createdAt
  ///    - Use [bookName] as label
  ///    - Set type="manual" (user bookmarks, not auto-bookmarks)
  /// 7. Write Library/{bookId}/metadata.json with:
  ///    - title, originalFileName, createdAt
  ///    - reading state (currentPosition, progress)
  ///    - bookmark entries
  /// 8. Record originalFileName → BookId mapping
  ///    (used in step 4 to update collections)
  ///
  /// On error per-book (corrupt EPUB, unreadable metadata, etc):
  /// - Log the error
  /// - Add to [skippedBooks] with reason
  /// - Continue with next book (don't crash)
  ///
  /// After each book:
  /// - Increment [processedBooks]
  /// - Call [saveState] to persist checkpoint
  ///
  /// After all books:
  /// - Final [saveState] call
  ///
  /// Throws: FileSystemException for I/O errors,
  /// but recovers gracefully for individual book failures
  Future<void> buildNewFolderStructure(
    MigrationState state,
    MigrationContext context,
    Future<void> Function(MigrationState) saveState,
  );

  /// **Step 4: Migrate Collections**
  ///
  /// Update collections to reference BookIds instead of filenames:
  /// 1. Load old collection.json
  /// 2. For each collection:
  ///    - For each filename in [pathList]:
  ///      - Look up in [fileNameToBookId] mapping
  ///      - If found: replace with BookId
  ///      - If not found (skipped book): silently remove from collection
  ///    - Rename field: [pathList] → [bookIds]
  ///    - Preserve collection name and other fields
  /// 3. Write updated collection.json
  /// 4. Update [state] and call [saveState]
  ///
  /// Safe to handle missing collection.json (new install case).
  /// In that case, create new empty collections.json.
  ///
  /// Throws: FileSystemException on file errors,
  /// FormatException on JSON parse errors
  Future<void> migrateCollections(
    MigrationState state,
    MigrationContext context,
    Future<void> Function(MigrationState) saveState,
  );

  /// **Step 5: Clear Superseded Data**
  ///
  /// Delete all old data structures that are no longer needed:
  /// 1. Delete all .tmp files in Cache/locations/
  /// 2. Delete or clear bookmark.json (old flat bookmarks)
  /// 3. Delete temp extraction directory (if created in step 1)
  /// 4. Update [state] and call [saveState]
  ///
  /// Safe to handle missing files/directories (some may not exist).
  ///
  /// Throws: FileSystemException on critical deletion errors,
  /// but logs and continues on non-critical failures
  Future<void> clearSupersededData(
    MigrationState state,
    MigrationContext context,
    Future<void> Function(MigrationState) saveState,
  );

  /// **Step 6: Rebuild Bookmark Cache**
  ///
  /// Rebuild the bookmark cache from all book metadata files:
  /// 1. Call BookmarkRebuildCacheUseCase to rebuild cache
  /// 2. This walks all Library/{bookId}/metadata.json files
  /// 3. Creates bookmark_cache.json with consolidated index
  /// 4. At this point all bookmarks are in metadata.json files,
  ///    bookmark_cache.json will initially be empty or minimal
  /// 5. Update [state] and call [saveState]
  ///
  /// This ensures cache file exists and is valid for app usage.
  ///
  /// Throws: FileSystemException on file errors,
  /// but cache rebuilding should be robust and handle edge cases
  Future<void> rebuildBookmarkCache(
    MigrationState state,
    MigrationContext context,
    Future<void> Function(MigrationState) saveState,
  );

  /// **Step 7: Rename Cloud Backup**
  ///
  /// Archive the original Library.zip on Google Drive:
  /// - If [context.scenario] is [MigrationScenario.localAndCloud] or
  ///   [MigrationScenario.cloudOnly]:
  ///   - Find Library.zip on Google Drive
  ///   - Rename to Library.zip.bak
  ///   - Do NOT delete (preserve as safety net)
  /// - If scenario is [MigrationScenario.localOnly] or [MigrationScenario.none]:
  ///   - Skip (no zip to rename)
  /// - Update [state] and call [saveState]
  ///
  /// On network error:
  /// - Throw exception (allows retry)
  /// - Do NOT modify state on failure
  ///
  /// Throws: NetworkException on Drive API errors,
  /// FileNotFoundException if zip doesn't exist (shouldn't happen,
  /// but handle gracefully)
  Future<void> renameCloudBackup(
    MigrationState state,
    MigrationContext context,
    Future<void> Function(MigrationState) saveState,
  );

  /// **Step 8: Enable Cloud Sync**
  ///
  /// Start uploading migrated books to Google Drive:
  /// - If user is signed into Google Drive:
  ///   - Trigger CloudIndexRepository to create index.json
  ///   - For each book in Library/{bookId}/:
  ///     - Upload book.epub to Drive at books/{bookId}/book.epub
  ///     - Upload metadata.json to Drive at books/{bookId}/metadata.json
  ///     - Create IndexEntry mapping bookId ↔ cloudFileId
  ///   - This runs in BACKGROUND (don't wait for completion)
  ///   - App becomes usable after step 7
  /// - If user NOT signed in:
  ///   - Skip (can re-sync manually from settings)
  /// - Update [state] and call [saveState]
  ///
  /// Important: Do NOT block migration completion on cloud upload.
  /// Return immediately after triggering background task.
  ///
  /// Throws: Rare FileSystemException only; network errors
  /// are handled in background task
  Future<void> enableCloudSync(
    MigrationState state,
    MigrationContext context,
    Future<void> Function(MigrationState) saveState,
  );
}
