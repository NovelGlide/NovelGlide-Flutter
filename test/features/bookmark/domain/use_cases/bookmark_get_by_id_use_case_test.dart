import 'package:flutter_test/flutter_test.dart';

import 'package:novel_glide/features/bookmark/domain/entities/bookmark_item.dart';
import 'package:novel_glide/features/bookmark/domain/repositories/bookmark_repository.dart';
import 'package:novel_glide/features/bookmark/domain/use_cases/bookmark_get_by_id_use_case.dart';

class MockBookmarkRepository implements BookmarkRepository {
  BookmarkItem? _item;
  Exception? _error;

  void setItem(BookmarkItem? item) {
    _item = item;
  }

  void throwError(Exception error) {
    _error = error;
  }

  @override
  Future<BookmarkItem?> getById(String entryId) async {
    if (_error != null) throw _error!;
    return _item;
  }

  @override
  Future<List<BookmarkItem>> getAll() async => <BookmarkItem>[];

  @override
  Future<void> addBookmark(dynamic bookId, dynamic entry) async {}

  @override
  Future<void> deleteBookmarks(dynamic entryIds) async {}

  @override
  Future<void> rebuildCache() async {}

  @override
  Stream<void> observeChanges() => const Stream.empty();
}

void main() {
  late BookmarkGetByIdUseCase useCase;
  late MockBookmarkRepository mockRepository;

  setUp(() {
    mockRepository = MockBookmarkRepository();
    useCase = BookmarkGetByIdUseCase(
      bookmarkRepository: mockRepository,
    );
  });

  group('BookmarkGetByIdUseCase', () {
    final DateTime now = DateTime.now();

    test('returns bookmark when found', () async {
      final BookmarkItem item = BookmarkItem(
        id: 'bm-1',
        bookId: 'book-1',
        bookTitle: 'Book 1',
        position: 'epubcfi(/6/4)',
        label: 'Label 1',
        createdAt: now,
      );

      mockRepository.setItem(item);

      final BookmarkItem? result = await useCase('bm-1');

      expect(result, isNotNull);
      expect(result?.id, equals('bm-1'));
    });

    test('returns null when not found', () async {
      mockRepository.setItem(null);

      final BookmarkItem? result = await useCase('bm-not-found');

      expect(result, isNull);
    });

    test('handles errors gracefully', () async {
      mockRepository.throwError(Exception('Error'));

      final BookmarkItem? result = await useCase('bm-1');

      expect(result, isNull);
    });
  });
}
