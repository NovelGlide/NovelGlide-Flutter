import '../repositories/migration_repository.dart';

/// Use case to increment the deferral count.
///
/// Called when user chooses "Remind me later" on the introduction screen.
/// Increments the deferral counter in persistent storage. Once this
/// reaches 3, the "Remind me later" button is hidden on next launch and
/// migration is forced to complete.
///
/// Resets automatically after successful migration completion.
class IncrementDeferralCountUseCase {
  /// Creates an IncrementDeferralCountUseCase.
  ///
  /// [repository] is the migration repository for persistence.
  IncrementDeferralCountUseCase({
    required MigrationRepository repository,
  }) : _repository = repository;

  final MigrationRepository _repository;

  /// Executes the use case.
  ///
  /// Returns: New deferral count after increment
  ///
  /// Throws: Exception on storage access errors
  Future<int> call() async {
    return _repository.incrementDeferralCount();
  }
}
