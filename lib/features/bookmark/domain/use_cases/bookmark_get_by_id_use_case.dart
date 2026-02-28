import 'package:novel_glide/core/log_system/log_system.dart';
import 'package:novel_glide/features/bookmark/domain/entities/bookmark_item.dart';
import 'package:novel_glide/features/bookmark/domain/repositories/bookmark_repository.dart';

/// Use case for retrieving a specific bookmark by ID.
///
/// Looks up a bookmark by its unique identifier and returns
/// the full [BookmarkItem] with context.
class BookmarkGetByIdUseCase {
  /// Creates a [BookmarkGetByIdUseCase] instance.
  const BookmarkGetByIdUseCase({
    required BookmarkRepository bookmarkRepository,
  }) : _bookmarkRepository = bookmarkRepository;

  final BookmarkRepository _bookmarkRepository;

  /// Executes the use case.
  ///
  /// [entryId] is the unique identifier of the bookmark.
  /// Returns a future that completes with the [BookmarkItem]
  /// if found, or null if not found.
  Future<BookmarkItem?> call(String entryId) async {
    try {
      return await _bookmarkRepository.getById(
        entryId,
      );
    } catch (e, st) {
      LogSystem.error(
        'Error in BookmarkGetByIdUseCase: $e',
        stackTrace: st,
      );
      return null;
    }
  }
}
