# Feature Spec: `bookmark` (redesigned)

## Overview

The `bookmark` feature owns the app-wide Bookmarks tab — the UI where users browse all their saved positions across every book and navigate back to them. It does not own bookmark storage. Bookmarks are stored inside each book's `metadata.json`, owned by `book_storage`.

To avoid reading every book's metadata file each time the Bookmarks tab opens, the feature maintains a local cache file that aggregates all bookmark data in one place. This cache is the read source for the entire feature and is always treated as disposable — it can be fully rebuilt from `book_storage` at any time.

---

## Responsibilities

| Concern                            | Owner                                                   |
|------------------------------------|---------------------------------------------------------|
| Bookmark storage — source of truth | `book_storage` — `BookmarkEntry` inside `metadata.json` |
| Bookmark cache — fast read layer   | `bookmark` — `bookmark_cache.json`                      |
| Bookmarks tab UI                   | `bookmark`                                              |
| Creating and deleting bookmarks    | `bookmark` — writes through to `book_storage`           |

---

## Cache Design

The cache is a single JSON file stored in `AppPathProvider.dataPath`. It holds a flat map of `BookId` to that book's list of bookmarks, enriched with the book title so the UI can render list items without additional lookups.

**Warm path (normal operation).** The cache repository subscribes to `LocalBookStorage.onChanged`. When any book's metadata changes, only that book's cache entry is updated. No full rebuild is needed.

**Cold path (first launch, missing cache, or corruption).** The cache repository reads every book's `metadata.json` via `LocalBookStorage`, collects all bookmark entries, and writes a fresh cache file. This is the only scenario where all metadata files are read at once.

**Book deleted.** When `LocalBookStorage.onChanged` emits a `BookId` and the book no longer exists, that book's entry is removed from the cache.

---

## Entities

### `BookmarkItem`

The presentation entity used throughout the `bookmark` feature. Combines a `BookmarkEntry` with just enough book context — specifically the book title — to render a Bookmarks tab list item without further lookups. Replaces the existing `BookmarkData`.

---

## Position Format

`BookmarkEntry.position` holds the location to navigate to when the bookmark is tapped. It may contain either of two formats:

- **EPUB CFI string** — a precise intra-chapter position, e.g. `epubcfi(/6/4[ch01]!/4/2/1:0)`. Used when the bookmark was created by the reader or migrated from a `BookmarkData` entry that had a `startCfi` value. Restores to the exact paragraph.
- **Chapter identifier** — the filename of a chapter inside the EPUB, e.g. `chapter_03.xhtml`. Used when a migrated `BookmarkData` entry had no `startCfi`. Restores to the start of that chapter.

The reader already handles both formats via the existing `pageIdentifier` and `cfi` parameters on `ReaderCoreRepository.init()`. No new reader logic is required to support chapter-level positions.

---

## Repositories

### `BookmarkCacheRepository` (new)

Owns reading and writing `bookmark_cache.json`. Responsible for the cache lifecycle described above. Subscribes to `LocalBookStorage.onChanged` at initialisation. Exposes a method to return all bookmarks as a flat list of `BookmarkItem`, a method to update a single book's cache entry, a method to remove a book's entry, a method to trigger a full rebuild, and a change notification stream.

### `BookmarkRepository` (modified)

The existing interface is updated to reflect the new data flow. Reads always come from the cache. Writes go to `book_storage` via `LocalBookStorage` and the cache updates reactively through the `onChanged` subscription.

Exposes: get all bookmarks as a list, get a single bookmark by entry id, add a bookmark to a specific book, and delete bookmarks by entry id. The delete operation resolves which book each entry belongs to via the cache, then updates the affected `metadata.json` files.

The existing `reset` operation is retired — resetting all bookmarks is no longer meaningful since bookmarks live inside individual book metadata files owned by `book_storage`.

---

## Use Cases

The existing use cases are updated or replaced to match the new repository interface:

- **Get list** — returns all bookmarks from the cache as `BookmarkItem` values.
- **Get by id** — returns a single `BookmarkItem` by entry id.
- **Add bookmark** — adds a `BookmarkEntry` to a specific book.
- **Delete bookmarks** — deletes a set of entries by id.
- **Observe changes** — unchanged, wraps the repository's change stream.
- **Rebuild cache** — triggers a full cache rebuild from `book_storage`. Used on cold start or if the cache is detected to be invalid.

---

## Impact on Existing Callers

### `BookmarkListCubit`

The list, selection, and delete flows are structurally unchanged. The entity type changes from `BookmarkData` to `BookmarkItem`.

### `ReaderCubit`

Currently uses `BookmarkGetDataUseCase` to read the resume position and `BookmarkUpdateDataUseCase` to save it. Both usages are removed. Reading the resume position now comes from `ReadingState` inside `BookMetadata`, read via `LocalBookStorage`. Saving the position on reader close writes `ReadingState` directly via `LocalBookStorage`. The reader only interacts with `BookmarkRepository` when the user explicitly creates a manual bookmark.

### `TocCubit`

Currently uses `BookmarkGetDataUseCase` to show the current reading position marker in the table of contents. This changes to reading `ReadingState` from `BookMetadata` via `LocalBookStorage`.

### `BookmarkBackupRepositoryImpl`

Retired. Bookmarks are backed up as part of each book's `metadata.json` through the cloud sync path in `book_storage`. The standalone `bookmark.json` cloud backup no longer exists.

---

## Feature Folder Structure

```
lib/features/bookmark/
├── domain/
│   ├── entities/
│   │   └── bookmark_item.dart
│   ├── repositories/
│   │   ├── bookmark_repository.dart
│   │   └── bookmark_cache_repository.dart
│   └── use_cases/
│       ├── bookmark_get_list_use_case.dart
│       ├── bookmark_get_by_id_use_case.dart
│       ├── bookmark_add_use_case.dart
│       ├── bookmark_delete_use_case.dart
│       ├── bookmark_observe_change_use_case.dart
│       └── bookmark_rebuild_cache_use_case.dart
├── data/
│   ├── repositories/
│   │   ├── bookmark_repository_impl.dart
│   │   └── bookmark_cache_repository_impl.dart
│   └── data_sources/
│       └── (bookmark_local_json_data_source retired)
└── setup_dependencies.dart
```

---

## Dependency Injection

`setupBookmarkDependencies()` must be called after `setupBookStorageDependencies()` since `BookmarkCacheRepository` depends on `LocalBookStorage`.

`BookmarkCacheRepository` and `BookmarkRepository` are registered as lazy singletons. All use cases are registered as factories. The `BookmarkListCubit` registration is updated to use the new use case types.