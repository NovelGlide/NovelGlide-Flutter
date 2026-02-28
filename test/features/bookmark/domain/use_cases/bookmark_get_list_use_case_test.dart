import 'package:flutter_test/flutter_test.dart';

import 'package:novel_glide/features/bookmark/domain/entities/bookmark_item.dart';
import 'package:novel_glide/features/bookmark/domain/repositories/bookmark_repository.dart';
import 'package:novel_glide/features/bookmark/domain/use_cases/bookmark_get_list_use_case.dart';

class MockBookmarkRepository implements BookmarkRepository {
  List<BookmarkItem> _items = <BookmarkItem>[];

  void setItems(List<BookmarkItem> items) {
    _items = items;
  }

  void throwError(Exception error) {
    _error = error;
  }

  Exception? _error;

  @override
  Future<List<BookmarkItem>> getAll() async {
    if (_error != null) throw _error!;
    return _items;
  }

  @override
  Future<void> addBookmark(dynamic bookId, dynamic entry) async {}

  @override
  Future<void> deleteBookmarks(dynamic entryIds) async {}

  @override
  Future<BookmarkItem?> getById(dynamic entryId) async => null;

  @override
  Future<void> rebuildCache() async {}

  @override
  Stream<void> observeChanges() => const Stream.empty();
}

void main() {
  late BookmarkGetListUseCase useCase;
  late MockBookmarkRepository mockRepository;

  setUp(() {
    mockRepository = MockBookmarkRepository();
    useCase = BookmarkGetListUseCase(
      bookmarkRepository: mockRepository,
    );
  });

  group('BookmarkGetListUseCase', () {
    final DateTime now = DateTime.now();

    test('returns list of bookmarks', () async {
      final BookmarkItem item1 = BookmarkItem(
        id: 'bm-1',
        bookId: 'book-1',
        bookTitle: 'Book 1',
        position: 'epubcfi(/6/4)',
        label: 'Label 1',
        createdAt: now,
      );

      mockRepository.setItems(<BookmarkItem>[item1]);

      final List<BookmarkItem> result = await useCase();

      expect(result, hasLength(1));
      expect(result[0].id, equals('bm-1'));
    });

    test('returns empty list when no bookmarks', () async {
      mockRepository.setItems(<BookmarkItem>[]);

      final List<BookmarkItem> result = await useCase();

      expect(result, isEmpty);
    });

    test('handles errors gracefully', () async {
      mockRepository.throwError(Exception('Error'));

      final List<BookmarkItem> result = await useCase();

      expect(result, isEmpty);
    });
  });
}
