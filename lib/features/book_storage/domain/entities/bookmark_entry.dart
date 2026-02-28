import 'package:freezed_annotation/freezed_annotation.dart';

part 'bookmark_entry.freezed.dart';
part 'bookmark_entry.g.dart';

/// A user-created saved position in a book.
///
/// Bookmarks are always created explicitly by the user. Auto-resume is
/// handled entirely by [ReadingState], not by bookmarks.
@freezed
abstract class BookmarkEntry with _$BookmarkEntry {
  const factory BookmarkEntry({
    /// Unique identifier for this bookmark.
    required String id,

    /// EPUB Canonical Fragment Identifier position string.
    /// Identifies the exact location in the book where this bookmark was created.
    required String cfiPosition,

    /// Date and time when this bookmark was created.
    required DateTime timestamp,

    /// Optional user-defined label or note for this bookmark.
    String? label,
  }) = _BookmarkEntry;

  const BookmarkEntry._();

  factory BookmarkEntry.fromJson(Map<String, dynamic> json) =>
      _$BookmarkEntryFromJson(json);
}
