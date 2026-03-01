import '../entities/migration_state.dart';
import '../repositories/migration_repository.dart';

/// Use case to retrieve the last saved migration state.
///
/// If migration was interrupted (e.g., app crash), the state file
/// contains information about which steps were completed and which
/// books were already processed. This enables resumption from the
/// last successful checkpoint rather than restarting from scratch.
///
/// Returns null if no prior migration state exists (fresh start).
class GetMigrationStateUseCase {
  /// Creates a GetMigrationStateUseCase.
  ///
  /// [repository] is the migration repository to query.
  GetMigrationStateUseCase({
    required MigrationRepository repository,
  }) : _repository = repository;

  final MigrationRepository _repository;

  /// Executes the use case.
  ///
  /// Returns: Previous migration state if exists, null otherwise
  ///
  /// Throws: Exception on file system or JSON parse errors
  Future<MigrationState?> call() async {
    return _repository.getLastMigrationState();
  }
}
