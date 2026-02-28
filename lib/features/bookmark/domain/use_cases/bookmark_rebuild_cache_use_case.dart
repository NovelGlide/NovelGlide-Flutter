import 'package:novel_glide/core/log_system/log_system.dart';
import 'package:novel_glide/features/bookmark/domain/repositories/bookmark_repository.dart';

/// Use case for rebuilding the bookmark cache.
///
/// Rebuilds the cache from scratch by reading all book metadata
/// and aggregating bookmarks. Use when the cache becomes corrupted
/// or to ensure consistency after offline changes.
class BookmarkRebuildCacheUseCase {
  /// Creates a [BookmarkRebuildCacheUseCase] instance.
  const BookmarkRebuildCacheUseCase({
    required BookmarkRepository bookmarkRepository,
  }) : _bookmarkRepository = bookmarkRepository;

  final BookmarkRepository _bookmarkRepository;

  /// Executes the use case.
  ///
  /// Returns a future that completes when the cache rebuild
  /// is done.
  Future<void> call() async {
    try {
      await _bookmarkRepository.rebuildCache();
    } catch (e, st) {
      LogSystem.error(
        'Error in BookmarkRebuildCacheUseCase: $e',
        stackTrace: st,
      );
    }
  }
}
