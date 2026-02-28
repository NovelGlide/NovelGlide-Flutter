import 'package:novel_glide/features/bookmark/domain/repositories/bookmark_repository.dart';

/// Use case for observing bookmark changes.
///
/// Provides a stream of events whenever any bookmark is
/// created, modified, or deleted. Useful for reactive UI updates.
class BookmarkObserveChangeUseCase {
  /// Creates a [BookmarkObserveChangeUseCase] instance.
  const BookmarkObserveChangeUseCase({
    required BookmarkRepository bookmarkRepository,
  }) : _bookmarkRepository = bookmarkRepository;

  final BookmarkRepository _bookmarkRepository;

  /// Executes the use case.
  ///
  /// Returns a stream that emits whenever any bookmark changes.
  /// The stream never terminates (broadcast stream) and can have
  /// multiple subscribers.
  Stream<void> call() {
    return _bookmarkRepository.observeChanges();
  }
}
