import 'package:novel_glide/features/bookmark/domain/entities/bookmark_data.dart';
import 'package:novel_glide/features/bookmark/domain/repositories/bookmark_repository.dart';

/// Legacy use case - use BookmarkGetListUseCase instead.
@deprecated
class BookmarkGetDataUseCase {
  const BookmarkGetDataUseCase(this._repository);

  final BookmarkRepository _repository;

  Future<List<BookmarkData>> call(String bookId) async {
    // Legacy implementation - return empty list
    return <BookmarkData>[];
  }
}
