import 'package:firebase_analytics/firebase_analytics.dart';

import '../log_data_source.dart';

class FirebaseAnalyticsAdapter extends LogDataSource {
  FirebaseAnalyticsAdapter(this._analytics);

  final FirebaseAnalytics _analytics;

  @override
  Future<void> info(String message) {
    return _analytics.logEvent(
      name: 'info_log',
      parameters: <String, Object>{'message': message},
    );
  }

  @override
  Future<void> warn(String message) {
    return _analytics.logEvent(
      name: 'warning_log',
      parameters: <String, Object>{'message': message},
    );
  }

  @override
  Future<void> error(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Iterable<Object> information = const <Object>[],
  }) {
    return _analytics.logEvent(
      name: 'error_log',
      parameters: <String, Object>{
        'message': message,
        'error_type': error?.runtimeType.toString() ?? 'RuntimeType is null',
      },
    );
  }

  @override
  Future<void> fatal(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Iterable<Object> information = const <Object>[],
  }) {
    return _analytics.logEvent(
      name: 'fatal_error',
      parameters: <String, Object>{
        'message': message,
        'error_type': error?.runtimeType.toString() ?? 'RuntimeType is null',
      },
    );
  }

  @override
  Future<void> event(String name, {Map<String, Object>? parameters}) {
    return _analytics.logEvent(name: name, parameters: parameters);
  }
}
