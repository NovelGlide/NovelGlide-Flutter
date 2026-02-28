import 'package:novel_glide/features/bookmark/domain/repositories/bookmark_repository.dart';

/// Legacy use case - use BookmarkRebuildCacheUseCase instead.
@deprecated
class BookmarkResetUseCase {
  const BookmarkResetUseCase(this._repository);

  final BookmarkRepository _repository;

  Future<void> call() async {
    // Legacy implementation - no-op
  }
}
