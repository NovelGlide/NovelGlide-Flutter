abstract class LogDataSource {
  Future<void> info(String message);

  Future<void> warn(String message);

  Future<void> error(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Iterable<Object> information,
  });

  Future<void> fatal(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Iterable<Object> information,
  });

  Future<void> event(String name, {Map<String, Object>? parameters});
}
