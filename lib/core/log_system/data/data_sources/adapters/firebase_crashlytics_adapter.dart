import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

import '../log_data_source.dart';

class FirebaseCrashlyticsAdapter extends LogDataSource {
  FirebaseCrashlyticsAdapter(this._instance);

  final FirebaseCrashlytics _instance;
  final bool _enableLogging = kReleaseMode;

  @override
  Future<void> error(
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) async {
    if (_enableLogging) {
      return _instance.recordError(
        error,
        stackTrace,
        reason: message,
        fatal: false,
      );
    }
  }

  @override
  Future<void> fatal(
    String message, {
    Object? error,
    StackTrace? stackTrace,
  }) async {
    if (_enableLogging) {
      return _instance.recordError(
        error,
        stackTrace,
        reason: message,
        fatal: true,
      );
    }
  }

  @override
  Future<void> info(String message) async {
    if (_enableLogging) {
      return _instance.log('Info: $message');
    }
  }

  @override
  Future<void> event(
    String name, {
    Map<String, dynamic>? parameters,
  }) async {
    // No-ops
  }
}
