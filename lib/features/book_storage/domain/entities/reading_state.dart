import 'package:freezed_annotation/freezed_annotation.dart';

part 'reading_state.freezed.dart';
part 'reading_state.g.dart';

/// Represents the reader's current position and progress in a book.
///
/// Updated silently every time the reader closes the book. This is not a
/// user-facing concept — it exists purely to enable auto-resume functionality.
@freezed
abstract class ReadingState with _$ReadingState {
  const factory ReadingState({
    /// EPUB Canonical Fragment Identifier position string.
    /// Identifies the exact location in the book (chapter/paragraph/etc).
    required String cfiPosition,

    /// Reading progress as a percentage (0.0 to 100.0).
    required double progress,

    /// Date and time of the last reading session.
    required DateTime lastReadTime,

    /// Total seconds spent reading this book.
    required int totalSeconds,
  }) = _ReadingState;

  const ReadingState._();

  factory ReadingState.fromJson(Map<String, dynamic> json) =>
      _$ReadingStateFromJson(json);
}
