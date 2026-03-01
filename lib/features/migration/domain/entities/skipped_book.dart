import 'package:freezed_annotation/freezed_annotation.dart';

part 'skipped_book.freezed.dart';
part 'skipped_book.g.dart';

/// Represents a book that failed to migrate during the process.
///
/// When a book cannot be processed (e.g., corrupt EPUB or
/// unreadable metadata), it is recorded in this class instead of
/// crashing the migration. The user is informed post-migration
/// about skipped books and can manually handle them if needed.
@freezed
class SkippedBook with _$SkippedBook {
  const factory SkippedBook({
    /// Original filename of the book that failed to migrate.
    required String originalFileName,

    /// Human-readable reason why the book was skipped.
    /// Examples: "Corrupt EPUB", "Unreadable metadata",
    /// "Missing file", "Invalid CFI"
    required String reason,

    /// Timestamp when the migration attempt was made.
    required DateTime attemptedAt,
  }) = _SkippedBook;

  factory SkippedBook.fromJson(Map<String, dynamic> json) =>
      _$SkippedBookFromJson(json);
}
