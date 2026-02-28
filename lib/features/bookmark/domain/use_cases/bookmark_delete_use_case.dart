import 'package:novel_glide/core/log_system/log_system.dart';
import 'package:novel_glide/features/bookmark/domain/repositories/bookmark_repository.dart';

/// Use case for deleting bookmarks.
///
/// Removes one or more bookmarks by their IDs, updating
/// the underlying book metadata.
class BookmarkDeleteUseCase {
  /// Creates a [BookmarkDeleteUseCase] instance.
  const BookmarkDeleteUseCase({
    required BookmarkRepository bookmarkRepository,
  }) : _bookmarkRepository = bookmarkRepository;

  final BookmarkRepository _bookmarkRepository;

  /// Executes the use case.
  ///
  /// [entryIds] is a list of bookmark IDs to delete.
  /// Returns a future that completes when the operation is done.
  Future<void> call(List<String> entryIds) async {
    try {
      await _bookmarkRepository.deleteBookmarks(
        entryIds,
      );
    } catch (e, st) {
      LogSystem.error(
        'Error in BookmarkDeleteUseCase: $e',
        stackTrace: st,
      );
    }
  }
}
