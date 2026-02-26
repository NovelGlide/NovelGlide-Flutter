# Cloud Sync & Library Enhancement Feature Plan
**Version 1.0 · February 2026**

---

## Overview & Strategic Shift

The current backup feature treats the entire book library as a single monolithic unit — compressing all EPUBs into one zip and uploading it to Google Drive. While functional, this approach limits granularity, wastes bandwidth, and provides no per-book visibility to the user.

This plan transforms the feature from a hidden "backup" operation into a transparent **cloud library** — where the cloud is a first-class storage layer and every book has its own sync state visible directly on the bookshelf.

|             | Before: Backup Model  | After: Cloud Library Model     |
|-------------|-----------------------|--------------------------------|
| Upload unit | Single `Library.zip`  | Each book individually         |
| Restore     | All-or-nothing        | Per-book, selective            |
| Visibility  | None                  | Sync status on every book tile |
| Trigger     | Manual only           | Auto on meaningful events      |
| Bandwidth   | Re-uploads everything | Only changed files             |

---

## 1. Storage Architecture

### 1.1 Three-Layer Model

The new architecture separates concerns into three layers, each with its own sync frequency and responsibility:

| Layer               | Contents                                | Sync Frequency      | Format          |
|---------------------|-----------------------------------------|---------------------|-----------------|
| `index.json`        | Global book registry, ID mappings       | On library change   | JSON            |
| `BookMetadata.json` | Reading progress, bookmarks, sync state | On reading activity | JSON (per book) |
| `Book.epub`         | The actual EPUB content                 | Once on add         | EPUB            |

Each layer syncs independently. When you finish a chapter, only the tiny metadata JSON needs to upload — not the entire EPUB again.

---

### 1.2 The Index File (`index.json`)

The index file is the backbone of the entire system. It acts as a **pointer table** — a single source of truth that maps the app's internal stable ID to both the local filename and the cloud provider's opaque file ID.

This solves the fundamental mismatch between how local storage and Google Drive identify files:

```
Local Storage   →  "MyBook.epub"                          (filename-based)
Google Drive    →  "1BxiMVs0XRA5nFMdKvBdBZjgmUUqptlbs74"  (opaque ID)
```

**Structure:**

```json
{
  "version": 1,
  "lastUpdatedAt": "2026-02-26T10:00:00Z",
  "books": [
    {
      "bookId": "uuid-1234-abcd",
      "fileName": "MyBook.epub",
      "cloudFileId": "1BxiMVs0XRA...",
      "metadataCloudFileId": "2CyiNW...",
      "localFileHash": "sha256:abc123",
      "lastSyncedAt": "2026-02-26T09:00:00Z",
      "syncStatus": "synced",
      "deletedAt": null
    }
  ]
}
```

**Why a stable `bookId`?**
A UUID generated once is the key insight. The local filename can change (user renames the file), the Google Drive ID changes if the file is re-uploaded — but `bookId` is permanent. All metadata, bookmarks, and sync state hang off this stable anchor.

**Where does it live?**
Both locally (working copy) and on Google Drive (source of truth). On app launch, the two copies are compared and reconciled. On a new device, downloading `index.json` first means the bookshelf can populate immediately showing all cloud books before any EPUB is downloaded.

**Append-only with tombstones:**
Rather than hard-deleting entries, set `deletedAt` to a timestamp when a book is removed. This makes merging two versions of the index (from two devices) safe and deterministic — no data is ever silently lost.

---

### 1.3 Book Metadata (`BookMetadata.json`)

Each book gets its own lightweight metadata file stored separately from the EPUB.

```json
{
  "bookId": "uuid-1234-abcd",
  "readingState": {
    "currentPosition": "epubcfi(/6/4[chap01]!/4/2/1:0)",
    "progressPercent": 42.5,
    "lastReadAt": "2026-02-26T08:30:00Z",
    "totalReadingSeconds": 7200
  },
  "bookmarks": [
    {
      "id": "bm-001",
      "type": "auto",
      "position": "epubcfi(/6/4[chap01]!/4/2/1:0)",
      "label": null,
      "createdAt": "2026-02-26T08:30:00Z"
    },
    {
      "id": "bm-002",
      "type": "manual",
      "position": "epubcfi(/6/6[chap03]!/4/2/1:0)",
      "label": "Great quote here",
      "createdAt": "2026-02-25T20:15:00Z"
    }
  ]
}
```

**Bookmark type distinction:**

- **`auto`** — saved silently when the user closes the book or the app. Only one exists per book; it overwrites on every close. This is the "resume reading" position.
- **`manual`** — user explicitly taps to save a spot. Multiple can exist per book and are never auto-deleted.

Both share the same data structure with a `type` field, keeping the model simple while preserving the behavioral difference.

---

### 1.4 Cloud Folder Structure

```
Google Drive App Folder/
├── index.json
├── collections.json
├── books/
│   ├── {bookId-1}/
│   │   ├── book.epub
│   │   ├── metadata.json
│   │   └── history/
│   │       ├── metadata_2026-02-25.json
│   │       └── metadata_2026-02-24.json
│   └── {bookId-2}/
│       ├── book.epub
│       └── metadata.json
```

---

## 2. Bookshelf UI — Cloud Sync Status

### 2.1 Per-Book Status Indicators

Each book tile on the bookshelf displays a small icon overlay showing its current sync state — identical in spirit to OneDrive on Windows.

| Icon | Status     | Meaning & User Action                                    |
|------|------------|----------------------------------------------------------|
| ☁️   | Cloud Only | Not downloaded locally. Tap to download on demand.       |
| ✅    | Synced     | Local copy matches cloud. No action needed.              |
| 🔄   | Syncing    | Upload or download in progress. Shows circular progress. |
| ⏳    | Pending    | Local changes queued for upload. Syncs when connected.   |
| ⚠️   | Conflict   | Both devices modified data. Tap to resolve.              |
| ❌    | Error      | Last sync failed. Tap for details and retry.             |
| 🔒   | Local Only | User opted out of sync for this book. Never uploaded.    |

### 2.2 New User Interactions

Per-book cloud objects unlock interactions not possible with the single-zip model:

- **Free up local space** — evict a book from device storage while keeping it cloud-only. The tile remains on the shelf with the ☁️ indicator.
- **Download on demand** — tapping a Cloud Only book triggers a background download; the book opens when ready.
- **Selective restore on new device** — the shelf populates from `index.json` immediately, showing all cloud books. User picks which to download locally rather than restoring everything at once.
- **Per-book sync toggle** — a long-press context menu lets users mark a book as Local Only for privacy.
- **Storage management view** — a dedicated screen showing local vs. cloud storage per book, with bulk eviction options.

---

## 3. Automatic Sync Triggers

Rather than relying on timed schedules, the sync system responds to meaningful reading events — ensuring data is never stale without draining battery or bandwidth unnecessarily.

### 3.1 Metadata Sync Triggers (lightweight, fast)

- App moved to background or closed
- User places a manual bookmark
- Reading session ends (chapter complete or user navigates away)
- Heartbeat every N minutes of active reading (configurable, default 5 min)

### 3.2 Book File Sync Triggers (heavier, background)

- New book added to the library
- Book file replaced or updated
- App launches and `index.json` comparison reveals un-synced books

### 3.3 Change Detection

Before uploading any file, compare the local `localFileHash` in `index.json` against the current file hash. If they match, skip the upload. This prevents wasteful re-uploads of large EPUB files when only the metadata has changed.

---

## 4. Backup Versioning & History

The current system overwrites the single backup on every sync. With per-book folders, versioning is straightforward.

- Retain the last **3 versions** per book by default (configurable in settings)
- Metadata snapshots are stored as timestamped files in the `history/` subfolder
- EPUB files are only re-versioned if the file content changes (rare)
- A History sheet accessible from each book's detail view shows timestamp, file size, and reading progress for each version
- Restoring a version restores both the EPUB and its metadata snapshot together

---

## 5. Cross-Device Reading Continuity

With metadata syncing independently from the EPUB file, cross-device continuity becomes a natural side effect of the architecture.

**Flow:**
1. User reads on Device A and closes the book → metadata syncs to cloud
2. User opens the same book on Device B → app fetches latest `metadata.json`
3. If cloud metadata is newer than local, a prompt appears:
   > *"Resume from page 87 where you left off on your other device?"*
4. User accepts (jump to cloud position) or dismisses (stay at local position)

**Sync latency goal:** Metadata sync should complete within a few seconds on WiFi. On mobile data, syncs can be deferred and batched per user settings.

---

## 6. Conflict Resolution

Conflicts arise when the same data is modified on two devices before either syncs. Each data type has a clear resolution strategy.

### 6.1 Index Conflicts
Since the index is append-only with tombstones, merging two versions is deterministic: take the union of all entries. For any `bookId` present in both, the entry with the newer `lastSyncedAt` wins.

### 6.2 Metadata Conflicts

| Data                            | Strategy                                                                |
|---------------------------------|-------------------------------------------------------------------------|
| Auto bookmark (resume position) | Last-write-wins silently                                                |
| Manual bookmarks                | Merge both sets (unique IDs prevent duplicates)                         |
| Reading position                | Prompt user if devices diverge by more than a threshold (e.g. 5+ pages) |

### 6.3 Book File Conflicts
If different file hashes are detected for the same `bookId` on two devices, prompt the user to choose which version to keep. The unchosen version is archived to `history/` rather than deleted.

---

## 7. Multi-Cloud Provider Support

The `CloudProviders` enum already anticipates expansion. The `index.json` approach makes adding a new provider straightforward — the `bookId` stays the same, and the index entry gains an additional field for the new provider's ID.

```json
{
  "bookId": "uuid-1234-abcd",
  "fileName": "MyBook.epub",
  "googleDriveFileId": "1BxiMVs0XRA...",
  "iCloudFileId": "CKRecordID:...",
  "dropboxFileId": "id:abc123...",
  "primaryProvider": "googleDrive"
}
```

This is a lower-priority item — the architecture supports it, but should not be built until the single-provider implementation is stable.

---

## 8. Implementation Priority

| Priority  | Feature                           | Rationale                                              | Effort |
|-----------|-----------------------------------|--------------------------------------------------------|--------|
| 🔴 High   | Per-book upload refactor          | Prerequisite for everything else                       | Large  |
| 🔴 High   | `index.json` storage layer        | Foundation for stable ID mapping                       | Large  |
| 🔴 High   | `BookMetadata.json` per book      | Enables progress sync & bookmarks                      | Medium |
| 🔴 High   | Bookshelf sync status UI          | Core UX improvement, visible value                     | Medium |
| 🟡 Medium | Auto-sync triggers                | Removes manual backup friction                         | Medium |
| 🟡 Medium | Cross-device continuity prompt    | High user value, low complexity once metadata is ready | Small  |
| 🟡 Medium | Conflict resolution               | Necessary for multi-device correctness                 | Medium |
| 🟡 Medium | Backup versioning & history       | Safety net, restores trust                             | Medium |
| 🟢 Low    | Per-book sync toggle (Local Only) | Privacy feature, niche use case                        | Small  |
| 🟢 Low    | Storage management view           | Nice-to-have, housekeeping                             | Small  |
| 🟢 Low    | Multi-cloud provider support      | Architecture is ready, demand unclear                  | Large  |

---

## 9. Migration Plan

The shift from the current zip-based system to per-book sync requires a one-time migration for existing users.

1. **On first launch after update:** detect if `Library.zip` exists in Google Drive
2. **Prompt the user** to migrate their existing backup to the new format
3. **Migration process:** download `Library.zip`, extract each EPUB, re-upload individually, generate `bookId` UUIDs, build `index.json`
4. **After migration:** delete `Library.zip` from Google Drive (or archive it)
5. **Fallback:** if migration fails, the old backup remains intact and the user is notified

Migration should run as a background task with a progress indicator, and must be resumable in case of interruption.

---

*This plan should be treated as a living document — priorities and details may evolve as implementation progresses.*