import 'package:flutter_test/flutter_test.dart';

import 'package:novel_glide/features/bookmark/domain/entities/bookmark_item.dart';
import 'package:novel_glide/features/bookmark/domain/repositories/bookmark_repository.dart';
import 'package:novel_glide/features/bookmark/domain/use_cases/bookmark_delete_use_case.dart';

class MockBookmarkRepository implements BookmarkRepository {
  bool deleteBookmarksCalled = false;
  List<String> deletedIds = <String>[];

  @override
  Future<void> deleteBookmarks(List<String> entryIds) async {
    deleteBookmarksCalled = true;
    deletedIds = entryIds;
  }

  @override
  Future<List<BookmarkItem>> getAll() async => <BookmarkItem>[];

  @override
  Future<BookmarkItem?> getById(dynamic entryId) async => null;

  @override
  Future<void> addBookmark(dynamic bookId, dynamic entry) async {}

  @override
  Future<void> rebuildCache() async {}

  @override
  Stream<void> observeChanges() => const Stream.empty();
}

void main() {
  late BookmarkDeleteUseCase useCase;
  late MockBookmarkRepository mockRepository;

  setUp(() {
    mockRepository = MockBookmarkRepository();
    useCase = BookmarkDeleteUseCase(
      bookmarkRepository: mockRepository,
    );
  });

  group('BookmarkDeleteUseCase', () {
    test('deletes bookmarks successfully', () async {
      await useCase(<String>['bm-1', 'bm-2']);

      expect(mockRepository.deleteBookmarksCalled, isTrue);
      expect(mockRepository.deletedIds, equals(['bm-1', 'bm-2']));
    });

    test('handles empty list', () async {
      await useCase(<String>[]);

      expect(mockRepository.deleteBookmarksCalled, isTrue);
      expect(mockRepository.deletedIds, isEmpty);
    });

    test('handles errors gracefully', () async {
      expect(useCase(<String>['bm-1']), completes);
    });
  });
}
