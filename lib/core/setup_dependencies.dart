import 'package:shared_preferences/shared_preferences.dart';

import '../app/cubit/app_cubit.dart';
import '../features/advertisement/setup_dependencies.dart';
import '../features/appearance/setup_dependencies.dart';
import '../features/auth/setup_dependencies.dart';
import '../features/backup/setup_dependencies.dart';
import '../features/bookmark/setup_dependencies.dart';
import '../features/books/setup_dependencies.dart';
import '../features/cloud/setup_dependencies.dart';
import '../features/collection/setup_dependencies.dart';
import '../features/download_manager/setup_dependencies.dart';
import '../features/explore/setup_dependencies.dart';
import '../features/locale_system/setup_dependencies.dart';
import '../features/manual/setup_dependencies.dart';
import '../features/pick_file/setup_dependencies.dart';
import '../features/preference/domain/use_cases/preference_get_use_cases.dart';
import '../features/preference/domain/use_cases/preference_observe_change_use_case.dart';
import '../features/preference/domain/use_cases/preference_save_use_case.dart';
import '../features/preference/setup_dependencies.dart';
import '../features/reader/setup_dependencies.dart';
import '../features/tts_service/setup_dependencies.dart';
import '../main.dart';
import 'css_parser/setup_dependencies.dart';
import 'file_system/setup_dependencies.dart';
import 'http_client/setup_dependencies.dart';
import 'lifecycle/setup_dependencies.dart';
import 'log_system/setup_dependencies.dart';
import 'mime_resolver/setup_dependencies.dart';
import 'path_provider/setup_dependencies.dart';
import 'web_server/setup_dependencies.dart';

Future<void> setupDependencies() async {
  // Setup external dependencies
  _setupExternalDependencies();

  // Wait for asynchronous initialization done.
  await sl.allReady();

  // Setup the core function
  _setupCoreDependencies();

  // Dependencies injection for all features
  _setupSystemsDependencies();

  // Dependencies injection for app
  _setupAppDependencies();

  // Wait for all asynchronous initialization done.
  await sl.allReady();
}

void _setupExternalDependencies() {
  if (!sl.isRegistered<SharedPreferences>()) {
    sl.registerSingletonAsync<SharedPreferences>(
      () => SharedPreferences.getInstance(),
    );
  }
}

void _setupCoreDependencies() {
  setupCssParserDependencies();
  setupFileSystemDependencies();
  setupLifecycleDependencies();
  setupMimeResolverDependencies();
  setupPathProviderDependencies();
  setupHttpClientDependencies();
  setupWebServerDependencies();
}

void _setupSystemsDependencies() {
  setupAdDependencies();
  setupAppearanceDependencies();
  setupAuthDependencies();
  setupBackupDependencies();
  setupBookDependencies();
  setupBookmarkDependencies();
  setupCollectionDependencies();
  setupCloudDependencies();
  setupDownloaderDependencies();
  setupExploreDependencies();
  setupLocaleDependencies();
  setupLogDependencies();
  setupManualDependencies();
  setupPickFileDependencies();
  setupPreferenceDependencies();
  setupReaderDependencies();
  setupTtsDependencies();
}

void _setupAppDependencies() {
  sl.registerSingletonAsync<AppCubit>(() async {
    final AppCubit cubit = AppCubit(
      sl<AppearanceGetPreferenceUseCase>(),
      sl<AppearanceSavePreferenceUseCase>(),
      sl<AppearanceObservePreferenceChangeUseCase>(),
      sl<LocaleGetPreferenceUseCase>(),
      sl<LocaleSavePreferenceUseCase>(),
      sl<LocaleObservePreferenceChangeUseCase>(),
    );
    await cubit.init();
    return cubit;
  });
}
