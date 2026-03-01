import 'package:get_it/get_it.dart';

import 'data/repositories/migration_repository_impl.dart';
import 'domain/repositories/migration_repository.dart';
import 'domain/use_cases/check_migration_needed_use_case.dart';
import 'domain/use_cases/get_deferral_count_use_case.dart';
import 'domain/use_cases/get_migration_state_use_case.dart';
import 'domain/use_cases/increment_deferral_count_use_case.dart';
import 'domain/use_cases/run_migration_use_case.dart';

/// Sets up all dependencies for the migration feature.
///
/// This function should be called during app startup, after all other
/// feature dependencies have been set up:
/// - setupBookStorageDependencies()
/// - setupBookmarkDependencies()
/// - setupCollectionDependencies()
/// - setupCloudDependencies()
///
/// Then call setupMigrationDependencies() to wire up the migration
/// feature with its dependencies.
///
/// Example:
/// ```dart
/// void main() {
///   setupBookStorageDependencies();
///   setupBookmarkDependencies();
///   setupCollectionDependencies();
///   setupCloudDependencies();
///   setupMigrationDependencies();
///   runApp(const MyApp());
/// }
/// ```
void setupMigrationDependencies() {
  final getIt = GetIt.instance;

  // Repository
  getIt.registerSingleton<MigrationRepository>(
    MigrationRepositoryImpl(),
  );

  // Use cases
  getIt.registerSingleton<CheckMigrationNeededUseCase>(
    CheckMigrationNeededUseCase(
      repository: getIt<MigrationRepository>(),
    ),
  );

  getIt.registerSingleton<GetDeferralCountUseCase>(
    GetDeferralCountUseCase(
      repository: getIt<MigrationRepository>(),
    ),
  );

  getIt.registerSingleton<IncrementDeferralCountUseCase>(
    IncrementDeferralCountUseCase(
      repository: getIt<MigrationRepository>(),
    ),
  );

  getIt.registerSingleton<GetMigrationStateUseCase>(
    GetMigrationStateUseCase(
      repository: getIt<MigrationRepository>(),
    ),
  );

  getIt.registerSingleton<RunMigrationUseCase>(
    RunMigrationUseCase(
      repository: getIt<MigrationRepository>(),
    ),
  );
}
