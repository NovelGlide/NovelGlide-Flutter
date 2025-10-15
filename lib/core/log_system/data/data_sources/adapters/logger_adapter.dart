import 'package:logger/logger.dart';

import '../log_data_source.dart';

class LoggerAdapter extends LogDataSource {
  LoggerAdapter();

  final Logger _logger = Logger(
    printer: PrettyPrinter(
      excludePaths: <String>[
        'package:novel_glide/core/log_system',
      ],
    ),
  );

  @override
  Future<void> info(String message) async {
    return _logger.i(message);
  }

  @override
  Future<void> warn(String message) async {
    return _logger.w(message);
  }

  @override
  Future<void> error(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Iterable<Object> information = const <Object>[],
  }) async {
    return _logger.e(message, error: error, stackTrace: stackTrace);
  }

  @override
  Future<void> fatal(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Iterable<Object> information = const <Object>[],
  }) async {
    return _logger.f(
      message,
      error: error,
      stackTrace: stackTrace,
    );
  }

  @override
  Future<void> event(String name, {Map<String, Object>? parameters}) async {
    return _logger.i('Event: $name\n$parameters');
  }
}
