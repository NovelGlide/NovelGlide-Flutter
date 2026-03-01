import '../entities/migration_step.dart';

/// Represents progress update during migration.
///
/// Emitted by RunMigrationUseCase through a Stream to update the
/// UI with current step, overall progress, and any errors.
class MigrationProgress {
  /// Creates a MigrationProgress instance.
  const MigrationProgress({
    required this.step,
    required this.progressPercent,
    required this.currentLabel,
    required this.processedBooks,
    required this.totalBooks,
    this.error,
  });

  /// The current migration step being executed.
  final MigrationStep step;

  /// Overall progress as a percentage (0-100).
  ///
  /// Calculated based on books processed vs total books.
  /// Updated after each book is processed.
  final int progressPercent;

  /// Human-readable label for current step.
  ///
  /// Examples:
  /// - "Downloading backup…"
  /// - "Enumerating books…"
  /// - "Building folder structure…"
  /// - "Migrating bookmarks (4 of 12)…"
  /// - "Clearing old files…"
  /// - "Enabling cloud sync…"
  final String currentLabel;

  /// Number of books processed so far.
  /// Updated after each book in steps 3+.
  final int processedBooks;

  /// Total number of books to migrate.
  final int totalBooks;

  /// Error information if step failed, otherwise null.
  ///
  /// When present, indicates that an error occurred and the user
  /// should be shown a retry button. The exception message can be
  /// displayed to the user (after sanitization).
  final Exception? error;

  /// Whether an error occurred during migration.
  bool get hasError => error != null;

  /// Creates a copy with updated fields.
  MigrationProgress copyWith({
    MigrationStep? step,
    int? progressPercent,
    String? currentLabel,
    int? processedBooks,
    int? totalBooks,
    Exception? error,
  }) {
    return MigrationProgress(
      step: step ?? this.step,
      progressPercent: progressPercent ?? this.progressPercent,
      currentLabel: currentLabel ?? this.currentLabel,
      processedBooks: processedBooks ?? this.processedBooks,
      totalBooks: totalBooks ?? this.totalBooks,
      error: error ?? this.error,
    );
  }

  @override
  String toString() {
    return 'MigrationProgress(step: $step, progress: $progressPercent%, '
        'processed: $processedBooks/$totalBooks, error: $error)';
  }
}
