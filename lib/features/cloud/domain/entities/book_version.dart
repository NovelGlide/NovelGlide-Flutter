import 'package:freezed_annotation/freezed_annotation.dart';

part 'book_version.freezed.dart';
part 'book_version.g.dart';

/// A snapshot of a book's version in history.
///
/// Tracks metadata snapshots for recovery and versioning.
@freezed
abstract class BookVersion with _$BookVersion {
  const factory BookVersion({
    required String bookId,
    required DateTime timestamp,
    required int fileSize,
    required double readingProgress,
    required String metadataHash,
    required String epubHash,
  }) = _BookVersion;

  const BookVersion._();

  factory BookVersion.fromJson(Map<String, dynamic> json) =>
      _$BookVersionFromJson(json);
}
