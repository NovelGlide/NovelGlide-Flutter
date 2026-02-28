import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:novel_glide/features/book_storage/domain/entities/bookmark_entry.dart';
import 'package:novel_glide/features/book_storage/domain/entities/reading_state.dart';

part 'book_metadata.freezed.dart';
part 'book_metadata.g.dart';

/// Metadata associated with a book stored in the library.
///
/// Contains the original filename, title, date added, current reading state,
/// and user-created bookmarks. This is serialized to metadata.json alongside
/// each book file.
@freezed
abstract class BookMetadata with _$BookMetadata {
  const factory BookMetadata({
    /// Original filename as it was when the book was added to the library.
    /// Used for display purposes only — has no structural role.
    required String originalFilename,

    /// The title of the book.
    required String title,

    /// Date and time when the book was added to the library.
    required DateTime dateAdded,

    /// Current reading state (position, progress, last read time, etc).
    /// Updated silently when the reader closes the book.
    required ReadingState readingState,

    /// List of user-created bookmarks in this book.
    required List<BookmarkEntry> bookmarks,
  }) = _BookMetadata;

  const BookMetadata._();

  factory BookMetadata.fromJson(Map<String, dynamic> json) =>
      _$BookMetadataFromJson(json);
}
