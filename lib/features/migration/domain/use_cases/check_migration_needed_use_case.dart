import '../repositories/migration_repository.dart';

/// Use case to check if migration is required.
///
/// Returns true if:
/// - migration_v1.done marker file does NOT exist, AND
/// - Either old Library/ folder OR Library.zip exists on Drive
///
/// Returns false if migration has already been completed.
///
/// This is typically called on app launch, before showing the UI,
/// to determine whether to show the migration wizard.
class CheckMigrationNeededUseCase {
  /// Creates a CheckMigrationNeededUseCase.
  ///
  /// [repository] is the migration repository to query.
  CheckMigrationNeededUseCase({
    required MigrationRepository repository,
  }) : _repository = repository;

  final MigrationRepository _repository;

  /// Executes the use case.
  ///
  /// Returns: true if migration is needed, false otherwise
  ///
  /// Throws: Exception on file system or network errors
  Future<bool> call() async {
    return _repository.isMigrationNeeded();
  }
}
