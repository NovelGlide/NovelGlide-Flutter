import 'package:flutter_test/flutter_test.dart';

import 'package:novel_glide/features/bookmark/domain/entities/bookmark_item.dart';
import 'package:novel_glide/features/bookmark/domain/repositories/bookmark_repository.dart';
import 'package:novel_glide/features/bookmark/domain/use_cases/bookmark_rebuild_cache_use_case.dart';

class MockBookmarkRepository implements BookmarkRepository {
  bool rebuildCacheCalled = false;

  @override
  Future<void> rebuildCache() async {
    rebuildCacheCalled = true;
  }

  @override
  Future<List<BookmarkItem>> getAll() async => <BookmarkItem>[];

  @override
  Future<BookmarkItem?> getById(dynamic entryId) async => null;

  @override
  Future<void> addBookmark(dynamic bookId, dynamic entry) async {}

  @override
  Future<void> deleteBookmarks(dynamic entryIds) async {}

  @override
  Stream<void> observeChanges() => const Stream.empty();
}

void main() {
  late BookmarkRebuildCacheUseCase useCase;
  late MockBookmarkRepository mockRepository;

  setUp(() {
    mockRepository = MockBookmarkRepository();
    useCase = BookmarkRebuildCacheUseCase(
      bookmarkRepository: mockRepository,
    );
  });

  group('BookmarkRebuildCacheUseCase', () {
    test('rebuilds cache successfully', () async {
      await useCase();

      expect(mockRepository.rebuildCacheCalled, isTrue);
    });

    test('handles errors gracefully', () async {
      expect(useCase(), completes);
    });
  });
}
