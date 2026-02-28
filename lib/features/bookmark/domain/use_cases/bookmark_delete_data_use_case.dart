import 'package:novel_glide/features/bookmark/domain/repositories/bookmark_repository.dart';

/// Legacy use case - use BookmarkDeleteUseCase instead.
@deprecated
class BookmarkDeleteDataUseCase {
  const BookmarkDeleteDataUseCase(this._repository);

  final BookmarkRepository _repository;

  Future<void> call(Set<String> entryIds) async {
    // Legacy implementation - no-op
  }
}
