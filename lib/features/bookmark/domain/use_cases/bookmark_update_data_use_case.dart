import 'package:novel_glide/features/bookmark/domain/entities/bookmark_data.dart';
import 'package:novel_glide/features/bookmark/domain/repositories/bookmark_repository.dart';

/// Legacy use case - use BookmarkAddUseCase instead.
@deprecated
class BookmarkUpdateDataUseCase {
  const BookmarkUpdateDataUseCase(this._repository);

  final BookmarkRepository _repository;

  Future<void> call(BookmarkData bookmarkData) async {
    // Legacy implementation - no-op
  }
}
