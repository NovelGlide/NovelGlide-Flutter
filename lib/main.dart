import 'dart:isolate';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:get_it/get_it.dart';

import 'app/app.dart';
import 'core/log_system/log_system.dart';
import 'core/setup_dependencies.dart';
import 'firebase_options.dart';

final GetIt sl = GetIt.instance;

Future<void> main() async {
  debugRepaintRainbowEnabled = false;

  WidgetsFlutterBinding.ensureInitialized();

  // Setup dependencies
  await setupDependencies();

  // Firebase initializations
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Record Flutter error
  if (kReleaseMode) {
    FlutterError.onError = (FlutterErrorDetails errorDetails) {
      FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
    };
  }

  // Asynchronous errors
  PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    LogSystem.error('Asynchronous Error', error: error, stackTrace: stack);
    return true;
  };

  // Errors outside of Flutter
  Isolate.current.addErrorListener(RawReceivePort((List<dynamic> pair) async {
    final List<dynamic> errorAndStacktrace = pair;
    LogSystem.error(
      'Errors outside of Flutter',
      error: errorAndStacktrace.first,
      stackTrace: errorAndStacktrace.last,
    );
  }).sendPort);

  // Start App
  FirebaseAnalytics.instance.logAppOpen();
  runApp(const App());
}
