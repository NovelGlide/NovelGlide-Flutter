import 'package:freezed_annotation/freezed_annotation.dart';
import 'migration_step.dart';
import 'skipped_book.dart';

part 'migration_state.freezed.dart';
part 'migration_state.g.dart';

/// Represents the complete state of the migration process.
///
/// This immutable class tracks all aspects of the migration:
/// which steps have completed, which books have been processed,
/// what mappings have been created, and which books were skipped.
///
/// The state is persisted to migration_state.json after each step
/// to enable resumption if the migration is interrupted.
@freezed
class MigrationState with _$MigrationState {
  const factory MigrationState({
    /// Schema version for forward/backward compatibility.
    /// Currently version 1.
    required int version,

    /// Current step being executed.
    required MigrationStep currentStep,

    /// Map tracking which steps have been completed.
    /// Key: step enum value as string, Value: true if completed
    required Map<String, bool> stepStatus,

    /// List of book filenames downloaded from Library.zip.
    /// Empty if no cloud backup was downloaded.
    required List<String> downloadedBooks,

    /// List of book filenames found in local Library/ folder.
    required List<String> localBooks,

    /// Mapping from original filename to generated BookId.
    /// Created during step 3 and used in steps 4-8.
    required Map<String, String> fileNameToBookId,

    /// List of books that failed to migrate and why.
    /// Reported to user after migration completes.
    required List<SkippedBook> skippedBooks,

    /// Total number of books to migrate.
    /// Set during step 2 (enumeration).
    required int totalBooks,

    /// Number of books successfully processed so far.
    /// Updated after each book in steps 3+.
    required int processedBooks,
  }) = _MigrationState;

  factory MigrationState.fromJson(Map<String, dynamic> json) =>
      _$MigrationStateFromJson(json);
}

/// Factory for creating initial migration state.
extension MigrationStateFactory on MigrationState {
  /// Creates a fresh migration state for a new migration.
  static MigrationState initial(MigrationStep startStep) {
    return MigrationState(
      version: 1,
      currentStep: startStep,
      stepStatus: {},
      downloadedBooks: [],
      localBooks: [],
      fileNameToBookId: {},
      skippedBooks: [],
      totalBooks: 0,
      processedBooks: 0,
    );
  }

  /// Returns a copy with updated current step.
  MigrationState copyWithStep(MigrationStep newStep) {
    return copyWith(currentStep: newStep);
  }

  /// Returns a copy with current step marked as complete.
  MigrationState markCurrentStepComplete() {
    final updated = Map<String, bool>.from(stepStatus);
    updated[currentStep.toString()] = true;
    return copyWith(stepStatus: updated);
  }

  /// Checks if a specific step has been completed.
  bool isStepComplete(MigrationStep step) {
    return stepStatus[step.toString()] ?? false;
  }

  /// Checks if all steps have been completed.
  bool get isComplete {
    return MigrationStep.values.every(isStepComplete);
  }

  /// Calculates progress percentage (0-100).
  int get progressPercent {
    if (totalBooks == 0) return 0;
    return ((processedBooks / totalBooks) * 100).toInt();
  }
}
