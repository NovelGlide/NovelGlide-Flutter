abstract class ReaderServerRepository {
  Future<Uri> start(String bookIdentifier);

  Future<void> stop();
}
