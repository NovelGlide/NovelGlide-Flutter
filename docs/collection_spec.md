# Feature Spec: `collection` (redesigned)

## Overview

The `collection` feature owns the creation, management, and display of user-defined book collections. Its core responsibility — grouping books together — remains unchanged. What changes is how a collection refers to its books.

Currently, `CollectionData.pathList` stores book filenames. Under `book_storage`, filenames have no stable identity — books are identified by `BookId`. This spec covers the changes required to align the collection feature with that model.

---

## What Changes

### `CollectionData` entity

The `pathList` field, which stores a list of book filenames, is replaced by a `bookIds` field storing a list of `BookId` values. Since `BookId` is a stable UUID that never changes regardless of renames or moves, collections become resilient to any future book file changes.

All existing operations on collections — create, delete, update, reorder — continue to work identically. Only the type of the member list changes.

### `CollectionRepository`

The repository interface and its implementation require no structural changes. The data it reads and writes now contains `BookId` values instead of filenames. The underlying storage mechanism — a local JSON file — is unchanged.

### Callers that resolve books from a collection

Two cubits currently take a collection's member list and load the corresponding books:

**`CollectionViewerCubit`** passes `pathList` to `BookGetListByIdentifiersUseCase` to load the books inside a collection. This changes to passing `bookIds` to a use case that resolves books by `BookId` via `book_storage`.

**`CollectionAddBookCubit`** computes which collections a selected set of books already belongs to by intersecting filename sets. This changes to intersecting `BookId` sets instead.

---

## What Does Not Change

The collection feature's structure, use cases, UI, preferences, and change notification stream are all unchanged. The only meaningful change throughout the feature is replacing `String` filename references with `BookId` references.

---

## Backup

The existing `CollectionBackupRepositoryImpl` uploads and downloads `collections.json` as a standalone file. This continues to work as-is since the file now simply contains `BookId` values instead of filenames. No structural change is needed to the backup flow.

---

## Local Migration

Existing users have `collections.json` records containing filenames. A one-time migration must run on the first launch after this change ships.

For each collection, each filename in the member list is matched against the corresponding book's `originalFileName` field in `BookMetadata`. The filename is replaced with that book's `BookId`. If a match cannot be found — for example because the book was deleted — the entry is silently dropped from the collection.

The migration is idempotent. If an entry already contains a UUID (from a previous successful migration), it is left unchanged.

---

## Feature Folder Structure

No new files. No files removed. The folder structure is unchanged.

```
lib/features/collection/
├── domain/
│   ├── entities/
│   │   └── collection_data.dart        ← pathList → bookIds
│   ├── repositories/
│   │   └── collection_repository.dart  ← unchanged
│   └── use_cases/                      ← all unchanged
├── data/
│   ├── data_sources/                   ← unchanged
│   └── repositories/
│       └── collection_repository_impl.dart  ← unchanged
└── presentation/                       ← viewer and add-book cubits updated
```

---

## Dependency Injection

`setupCollectionDependencies()` is unchanged. No new dependencies are introduced.