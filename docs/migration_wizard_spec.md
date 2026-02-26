# Spec: Library Migration

## Overview

Library migration is a one-time process that transforms the app's existing storage structure into the new `book_storage` architecture. It runs on first launch after the `book_storage` feature ships and must complete before the app becomes usable.

The migration uses the cloud backup as the primary book source when available, merging it with any local books, then builds the new folder structure, updates all dependent data, and finally enables cloud sync. A wizard guides the user through the process so they understand what is happening and can see progress.

---

## Scenarios

The migration handles four possible states. The wizard and migration logic adapt to each.

| Local state           | Cloud state            | Outcome                                       |
|-----------------------|------------------------|-----------------------------------------------|
| Existing flat library | `Library.zip` on Drive | Download zip, merge with local, migrate all   |
| Existing flat library | No zip on Drive        | Migrate local books only                      |
| Clean install         | `Library.zip` on Drive | Download zip, build library fresh from cloud  |
| Clean install         | No zip on Drive        | Nothing to migrate, mark complete immediately |

In all cases, if `Library.zip` is available on Drive it is treated as the authoritative book source. Local files are merged in — when the same book exists in both places, matched by original filename, the local copy is preferred since its reading position cache may be more recent.

---

## Data Being Migrated

### What carries forward

- All EPUB files, restructured into `Library/{bookId}/book.epub`
- Book title and original filename, stored in `metadata.json`
- Reading position from `ReaderLocationCacheRepository`, stored as `ReadingState.currentPosition` in `metadata.json`
- Collections, with filename references replaced by `BookId` values

### What carries forward with best-effort precision

Existing bookmarks in `bookmark.json` are migrated to `BookmarkEntry` values using the best position data available per entry:

- If `startCfi` is present on the old `BookmarkData`, it is used directly as `BookmarkEntry.position`. The bookmark is restored to the exact paragraph.
- If `startCfi` is absent, the `chapterIdentifier` (the chapter's filename inside the EPUB) is used to construct a position pointing to the start of that chapter. The bookmark is restored to the chapter start rather than the exact paragraph.

In both cases the bookmark is preserved. Precision varies but no bookmarks are silently lost.

### What is retired after migration

- Flat `Library/*.epub` files — moved into new folder structure
- `Cache/locations/*.tmp` files — superseded by `ReadingState` in `metadata.json`
- `bookmark.json` — cleared after all entries are migrated to per-book `metadata.json` files
- `Library.zip` on Drive — renamed to `Library.zip.bak`, never deleted

---

## Migration Wizard

The wizard is a blocking full-screen flow. The app's main interface is not accessible until migration completes, is deferred, or is not needed (clean install with no cloud backup).

### Deferral policy

The user may defer migration up to three times using "Remind me later". After three deferrals the option is removed and migration is required to proceed. This prevents the app from indefinitely supporting both old and new storage structures simultaneously. The deferral count is stored in app preferences.

---

### Screen 1 — Introduction

Shown to all users who require migration.

**Content:**
- Heading: "Your library is getting an upgrade"
- A plain-language explanation that the app is updating how books are stored. This happens once and cannot be undone.
- A note that existing bookmarks will be carried over, though some may only restore to the start of their chapter rather than the exact position if precise location data was not available.
- Estimated time indication if determinable (e.g. "This may take a minute for large libraries").

**Actions:**
- "Get started" — proceeds to Screen 2 or Screen 3 depending on cloud state
- "Remind me later" — defers migration to next launch, shown only if deferral count is below the limit

---

### Screen 2 — Cloud backup (conditional)

Shown only if the user is currently signed into Google Drive and `Library.zip` is detected on Drive. Skipped entirely otherwise.

**Content:**
- Heading: "We found your cloud backup"
- Explanation that the app found a previous backup on Google Drive and can include those books in the migration.
- Note that books in the cloud backup and books on this device will be merged. Duplicates matched by filename will use the local copy.

**Actions:**
- "Include cloud backup" — migration will download and merge `Library.zip`
- "Use device only" — migration proceeds with local books only, zip is ignored

---

### Screen 3 — Progress

Non-dismissible. Shown once the user confirms they want to start. There is no cancel button once migration has begun.

**Content:**
- A progress bar showing overall completion as a percentage
- A current step label indicating what is happening right now, for example:
  - "Downloading your cloud backup…"
  - "Processing book 4 of 12…"
  - "Updating collections…"
  - "Finishing up…"

**Error state:**
If the migration fails at any step, the progress screen transitions to an error state showing what went wrong and a "Retry" button. Retrying resumes from the last successfully completed step, not from the beginning.

**Low storage state:**
If the device runs out of storage during migration, a specific message is shown asking the user to free space and tap "Retry".

---

### Screen 4 — Completion

Shown after successful migration.

**Content:**
- Confirmation that the library has been upgraded
- If any books were skipped due to errors, a count is shown with a link to a details screen accessible later from settings
- A single "Continue" button that opens the app normally

---

## Migration Steps

Progress is tracked in a state file at `Data/migration_state.json`. Each step records its completion status so the migration can resume after interruption without repeating completed work. The state file is deleted once migration fully completes.

### Step 1 — Download cloud backup (conditional)

If the user chose to include the cloud backup in Screen 2, download `Library.zip` from Google Drive to a temporary directory. If the download fails, surface the error on Screen 3 and allow retry. If the user chose device-only in Screen 2, skip this step.

### Step 2 — Enumerate books

Build a unified list of all books to migrate:

- If a zip was downloaded, extract all EPUB files from it into the temporary directory.
- Add all EPUB files found in the flat local `Library/` folder.
- Deduplicate by original filename. Where both sources have the same filename, keep the local copy and discard the zip copy.

This unified list is the complete set of books that will be migrated.

### Step 3 — Build new folder structure

For each book in the unified list:

- Generate a `BookId` (UUID v4).
- Create `Library/{bookId}/`.
- Move or copy the EPUB file into the new folder as `book.epub`.
- Extract the book title from the EPUB metadata. Fall back to the original filename without extension if extraction fails.
- Check `Cache/locations/` for a `.tmp` file matching the original filename. If found, use its contents as `ReadingState.currentPosition`.
- Find all `BookmarkData` entries in `bookmark.json` whose `bookIdentifier` matches this book's original filename. For each entry, construct a `BookmarkEntry` using the best available position data: use `startCfi` directly if present, otherwise use `chapterIdentifier` as a chapter-level position pointing to the start of that chapter. Preserve the `savedTime` as `createdAt` and the `bookName` as the label.
- Write `Library/{bookId}/metadata.json` containing the book title, original filename, creation date, reading state if available, and the migrated bookmark entries.
- Record the `originalFileName → bookId` mapping in the migration state file for use in subsequent steps.

Books that cannot be processed due to a corrupt or unreadable EPUB are skipped and logged. Migration continues with the remaining books.

### Step 4 — Migrate collections

Read `collection.json`. For each collection, replace each filename entry in `pathList` with the corresponding `BookId` from the mapping recorded in step 3. Filenames with no matching entry — books that were skipped or never existed — are silently dropped from the collection. Write the updated `collection.json` with the renamed field `bookIds`.

### Step 5 — Clear superseded data

- Delete all `.tmp` files in `Cache/locations/`. Reading state is now in each book's `metadata.json`.
- Clear `bookmark.json`. All entries have been migrated to their respective book's `metadata.json` in step 3.
- Delete any temporary extraction directory created in step 1.

### Step 6 — Rebuild bookmark cache

Trigger `BookmarkRebuildCacheUseCase`. At this point all metadata files have empty bookmark lists, so the resulting cache will be empty. This ensures `bookmark_cache.json` exists and is valid before the app opens.

### Step 7 — Rename cloud backup (conditional)

If `Library.zip` was used in this migration, rename it to `Library.zip.bak` on Google Drive. This preserves it as a safety net without interfering with the new sync structure. Do not delete it.

### Step 8 — Enable cloud sync

If the user is signed into Google Drive, trigger the initial cloud sync. This uploads each `{bookId}/book.epub` and `{bookId}/metadata.json` to Drive under the new `books/{bookId}/` folder structure and creates `index.json`. This step runs in the background — the app becomes usable immediately after step 7 completes without waiting for the full upload.

### Step 9 — Mark migration complete

Write `Data/migration_v1.done`. On all future launches the presence of this file causes the migration wizard to be skipped entirely. Delete `Data/migration_state.json`.

---

## New Feature: Migration

This flow is implemented as a dedicated `migration` feature.

### Responsibilities

- Detecting whether migration is needed on app launch
- Managing the deferral count in preferences
- Orchestrating all migration steps in order
- Tracking per-step progress in the migration state file
- Resuming from the correct step after interruption
- Reporting skipped books

### Position in architecture

The `migration` feature depends on `book_storage`, `bookmark`, `collection`, and `cloud`. It is only active during its one-time execution and has no ongoing responsibilities after completion.

### Feature folder structure

```
lib/features/migration/
├── domain/
│   ├── entities/
│   │   ├── migration_state.dart
│   │   └── migration_step.dart
│   ├── repositories/
│   │   └── migration_repository.dart
│   └── use_cases/
│       ├── migration_is_needed_use_case.dart
│       ├── migration_run_use_case.dart
│       └── migration_get_state_use_case.dart
├── data/
│   └── repositories/
│       └── migration_repository_impl.dart
├── presentation/
│   └── wizard/
│       ├── cubit/
│       │   └── migration_wizard_cubit.dart
│       └── screens/
│           ├── migration_introduction_screen.dart
│           ├── migration_cloud_screen.dart
│           ├── migration_progress_screen.dart
│           └── migration_complete_screen.dart
└── setup_dependencies.dart
```

### App launch integration

On every launch, before the main interface is shown, the app checks `migration_is_needed_use_case`. If migration is needed and the deferral limit has not been reached, the wizard is pushed as a full-screen route over the normal app. If migration is not needed, the app opens normally.

---

## Dependency Injection

`setupMigrationDependencies()` must be called after `setupBookStorageDependencies()`, `setupBookmarkDependencies()`, and `setupCollectionDependencies()`.