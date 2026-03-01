import '../repositories/migration_repository.dart';

/// Use case to retrieve the current deferral count.
///
/// The deferral system allows users to postpone migration up to 3 times.
/// After 3 deferrals, the "Remind me later" button is hidden and
/// migration must complete on next app launch.
///
/// Used on the migration introduction screen to determine whether to
/// show the deferral button.
class GetDeferralCountUseCase {
  /// Creates a GetDeferralCountUseCase.
  ///
  /// [repository] is the migration repository to query.
  GetDeferralCountUseCase({
    required MigrationRepository repository,
  }) : _repository = repository;

  final MigrationRepository _repository;

  /// Executes the use case.
  ///
  /// Returns: Current deferral count (typically 0-3)
  ///
  /// Throws: Exception on storage access errors
  Future<int> call() async {
    return _repository.getDeferralCount();
  }
}
