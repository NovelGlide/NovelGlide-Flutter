import '../../main.dart';
import 'domain/repositories/log_repository.dart';

class LogSystem {
  LogSystem(this._repository);

  final LogRepository _repository;

  void _info(String message) => _repository.info(message);

  void _warn(String message) => _repository.warn(message);

  void _error(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Iterable<Object> information = const <Object>[],
  }) =>
      _repository.error(
        message,
        error: error,
        stackTrace: stackTrace,
        information: information,
      );

  void _fatal(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Iterable<Object> information = const <Object>[],
  }) =>
      _repository.fatal(
        message,
        error: error,
        stackTrace: stackTrace,
        information: information,
      );

  void _event(String name, {Map<String, Object>? parameters}) =>
      _repository.event(name, parameters: parameters);

  /// Static members

  static void info(String message) => sl<LogSystem>()._info(message);

  static void warn(String message) => sl<LogSystem>()._warn(message);

  static void error(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Iterable<Object> information = const <Object>[],
  }) =>
      sl<LogSystem>()._error(
        message,
        error: error,
        stackTrace: stackTrace,
        information: information,
      );

  static void fatal(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Iterable<Object> information = const <Object>[],
  }) =>
      sl<LogSystem>()._fatal(
        message,
        error: error,
        stackTrace: stackTrace,
        information: information,
      );

  static void event(String name, {Map<String, Object>? parameters}) =>
      sl<LogSystem>()._event(name, parameters: parameters);
}
