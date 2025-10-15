import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';

import '../../main.dart';
import 'data/data_sources/adapters/firebase_analytics_adapter.dart';
import 'data/data_sources/adapters/firebase_crashlytics_adapter.dart';
import 'data/data_sources/adapters/logger_adapter.dart';
import 'data/repositories/log_repository_impl.dart';
import 'domain/repositories/log_repository.dart';
import 'log_system.dart';

void setupLogDependencies() {
  // Register Logger for console logging.
  sl.registerLazySingleton<LoggerAdapter>(() => LoggerAdapter());

  // Register FirebaseCrashlytics.
  sl.registerLazySingleton<FirebaseCrashlyticsAdapter>(
      () => FirebaseCrashlyticsAdapter(FirebaseCrashlytics.instance));

  // Register FirebaseCrashlytics.
  sl.registerLazySingleton<FirebaseAnalyticsAdapter>(
      () => FirebaseAnalyticsAdapter(FirebaseAnalytics.instance));

  // Register LogRepository
  sl.registerLazySingleton<LogRepository>(() => LogRepositoryImpl(
        sl<LoggerAdapter>(),
        sl<FirebaseCrashlyticsAdapter>(),
        sl<FirebaseAnalyticsAdapter>(),
      ));

  // Register LogSystem
  sl.registerLazySingleton<LogSystem>(() => LogSystem(sl<LogRepository>()));
}
