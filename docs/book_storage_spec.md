# Feature Spec: `book_storage`

## Overview

`book_storage` is a feature that defines the canonical structure for storing book files and their metadata. It provides a single abstract interface with two implementations — one for local device storage, one for cloud storage — so that all other features interact with book data through a consistent API regardless of where the data lives.

Callers identify every book solely by its `BookId`, a stable UUID generated once when a book is first added and never changed. All file path and cloud ID resolution is an internal implementation detail hidden from the rest of the app.

---

## Folder Structure

Both local and cloud storage follow the same layout. The book content and metadata always use the same fixed filenames. These filenames are defined as constants on the abstract interface so both implementations are guaranteed to agree.

### Local

Root: `AppPathProvider.libraryPath`

```
Library/
└── {bookId}/
    ├── book.epub
    └── metadata.json
```

### Cloud

Root: Google Drive `appDataFolder`

```
(appDataFolder)/
└── books/
    └── {bookId}/
        ├── book.epub
        ├── metadata.json
        └── history/
            └── {ISO8601}.json
```

The `history/` folder exists on cloud only. Local storage does not maintain snapshots. Each snapshot is a point-in-time copy of `metadata.json`, named by timestamp.

---

## Entities

### `BookId`

A UUID v4 string. Generated once when a book is added. Never changes for the lifetime of that book.

### `BookMetadata`

The metadata stored alongside each book. Contains the original filename (for display purposes only — it has no structural role), the book title, the date the book was added, the current reading state, and the list of manual bookmarks.

### `ReadingState`

Represents the reader's last known position in a book. Contains the EPUB CFI position string, progress percentage, the time of the last reading session, and the total seconds spent reading. Written silently every time the reader closes. This is not a user-facing concept — it exists purely to enable auto-resume.

### `BookmarkEntry`

A user-created saved position. Contains a unique id, an EPUB CFI position string, the creation timestamp, and an optional user-defined label. There is no auto type — bookmarks are always created explicitly by the user. Auto-resume is handled entirely by `ReadingState`.

---

## Interface

`BookStorage` exposes operations in four groups:

**Book content** — check existence, read bytes, write bytes, and delete a book. Writing creates the book folder if it does not already exist. Deleting removes the entire book folder and all its contents.

**Metadata** — read and write `BookMetadata` for a given book. Reading returns null if no metadata exists yet.

**Listing** — return the list of all `BookId` values present in this storage.

**Change notification** — a stream that emits a `BookId` whenever that book's content or metadata is written or deleted. Consumers subscribe to this stream to react to changes without polling.

No method on the interface accepts or returns a file path or filename. Every operation is identified solely by `BookId`.

---

## Implementations

### `LocalBookStorage`

Implements the interface against the device filesystem using `FileSystemRepository` and `AppPathProvider`. Path construction is entirely private — no path ever leaves this class.

Listing enumerates the immediate subdirectories of `libraryPath` and treats each directory name as a `BookId`.

The change notification stream fires after every successful write or delete operation.

Dependencies: `AppPathProvider`, `FileSystemRepository`, `JsonRepository`.

### `CloudBookStorage`

Implements the interface against Google Drive using `CloudRepository`. Cloud path construction mirrors the local structure with a `books/` root prefix and is entirely private to this class.

Listing enumerates the subfolders inside the `books/` Drive folder.

Deleting a book removes the entire `books/{bookId}/` Drive folder and all its contents.

The change notification stream fires after every successful write or delete to Drive.

Dependencies: `CloudRepository`.

The current `CloudRepository` interface does not support folder-based operations. Three new methods are required: uploading a file into a named subfolder path, listing the contents of a folder, and deleting an entire folder. These must be added to `CloudRepository`, `CloudRepositoryImpl`, and `GoogleDriveApi`.

---

## Feature Folder Structure

```
lib/features/book_storage/
├── domain/
│   ├── entities/
│   │   ├── book_metadata.dart
│   │   ├── reading_state.dart
│   │   └── bookmark_entry.dart
│   └── repositories/
│       └── book_storage.dart
├── data/
│   └── repositories/
│       ├── local_book_storage.dart
│       └── cloud_book_storage.dart
└── setup_dependencies.dart
```

---

## Dependency Injection

Both `LocalBookStorage` and `CloudBookStorage` are registered as lazy singletons. `setupBookStorageDependencies()` must be called before any feature that depends on `book_storage`.