import 'package:freezed_annotation/freezed_annotation.dart';
import 'migration_scenario.dart';

part 'migration_context.freezed.dart';

/// Shared context passed to all migration steps.
///
/// Contains the detected scenario, user choices, paths, and references
/// to repositories and services needed during migration. This is
/// created once at the start and passed through all steps, avoiding
/// repeated dependency injection.
@freezed
class MigrationContext with _$MigrationContext {
  const factory MigrationContext({
    /// The detected migration scenario (local/cloud/both/none).
    required MigrationScenario scenario,

    /// Temporary directory path where Library.zip is extracted.
    /// Used for reading downloaded books during migration.
    required String tempExtractionPath,

    /// User's choice whether to include cloud backup in merge.
    /// True if scenario is localAndCloud and user chose to merge.
    /// Ignored if scenario is not localAndCloud.
    required bool userChosenIncludeCloud,

    /// Total number of books to migrate across all sources.
    /// Calculated during enumeration step.
    required int totalBooksToMigrate,
  }) = _MigrationContext;
}
