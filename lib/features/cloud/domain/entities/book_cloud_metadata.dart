import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:novel_glide/features/book_storage/domain/entities/bookmark_entry.dart';
import 'package:novel_glide/features/book_storage/domain/entities/reading_state.dart';

part 'book_cloud_metadata.freezed.dart';
part 'book_cloud_metadata.g.dart';

/// Converter for serializing/deserializing ReadingState.
class ReadingStateConverter
    implements JsonConverter<ReadingState, Map<String, dynamic>> {
  const ReadingStateConverter();

  @override
  ReadingState fromJson(Map<String, dynamic> json) {
    return ReadingState.fromJson(json);
  }

  @override
  Map<String, dynamic> toJson(ReadingState object) {
    return object.toJson() as Map<String, dynamic>;
  }
}

/// Converter for serializing/deserializing BookmarkEntry lists.
class BookmarkEntryListConverter
    implements JsonConverter<List<BookmarkEntry>, List<dynamic>> {
  const BookmarkEntryListConverter();

  @override
  List<BookmarkEntry> fromJson(List<dynamic> json) {
    return json
        .map((dynamic e) => BookmarkEntry.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  List<dynamic> toJson(List<BookmarkEntry> object) {
    return object.map((BookmarkEntry e) => e.toJson()).toList();
  }
}

/// Cloud metadata for a single book.
///
/// Stores per-book reading state (position, progress, timestamps) and
/// bookmarks (both auto-resume and manual). This metadata is synced
/// independently from the EPUB file for granular control and faster updates.
///
/// Bookmark behavior:
/// - Auto bookmarks: Max 1 per book, overwrites on close
/// - Manual bookmarks: Multiple per book, persistent across devices
@freezed
abstract class BookCloudMetadata with _$BookCloudMetadata {
  const factory BookCloudMetadata({
    /// The stable UUID of the book (matches IndexEntry.bookId)
    required String bookId,

    /// Current reading state (position, progress, timestamps)
    @ReadingStateConverter() required ReadingState readingState,

    /// List of bookmarks (auto and manual)
    @BookmarkEntryListConverter() required List<BookmarkEntry> bookmarks,
  }) = _BookCloudMetadata;

  const BookCloudMetadata._();

  factory BookCloudMetadata.fromJson(Map<String, dynamic> json) =>
      _$BookCloudMetadataFromJson(json);

  /// Gets the auto-resume bookmark (max 1 per book)
  ///
  /// Returns the auto bookmark entry if present, null otherwise.
  BookmarkEntry? getAutoBookmark() {
    for (final BookmarkEntry bookmark in bookmarks) {
      if (bookmark.type == BookmarkType.auto) {
        return bookmark;
      }
    }
    return null;
  }

  /// Gets all manual bookmarks (multiple per book)
  ///
  /// Returns a list of all manual bookmarks, sorted by timestamp (oldest first).
  List<BookmarkEntry> getManualBookmarks() {
    final List<BookmarkEntry> manuals = bookmarks
        .where((BookmarkEntry b) => b.type == BookmarkType.manual)
        .toList();
    manuals.sort((BookmarkEntry a, BookmarkEntry b) =>
        a.timestamp.compareTo(b.timestamp));
    return manuals;
  }

  /// Updates the auto-resume bookmark.
  ///
  /// Removes any existing auto bookmark and creates a new one with the
  /// given position. Only one auto bookmark per book is allowed.
  ///
  /// Parameters:
  ///   cfiPosition: The new reading position
  ///   timestamp: When this position was set (defaults to now)
  ///
  /// Returns: A new BookCloudMetadata with the updated auto bookmark
  BookCloudMetadata updateAutoBookmark(
    String cfiPosition, {
    DateTime? timestamp,
  }) {
    final List<BookmarkEntry> updatedBookmarks = bookmarks
        .where((BookmarkEntry b) => b.type != BookmarkType.auto)
        .toList();

    updatedBookmarks.add(
      BookmarkEntry(
        id: 'auto-${DateTime.now().millisecondsSinceEpoch}',
        cfiPosition: cfiPosition,
        timestamp: timestamp ?? DateTime.now(),
        type: BookmarkType.auto,
      ),
    );

    return copyWith(bookmarks: updatedBookmarks);
  }

  /// Adds a manual bookmark.
  ///
  /// Parameters:
  ///   bookmark: The bookmark to add
  ///
  /// Returns: A new BookCloudMetadata with the added bookmark
  BookCloudMetadata addManualBookmark(BookmarkEntry bookmark) {
    final List<BookmarkEntry> updated = <BookmarkEntry>[
      ...bookmarks,
      bookmark.copyWith(type: BookmarkType.manual),
    ];
    return copyWith(bookmarks: updated);
  }

  /// Removes a bookmark by ID.
  ///
  /// Parameters:
  ///   bookmarkId: The ID of the bookmark to remove
  ///
  /// Returns: A new BookCloudMetadata with the bookmark removed
  /// Returns unchanged if bookmark ID not found
  BookCloudMetadata removeBookmark(String bookmarkId) {
    final List<BookmarkEntry> updated =
        bookmarks.where((BookmarkEntry b) => b.id != bookmarkId).toList();
    return copyWith(bookmarks: updated);
  }
}
