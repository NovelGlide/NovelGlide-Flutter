import 'package:novel_glide/core/log_system/log_system.dart';
import 'package:novel_glide/features/bookmark/domain/entities/bookmark_item.dart';
import 'package:novel_glide/features/bookmark/domain/repositories/bookmark_repository.dart';

/// Use case for retrieving all bookmarks.
///
/// Fetches the complete list of bookmarks across all books,
/// sorted by creation time (newest first).
class BookmarkGetListUseCase {
  /// Creates a [BookmarkGetListUseCase] instance.
  const BookmarkGetListUseCase({
    required BookmarkRepository bookmarkRepository,
  }) : _bookmarkRepository = bookmarkRepository;

  final BookmarkRepository _bookmarkRepository;

  /// Executes the use case.
  ///
  /// Returns a future that completes with a list of all
  /// [BookmarkItem] instances.
  Future<List<BookmarkItem>> call() async {
    try {
      return await _bookmarkRepository.getAll();
    } catch (e, st) {
      LogSystem.error(
        'Error in BookmarkGetListUseCase: $e',
        stackTrace: st,
      );
      return <BookmarkItem>[];
    }
  }
}
