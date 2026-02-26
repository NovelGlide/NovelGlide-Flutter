# Cloud Sync Refactor — Implementation Phases

Each phase is **atomic**: it compiles cleanly, all existing tests pass, and the app is fully functional before moving to the next phase. No phase depends on incomplete work from a later phase.

---

## Dependency Order

```
Phase 1 → Phase 2 → Phase 3 → Phase 4 → Phase 5 → Phase 6
```

| Phase | Name                        | Depends On | Breaks Existing Behaviour? |
|-------|-----------------------------|------------|----------------------------|
| 1     | Book Metadata Foundation    | nothing    | No                         |
| 2     | Cloud Index Foundation      | Phase 1    | No                         |
| 3     | Cloud Layer: Folder Support | Phase 2    | No                         |
| 4     | Per-Book Sync Engine        | Phase 3    | No                         |
| 5     | Bookshelf Sync UI           | Phase 4    | No                         |
| 6     | Migration & Zip Retirement  | Phase 5    | Yes — replaces zip backup  |

---

## Phase 1 — Book Metadata Foundation

> Add the per-book metadata system to the `books` feature. The sync and cloud layers are not touched yet. The app behaves identically after this phase — metadata is stored locally but nothing reads it yet.

### What changes

**`lib/features/books/domain/entities/book_sync_status.dart`** — NEW

```dart
enum BookSyncStatus {
  synced,     // local matches cloud
  pending,    // local changes not yet uploaded
  syncing,    // upload/download in progress
  cloudOnly,  // exists on cloud only, not downloaded locally
  conflict,   // both devices diverged
  error,      // last sync failed
  localOnly,  // user opted out of sync
}
```

---

**`lib/features/books/domain/entities/book_metadata.dart`** — NEW

Holds per-book reading state and bookmarks. Stored locally as `<dataPath>/metadata/<bookId>.json`.

```dart
class BookMetadata {
  const BookMetadata({
    required this.bookId,         // stable UUID, the new primary key
    required this.bookmarks,
    this.readingState,
    this.syncStatus = BookSyncStatus.pending,
    this.cloudFileId,
    this.metadataCloudFileId,
    this.localFileHash,
    this.lastSyncedAt,
  });

  final String bookId;
  final ReadingState? readingState;
  final List<BookmarkEntry> bookmarks;
  final BookSyncStatus syncStatus;
  final String? cloudFileId;
  final String? metadataCloudFileId;
  final String? localFileHash;
  final DateTime? lastSyncedAt;
}

// Reading position uses EPUB CFI strings (same format as
// ReaderSetStateData.startCfi already present in the reader feature)
class ReadingState {
  const ReadingState({
    required this.currentPosition,  // EPUB CFI
    required this.progressPercent,
    required this.lastReadAt,
    this.totalReadingSeconds = 0,
  });
}

// Two types share the same structure, distinguished by [type]
// - auto: one per book, silently overwritten on every app close
// - manual: many per book, user-managed, never auto-deleted
class BookmarkEntry {
  const BookmarkEntry({
    required this.id,
    required this.type,       // BookmarkEntryType.auto | .manual
    required this.position,   // EPUB CFI
    required this.createdAt,
    this.label,               // user-set label, manual bookmarks only
  });
}

enum BookmarkEntryType { auto, manual }
```

> **Note on naming:** `BookmarkEntry` avoids collision with the existing `BookmarkData` entity in the `bookmark` feature. The two are separate concerns — `BookmarkData` powers the global Bookmarks tab; `BookmarkEntry` is internal per-book reading state.

---

**`lib/features/books/domain/entities/book.dart`** — MODIFIED

Add `bookId` (stable UUID) alongside the existing `identifier` (filename). Identifier keeps its role for all local file I/O. `syncStatus` is added for future UI use but defaults to `null` (no cloud configured) so no existing widget is affected.

```dart
// BEFORE
class Book extends Equatable {
  const Book({
    required this.identifier,
    required this.title,
    required this.modifiedDate,
    required this.coverIdentifier,
  });
}

// AFTER
class Book extends Equatable {
  const Book({
    required this.bookId,       // NEW — stable UUID
    required this.identifier,   // unchanged — filename for file I/O
    required this.title,
    required this.modifiedDate,
    required this.coverIdentifier,
    this.syncStatus,            // NEW — null means no cloud configured
  });

  final String bookId;
  final String identifier;
  final String title;
  final DateTime modifiedDate;
  final String coverIdentifier;
  final BookSyncStatus? syncStatus;
}
```

---

**`lib/features/books/data/data_sources/implementations/epub_data_source.dart`** — MODIFIED

Generate a `bookId` UUID when a book is first added and persist it alongside the file. On subsequent reads, load the stored UUID.

The simplest approach: store `<identifier>.id` as a tiny sidecar file in the library folder (e.g. `MyBook.epub.id`). This keeps the UUID co-located with the EPUB with zero new infrastructure.

```dart
// When adding a book — generate and persist UUID
final String bookId = const Uuid().v4();
await _fileSystemRepository.writeFileAsString(
  '$destination.id',
  bookId,
);

// When reading a book — load the UUID sidecar
Future<String> _getOrCreateBookId(String absolutePath) async {
  final String idPath = '$absolutePath.id';
  if (await _fileSystemRepository.existsFile(idPath)) {
    return _fileSystemRepository.readFileAsString(idPath);
  }
  // Fallback for books added before this phase
  final String newId = const Uuid().v4();
  await _fileSystemRepository.writeFileAsString(idPath, newId);
  return newId;
}
```

---

**`lib/features/books/domain/repositories/book_metadata_repository.dart`** — NEW

```dart
abstract class BookMetadataRepository {
  Future<BookMetadata?> getMetadata(String bookId);
  Future<void> saveMetadata(BookMetadata metadata);
  Future<void> deleteMetadata(String bookId);
  Stream<String> get onMetadataChanged; // emits bookId on any change
}
```

**`lib/features/books/data/repositories/book_metadata_repository_impl.dart`** — NEW

Reads/writes `<dataPath>/metadata/<bookId>.json`. No cloud access.

---

**New use cases** under `lib/features/books/domain/use_cases/`:

| File                                       | Purpose                                                                     |
|--------------------------------------------|-----------------------------------------------------------------------------|
| `book_get_metadata_use_case.dart`          | Fetch `BookMetadata` for a given `bookId`                                   |
| `book_save_metadata_use_case.dart`         | Persist metadata (progress + bookmarks)                                     |
| `book_save_reading_position_use_case.dart` | Update `ReadingState.currentPosition`; creates/replaces the `auto` bookmark |
| `book_add_manual_bookmark_use_case.dart`   | Append a `BookmarkEntryType.manual` entry                                   |
| `book_delete_bookmark_use_case.dart`       | Remove a bookmark by its `id`                                               |

---

**`lib/features/books/setup_dependencies.dart`** — MODIFIED

Register `BookMetadataRepository` and the five new use cases.

---

### Completion criteria for Phase 1
- App compiles and runs with no behaviour change
- Every existing book silently gains a UUID sidecar on next open
- `BookMetadata` can be written and read back locally for any book

---

## Phase 2 — Cloud Index Foundation

> Build the `sync` feature with the `CloudIndex` data model and its local read/write. The index is **not** pushed to Google Drive yet — that comes in Phase 3. After this phase, the app still functions identically, but the index infrastructure is in place.

### What changes

**New feature folder:** `lib/features/sync/`

```
lib/features/sync/
├── domain/
│   ├── entities/
│   │   ├── cloud_index.dart
│   │   └── cloud_index_entry.dart
│   ├── repositories/
│   │   └── cloud_index_repository.dart
│   └── use_cases/
│       ├── sync_load_index_use_case.dart
│       └── sync_save_index_use_case.dart
├── data/
│   └── repositories/
│       └── cloud_index_repository_impl.dart   (local only for now)
└── setup_dependencies.dart
```

---

**`lib/features/sync/domain/entities/cloud_index_entry.dart`** — NEW

```dart
class CloudIndexEntry {
  const CloudIndexEntry({
    required this.bookId,
    required this.fileName,       // local filename e.g. "MyBook.epub"
    required this.lastSyncedAt,
    required this.syncStatus,
    this.cloudFileId,             // Google Drive file ID for the epub
    this.metadataCloudFileId,     // Google Drive file ID for metadata.json
    this.localFileHash,           // sha256 for change detection
    this.deletedAt,               // tombstone — null means active
  });
}
```

---

**`lib/features/sync/domain/entities/cloud_index.dart`** — NEW

```dart
class CloudIndex {
  const CloudIndex({
    required this.version,
    required this.lastUpdatedAt,
    required this.entries,
  });

  final int version;
  final DateTime lastUpdatedAt;
  final List<CloudIndexEntry> entries;

  // Append-only merge: union of entries, newer lastSyncedAt wins on conflict.
  CloudIndex mergeWith(CloudIndex other) { ... }

  // Convenience — active books only (deletedAt == null)
  List<CloudIndexEntry> get activeEntries =>
      entries.where((e) => e.deletedAt == null).toList();
}
```

---

**`lib/features/sync/domain/repositories/cloud_index_repository.dart`** — NEW

```dart
abstract class CloudIndexRepository {
  Future<CloudIndex> loadLocal();
  Future<void> saveLocal(CloudIndex index);

  // These are stubs in Phase 2, implemented in Phase 3:
  Future<CloudIndex?> loadFromCloud();
  Future<void> uploadToCloud(CloudIndex index);

  Future<CloudIndex> reconcile(); // merges local + cloud copies
  Stream<void> get onIndexChanged;
}
```

**`lib/features/sync/data/repositories/cloud_index_repository_impl.dart`** — NEW

In Phase 2, `loadFromCloud()` and `uploadToCloud()` return `null` / no-op. Only local JSON read/write (`<dataPath>/sync/index.json`) is active.

---

**`lib/features/sync/setup_dependencies.dart`** — NEW

Register `CloudIndexRepository` and the two local use cases.

---

### Completion criteria for Phase 2
- `index.json` is created locally on first use
- Books added/deleted update the local index correctly
- `CloudIndex.mergeWith()` has unit tests verifying tombstone and conflict logic

---

## Phase 3 — Cloud Layer: Folder Support

> Extend `CloudRepository` and `GoogleDriveApi` to support subfolder operations needed for the `books/{bookId}/` structure. After this phase, the app can upload/download individual files to named subfolders on Google Drive — but no sync logic is wired up yet.

### What changes

**`lib/features/cloud/domain/repositories/cloud_repository.dart`** — MODIFIED

Add three new methods alongside the existing four:

```dart
abstract class CloudRepository {
  // --- existing ---
  Future<CloudFile?> getFile(CloudProviders provider, String fileName);
  Future<void> uploadFile(CloudProviders provider, String path, {...});
  Future<void> deleteFile(CloudProviders provider, String fileId);
  Stream<Uint8List> downloadFile(CloudProviders provider, CloudFile file, {...});

  // --- new in Phase 3 ---

  /// Upload [localPath] into [cloudFolderPath] (e.g. "books/uuid-1234").
  Future<CloudFile> uploadFileToFolder(
    CloudProviders provider,
    String localPath,
    String cloudFolderPath, {
    void Function(double progress)? onUpload,
  });

  /// List all CloudFiles directly inside [cloudFolderPath].
  Future<List<CloudFile>> listFolder(
    CloudProviders provider,
    String cloudFolderPath,
  );

  /// Delete the entire folder and all its children.
  Future<bool> deleteFolder(
    CloudProviders provider,
    String cloudFolderPath,
  );
}
```

---

**`lib/features/cloud/data/repositories/cloud_repository_impl.dart`** — MODIFIED

Delegate the three new methods to `CloudDriveApi`.

---

**`lib/features/cloud/data/data_sources/cloud_drive_api.dart`** — MODIFIED

Add the matching abstract methods.

---

**`lib/features/cloud/data/data_sources/impl/google_drive_api.dart`** — MODIFIED

Implement folder operations using the Google Drive v3 API. Google Drive uses a parent-child relationship for folders rather than path strings, so the implementation maps `cloudFolderPath` to Drive folder IDs internally.

```dart
// Internal helper: resolve or create a folder chain like "books/uuid-1234"
// Returns the Drive folder ID of the deepest folder.
Future<String> _resolveFolderPath(String folderPath) async { ... }

@override
Future<CloudFile> uploadFileToFolder(
  String localPath,
  String cloudFolderPath, {
  void Function(double progress)? onUpload,
}) async {
  final String parentFolderId = await _resolveFolderPath(cloudFolderPath);
  // upload with parentFolderId instead of _appDataFolder
}
```

---

**`lib/features/sync/data/repositories/cloud_index_repository_impl.dart`** — MODIFIED

Implement the previously stubbed `loadFromCloud()` and `uploadToCloud()` now that `CloudRepository` has folder support. The index is stored as `index.json` at the root of the app folder (no subfolder).

---

### Completion criteria for Phase 3
- Can manually call `uploadFileToFolder` and verify the file appears inside the correct Drive subfolder
- `CloudIndexRepository.reconcile()` correctly merges a local-only and a cloud-only index
- All existing backup paths (`uploadFile`, `downloadFile`) are untouched and still pass

---

## Phase 4 — Per-Book Sync Engine

> Wire up the actual sync logic. Each book can now be individually uploaded to and downloaded from `books/{bookId}/` on Google Drive. The old `BackupBookCreateUseCase` zip flow is replaced. The backup UI still works — it surfaces sync actions rather than zip actions.

### What changes

**`lib/features/sync/domain/use_cases/`** — NEW use cases added:

| File                                   | Purpose                                                                                 |
|----------------------------------------|-----------------------------------------------------------------------------------------|
| `sync_upload_book_use_case.dart`       | Upload `book.epub` to `books/{bookId}/book.epub`; update index entry with `cloudFileId` |
| `sync_upload_metadata_use_case.dart`   | Upload `metadata.json` to `books/{bookId}/metadata.json`; update `metadataCloudFileId`  |
| `sync_download_book_use_case.dart`     | Download `book.epub` from Drive to local library path                                   |
| `sync_download_metadata_use_case.dart` | Download and merge `metadata.json` for a given `bookId`                                 |
| `sync_resolve_conflict_use_case.dart`  | Compare timestamps; return `SyncConflictResult` for the UI to act on                    |
| `sync_evict_local_book_use_case.dart`  | Delete local `.epub` + `.epub.id`, set status to `cloudOnly` in index                   |
| `sync_set_local_only_use_case.dart`    | Set `syncStatus = localOnly` in index; prevents future uploads for this book            |

---

**`lib/features/backup/data/repositories/book_backup_repository_impl.dart`** — MODIFIED

Remove zip-specific methods and delegate to the new sync use cases:

```dart
// REMOVE:
Future<String> archive(...)   // zip creation
Future<void> extract(...)     // zip extraction

// REPLACE uploadToCloud / downloadFromCloud with per-book equivalents:
Future<bool> uploadBook(String bookId, {void Function(double)? onUpload});
Future<bool> downloadBook(String bookId, {void Function(double)? onDownload});
```

The `BookBackupRepository` interface is updated to match.

---

**`lib/features/backup/domain/use_cases/backup_book_create_use_case.dart`** — MODIFIED

Replace the zip pipeline with a loop over all pending books, calling `SyncUploadBookUseCase` for each:

```dart
// BEFORE: zip → upload single file
// AFTER: for each book with syncStatus == pending → upload individually
Future<void> _runner() async {
  final CloudIndex index = await _syncLoadIndexUseCase();
  final pendingEntries = index.activeEntries
      .where((e) => e.syncStatus == BookSyncStatus.pending);

  for (final entry in pendingEntries) {
    await _syncUploadBookUseCase(entry.bookId, onUpload: ...);
    await _syncUploadMetadataUseCase(entry.bookId);
  }
}
```

---

**`lib/features/backup/domain/use_cases/backup_book_restore_use_case.dart`** — MODIFIED

Replace zip download+extract with index-driven selective restore. On a fresh device, reads the cloud index and downloads each active entry.

---

**`lib/features/backup/presentation/google_drive/cubit/backup_service_google_drive_cubit.dart`** — MODIFIED

Surface per-book sync state instead of coarse booleans:

```dart
// BEFORE
BackupServiceGoogleDriveState({
  isBookBackupExists: bool,
  isBookmarkBackupExists: bool,
  isCollectionBackupExists: bool,
  lastBackupTime: DateTime?,
})

// AFTER
BackupServiceGoogleDriveState({
  indexStatus: IndexSyncStatus,               // overall cloud connection state
  bookSyncMap: Map<String, BookSyncStatus>,   // bookId → status
  lastSyncedAt: DateTime?,
  pendingCount: int,
  // bookmark/collection fields unchanged
  isBookmarkBackupExists: bool,
  isCollectionBackupExists: bool,
})
```

New cubit methods:

```dart
Future<void> syncBook(String bookId);
Future<void> downloadBook(String bookId);
Future<void> evictBookLocally(String bookId);
Future<void> setBookLocalOnly(String bookId, bool localOnly);
```

---

**`lib/features/books/setup_dependencies.dart`** — MODIFIED

Subscribe to `BookRepository.onChangedController` to enqueue newly added books into the index with `syncStatus = pending`.

---

**`lib/features/sync/setup_dependencies.dart`** — MODIFIED

Register all new use cases from this phase.

---

### Completion criteria for Phase 4
- Adding a book on Device A → book appears in Google Drive under `books/{bookId}/book.epub`
- Adding a book on Device B after signing in → Drive index is reconciled and the book shows with `cloudOnly` status
- "Back books up" button in the UI triggers per-book upload instead of zip

---

## Phase 5 — Bookshelf Sync UI

> Surface sync status on each book tile in the bookshelf. This phase is purely presentational — no domain logic changes.

### What changes

**`lib/features/books/presentation/book_list/widgets/book_sync_status_icon.dart`** — NEW

Small overlay widget placed on each book cover tile showing the current `BookSyncStatus`:

```dart
class BookSyncStatusIcon extends StatelessWidget {
  const BookSyncStatusIcon({required this.status});
  final BookSyncStatus status;

  @override
  Widget build(BuildContext context) {
    return switch (status) {
      BookSyncStatus.synced    => Icon(Icons.cloud_done,            color: Colors.green),
      BookSyncStatus.pending   => Icon(Icons.cloud_upload_outlined, color: Colors.blue),
      BookSyncStatus.syncing   => const CircularProgressIndicator(strokeWidth: 2),
      BookSyncStatus.cloudOnly => Icon(Icons.cloud,                 color: Colors.grey),
      BookSyncStatus.conflict  => Icon(Icons.warning_amber,         color: Colors.orange),
      BookSyncStatus.error     => Icon(Icons.cloud_off,             color: Colors.red),
      BookSyncStatus.localOnly => Icon(Icons.lock_outline,          color: Colors.grey),
    };
  }
}
```

---

**`lib/features/books/presentation/book_list/cubit/book_list_cubit.dart`** — MODIFIED

Inject `CloudIndexRepository` and subscribe to `onIndexChanged` so the book list state re-emits whenever any book's sync status changes — without re-reading the filesystem.

```dart
// Add to constructor:
cubit.onIndexChangedSubscription =
    cloudIndexRepository.onIndexChanged.listen((_) => cubit.refreshSyncStatus());

// New lightweight refresh — only updates syncStatus fields, no epub I/O:
Future<void> refreshSyncStatus() async {
  final CloudIndex index = await _syncLoadIndexUseCase();
  final updated = state.dataList.map((book) {
    final entry = index.entries.firstWhereOrNull((e) => e.bookId == book.bookId);
    return book.copyWith(syncStatus: entry?.syncStatus);
  }).toList();
  emit(state.copyWith(dataList: updated));
}
```

---

**Book tile widget** (existing) — MODIFIED

Wrap the existing cover `Stack` to include `BookSyncStatusIcon` as a positioned overlay. Only shown when `book.syncStatus != null`.

---

**Long-press context menu** (existing) — MODIFIED

Add context menu actions that map to the new cubit methods from Phase 4:
- "Download" (when `cloudOnly`)
- "Remove from device" (when `synced`, to evict locally)
- "Don't sync this book" (to set `localOnly`)

---

**`lib/features/books/setup_dependencies.dart`** — MODIFIED

Pass `CloudIndexRepository` into `BookListCubit`.

---

### Completion criteria for Phase 5
- Each book tile shows the correct status icon reflecting its current sync state
- Status icon updates reactively when a background sync completes
- Long-press menu shows context-appropriate cloud actions

---

## Phase 6 — Migration & Zip Retirement

> Detect users with an existing `Library.zip` backup and migrate them to the new per-book format. After migration completes successfully, the zip backup path is retired.

### What changes

**`lib/features/sync/domain/use_cases/sync_migrate_from_zip_use_case.dart`** — NEW

Orchestrates the one-time migration. Runs only if `Library.zip` is found in Google Drive and `index.json` does not yet exist.

```
1. Prompt user: "Migrate your backup to the new format?"
2. Download Library.zip to temp directory
3. Extract all .epub files (same logic as old BookBackupRepositoryImpl.extract())
4. For each .epub:
   a. Generate bookId UUID
   b. Upload to books/{bookId}/book.epub on Drive
   c. Create default BookMetadata (no reading state, no bookmarks)
   d. Upload metadata to books/{bookId}/metadata.json
   e. Append entry to CloudIndex
5. Upload final index.json to Drive
6. Rename Library.zip → Library.zip.migrated on Drive (not deleted — safety net)
7. Clean up temp directory
```

---

**`lib/features/backup/presentation/google_drive/`** — MODIFIED

Show migration prompt on launch if:
- User is signed into Google Drive
- `Library.zip` exists on Drive
- `index.json` does not exist on Drive

Progress is shown in the existing backup process dialog, reusing `BackupProgressStepCode`.

---

**`lib/features/backup/data/repositories/book_backup_repository_impl.dart`** — MODIFIED (final cleanup)

Remove the now-dead zip methods entirely:
- `archive()` — deleted
- `extract()` — deleted
- `archiveName` getter — deleted

The `BookBackupRepository` interface is trimmed to match.

---

**`lib/features/backup/domain/use_cases/backup_book_create_use_case.dart`** — clean up any remaining zip imports.

---

**`lib/features/sync/setup_dependencies.dart`** — MODIFIED

Register `SyncMigrateFromZipUseCase`.

---

**`lib/main.dart`** — MODIFIED

Call `setupSyncDependencies()` after `setupBackupDependencies()`.

---

### Completion criteria for Phase 6
- User with existing `Library.zip` sees migration prompt on first launch after update
- Migration uploads all books individually and creates a valid `index.json`
- `Library.zip` is renamed (not deleted) on Drive as a fallback
- User with no prior backup starts fresh with an empty `index.json`
- All zip-related code paths are removed and no longer referenced

---

## Files Unchanged Across All Phases

These files require no modification at any phase:

| File                                                              | Reason                                                                                                                     |
|-------------------------------------------------------------------|----------------------------------------------------------------------------------------------------------------------------|
| `bookmark/` entire feature                                        | Global bookmark list is a separate concern; backed up as `bookmark.json` as before                                         |
| `collection/` entire feature                                      | Collection backup is unchanged; backed up as `collection.json` as before                                                   |
| `backup/data/repositories/bookmark_backup_repository_impl.dart`   | No change                                                                                                                  |
| `backup/data/repositories/collection_backup_repository_impl.dart` | No change                                                                                                                  |
| `backup/domain/use_cases/backup_bookmark_*`                       | No change                                                                                                                  |
| `backup/domain/use_cases/backup_collection_*`                     | No change                                                                                                                  |
| `reader/` feature                                                 | Reading position already written via `ReaderLocationCacheRepository`; Phase 1 adds a parallel metadata path for cloud sync |
| `auth/` feature                                                   | Sign-in flow unchanged                                                                                                     |
| `cloud/domain/entities/cloud_providers.dart`                      | No change; multi-cloud expansion deferred                                                                                  |