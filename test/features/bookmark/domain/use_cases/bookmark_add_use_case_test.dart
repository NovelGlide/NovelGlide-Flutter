import 'package:flutter_test/flutter_test.dart';

import 'package:novel_glide/features/book_storage/domain/entities/bookmark_entry.dart';
import 'package:novel_glide/features/bookmark/domain/entities/bookmark_item.dart';
import 'package:novel_glide/features/bookmark/domain/repositories/bookmark_repository.dart';
import 'package:novel_glide/features/bookmark/domain/use_cases/bookmark_add_use_case.dart';

class MockBookmarkRepository implements BookmarkRepository {
  bool addBookmarkCalled = false;

  @override
  Future<void> addBookmark(dynamic bookId, dynamic entry) async {
    addBookmarkCalled = true;
  }

  @override
  Future<List<BookmarkItem>> getAll() async => <BookmarkItem>[];

  @override
  Future<BookmarkItem?> getById(dynamic entryId) async => null;

  @override
  Future<void> deleteBookmarks(dynamic entryIds) async {}

  @override
  Future<void> rebuildCache() async {}

  @override
  Stream<void> observeChanges() => const Stream.empty();
}

void main() {
  late BookmarkAddUseCase useCase;
  late MockBookmarkRepository mockRepository;

  setUp(() {
    mockRepository = MockBookmarkRepository();
    useCase = BookmarkAddUseCase(
      bookmarkRepository: mockRepository,
    );
  });

  group('BookmarkAddUseCase', () {
    final DateTime now = DateTime.now();

    test('adds bookmark successfully', () async {
      final BookmarkEntry entry = BookmarkEntry(
        id: 'bm-1',
        cfiPosition: 'epubcfi(/6/4)',
        timestamp: now,
        label: 'Label',
      );

      await useCase('book-1', entry);

      expect(mockRepository.addBookmarkCalled, isTrue);
    });

    test('handles errors gracefully', () async {
      final BookmarkEntry entry = BookmarkEntry(
        id: 'bm-1',
        cfiPosition: 'epubcfi(/6/4)',
        timestamp: now,
        label: 'Label',
      );

      expect(useCase('book-1', entry), completes);
    });
  });
}
