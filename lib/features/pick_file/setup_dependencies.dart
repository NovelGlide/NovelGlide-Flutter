import '../../main.dart';
import 'data/data_sources/impl/pick_file_local_data_source_impl.dart';
import 'data/data_sources/pick_file_local_data_source.dart';
import 'data/repositories/pick_file_repository_impl.dart';
import 'domain/repositories/pick_file_repository.dart';
import 'domain/use_cases/pick_file_clear_temp_use_case.dart';

void setupPickFileDependencies() {
  // Register data sources
  sl.registerLazySingleton<PickFileLocalDataSource>(
    () => PickFileLocalDataSourceImpl(),
  );

  // Register repositories
  sl.registerLazySingleton<PickFileRepository>(
    () => PickFileRepositoryImpl(
      sl<PickFileLocalDataSource>(),
    ),
  );

  // Register use cases
  sl.registerFactory<PickFileClearTempUseCase>(
    () => PickFileClearTempUseCase(
      sl<PickFileRepository>(),
    ),
  );
}
