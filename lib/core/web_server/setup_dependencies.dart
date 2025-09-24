import '../../main.dart';
import '../lifecycle/domain/repositories/lifecycle_repository.dart';
import 'data/data_sources/shelf_io_server_impl.dart';
import 'data/data_sources/web_server_data_source.dart';
import 'data/repositories/web_server_repository_impl.dart';
import 'domain/repositories/web_server_repository.dart';

void setupWebServerDependencies() {
  // Register data sources
  sl.registerLazySingleton<WebServerDataSource>(
    () => ShelfIoServerImpl(),
  );

  // Register repositories
  sl.registerLazySingleton<WebServerRepository>(
    () => WebServerRepositoryImpl(
      sl<WebServerDataSource>(),
      sl<LifecycleRepository>(),
    ),
  );
}
