import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:novel_glide/features/book_storage/domain/entities/bookmark_entry.dart';

part 'bookmark_item.freezed.dart';
part 'bookmark_item.g.dart';

/// Presentation entity for a bookmark with full context.
///
/// BookmarkItem represents a single bookmark with its associated book
/// information. It is used by the UI layer to display bookmarks with
/// complete context (book title, position, label, etc.).
///
/// The [position] field supports both CFI strings (e.g.,
/// "epubcfi(/6/4[chap01]!/4/2/16,1:10)") and chapter identifiers
/// (e.g., "chapter-01"). The format is generic to support multiple
/// location systems in EPUB.
@freezed
abstract class BookmarkItem with _$BookmarkItem {
  const factory BookmarkItem({
    /// Unique identifier for this bookmark (UUID).
    required String id,

    /// Book ID (folder identifier) where this bookmark exists.
    required String bookId,

    /// Title of the book containing this bookmark.
    required String bookTitle,

    /// Position string identifying the location in the book.
    /// Can be CFI string or chapter identifier.
    required String position,

    /// Optional user-defined label or note for this bookmark.
    String? label,

    /// Date and time when this bookmark was created.
    required DateTime createdAt,
  }) = _BookmarkItem;

  const BookmarkItem._();

  /// Creates a BookmarkItem from a BookmarkEntry and book title.
  ///
  /// Converts a domain-level [BookmarkEntry] (which has CFI position)
  /// along with the book title into a presentation-ready
  /// [BookmarkItem].
  factory BookmarkItem.fromBookmarkEntry(
    BookmarkEntry entry,
    String bookTitle,
    String bookId,
  ) {
    return BookmarkItem(
      id: entry.id,
      bookId: bookId,
      bookTitle: bookTitle,
      position: entry.cfiPosition,
      label: entry.label,
      createdAt: entry.timestamp,
    );
  }

  factory BookmarkItem.fromJson(Map<String, dynamic> json) =>
      _$BookmarkItemFromJson(json);
}
