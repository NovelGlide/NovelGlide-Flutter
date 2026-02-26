import '../../main.dart';
import 'data/repositories/app_font_loader_impl.dart';
import 'domain/repositories/app_font_loader.dart';
import 'domain/use_cases/app_font_loader_load_font.dart';

void setupAppFontLoaderDependencies() {
  /// Register the font loader.
  sl.registerLazySingleton<AppFontLoader>(
    () => AppFontLoaderImpl(),
  );

  /// Register all use-cases.
  sl.registerFactory<AppFontLoaderLoadCssFontUseCase>(
    () => AppFontLoaderLoadCssFontUseCase(
      sl<AppFontLoader>(),
    ),
  );
}
