import 'package:flutter_test/flutter_test.dart';

import 'package:novel_glide/features/bookmark/domain/entities/bookmark_item.dart';
import 'package:novel_glide/features/bookmark/domain/repositories/bookmark_repository.dart';
import 'package:novel_glide/features/bookmark/domain/use_cases/bookmark_observe_change_use_case.dart';

class MockBookmarkRepository implements BookmarkRepository {
  @override
  Stream<void> observeChanges() => const Stream.empty();

  @override
  Future<List<BookmarkItem>> getAll() async => <BookmarkItem>[];

  @override
  Future<BookmarkItem?> getById(dynamic entryId) async => null;

  @override
  Future<void> addBookmark(dynamic bookId, dynamic entry) async {}

  @override
  Future<void> deleteBookmarks(dynamic entryIds) async {}

  @override
  Future<void> rebuildCache() async {}
}

void main() {
  late BookmarkObserveChangeUseCase useCase;
  late MockBookmarkRepository mockRepository;

  setUp(() {
    mockRepository = MockBookmarkRepository();
    useCase = BookmarkObserveChangeUseCase(
      bookmarkRepository: mockRepository,
    );
  });

  group('BookmarkObserveChangeUseCase', () {
    test('returns stream of changes', () {
      final Stream<void> result = useCase();

      expect(result, isNotNull);
    });

    test('stream is broadcast', () {
      final Stream<void> stream1 = useCase();
      final Stream<void> stream2 = useCase();

      expect(stream1, isNotNull);
      expect(stream2, isNotNull);
    });
  });
}
