import 'package:freezed_annotation/freezed_annotation.dart';

part 'bookmark_entry.freezed.dart';
part 'bookmark_entry.g.dart';

/// Enum for bookmark entry types.
///
/// - auto: Resume position (max 1 per book, overwrites on close)
/// - manual: User-created bookmarks (multiple allowed, persistent)
enum BookmarkType {
  /// Auto-generated resume position bookmark.
  /// Only one per book, automatically created/updated.
  /// Represents where the user last stopped reading.
  @JsonValue('auto')
  auto,

  /// User-created manual bookmark.
  /// Multiple per book, persist across sessions.
  /// Created by explicit user action.
  @JsonValue('manual')
  manual,
}

/// A user-created saved position in a book.
///
/// Bookmarks can be either auto-generated resume positions or user-created
/// manual bookmarks. Auto-resume is exclusive (max 1 per book), while manual
/// bookmarks are multiple and persistent.
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

    /// Type of this bookmark entry.
    ///
    /// - auto: Auto-generated resume position (max 1 per book)
    /// - manual: User-created bookmark (multiple per book)
    @Default(BookmarkType.manual) BookmarkType type,
  }) = _BookmarkEntry;

  const BookmarkEntry._();

  factory BookmarkEntry.fromJson(Map<String, dynamic> json) =>
      _$BookmarkEntryFromJson(json);
}
