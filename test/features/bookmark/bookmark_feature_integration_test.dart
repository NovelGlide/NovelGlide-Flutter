import 'package:flutter_test/flutter_test.dart';
import 'package:novel_glide/features/book_storage/domain/entities/book_metadata.dart';
import 'package:novel_glide/features/book_storage/domain/entities/bookmark_entry.dart';
import 'package:novel_glide/features/book_storage/domain/entities/reading_state.dart';
import 'package:novel_glide/features/bookmark/domain/entities/bookmark_item.dart';

void main() {
  group('Bookmark Feature Integration Tests', () {
    group('Scenario 1: Bookmark data persistence', () {
      test('should create BookmarkEntry with valid data', () {
        // Arrange
        const String id = 'bm-001';
        const String position = 'epubcfi(/6/4[chap01]!/4/2/16,1:10)';
        const String label = 'Important passage';
        final DateTime now = DateTime.now();

        // Act
        final BookmarkEntry entry = BookmarkEntry(
          id: id,
          cfiPosition: position,
          timestamp: now,
          label: label,
        );

        // Assert
        expect(entry.id, equals(id));
        expect(entry.cfiPosition, equals(position));
        expect(entry.label, equals(label));
        expect(entry.timestamp, equals(now));
      });

      test('should create BookmarkItem with all required fields', () {
        // Arrange & Act
        final BookmarkItem item = BookmarkItem(
          id: 'bm-001',
          bookId: 'book-a-001',
          bookTitle: 'Book A',
          position: 'epubcfi(/6/4[chap01]!/4/2/16,1:10)',
          label: 'First bookmark',
          createdAt: DateTime.now(),
        );

        // Assert
        expect(item.id, equals('bm-001'));
        expect(item.bookId, equals('book-a-001'));
        expect(item.bookTitle, equals('Book A'));
        expect(item.position, startsWith('epubcfi'));
        expect(item.label, equals('First bookmark'));
      });

      test('should handle BookmarkItem without label', () {
        // Arrange & Act
        final BookmarkItem item = BookmarkItem(
          id: 'bm-002',
          bookId: 'book-a-001',
          bookTitle: 'Book A',
          position: 'epubcfi(/6/4[chap02]!/4/2/16,1:10)',
          createdAt: DateTime.now(),
        );

        // Assert
        expect(item.label, isNull);
        expect(item.position, isNotEmpty);
      });
    });

    group('Scenario 2: Reading state management', () {
      test('should create ReadingState with CFI position', () {
        // Arrange
        const String cfiPosition = 'epubcfi(/6/4[chap01]!/4/2/16,1:10)';
        const double progress = 15.5;
        final DateTime lastRead = DateTime.now();
        const int totalSeconds = 3600;

        // Act
        final ReadingState state = ReadingState(
          cfiPosition: cfiPosition,
          progress: progress,
          lastReadTime: lastRead,
          totalSeconds: totalSeconds,
        );

        // Assert
        expect(state.cfiPosition, equals(cfiPosition));
        expect(state.progress, equals(15.5));
        expect(state.lastReadTime, equals(lastRead));
        expect(state.totalSeconds, equals(3600));
      });

      test('should track progress percentage', () {
        // Arrange
        final ReadingState state = ReadingState(
          cfiPosition: 'epubcfi(/6/4[c01]!/4/2/16,1:10)',
          progress: 33.33,
          lastReadTime: DateTime.now(),
          totalSeconds: 5000,
        );

        // Act & Assert
        expect(state.progress, equals(33.33));
        expect(state.progress >= 0.0 && state.progress <= 100.0, isTrue);
      });

      test('should track reading duration in seconds', () {
        // Arrange
        const int totalSeconds = 86400; // 24 hours
        final ReadingState state = ReadingState(
          cfiPosition: 'epubcfi(/6/4[c01]!/4/2/16,1:10)',
          progress: 50.0,
          lastReadTime: DateTime.now(),
          totalSeconds: totalSeconds,
        );

        // Act & Assert
        expect(state.totalSeconds, equals(86400));
      });
    });

    group('Scenario 3: BookMetadata management', () {
      test('should create BookMetadata with reading state', () {
        // Arrange
        const String title = 'Book A';
        const String filename = 'book-a.epub';
        final DateTime dateAdded = DateTime.now();
        final ReadingState readingState = ReadingState(
          cfiPosition: 'epubcfi(/6/4[chap01]!/4/2/16,1:10)',
          progress: 25.0,
          lastReadTime: DateTime.now(),
          totalSeconds: 5000,
        );

        // Act
        final BookMetadata metadata = BookMetadata(
          originalFilename: filename,
          title: title,
          dateAdded: dateAdded,
          readingState: readingState,
          bookmarks: const <BookmarkEntry>[],
        );

        // Assert
        expect(metadata.title, equals(title));
        expect(metadata.originalFilename, equals(filename));
        expect(metadata.readingState.cfiPosition,
            equals('epubcfi(/6/4[chap01]!/4/2/16,1:10)'));
        expect(metadata.bookmarks, isEmpty);
      });

      test('should include bookmarks in metadata', () {
        // Arrange
        final List<BookmarkEntry> bookmarks = <BookmarkEntry>[
          BookmarkEntry(
            id: 'bm-1',
            cfiPosition: 'epubcfi(/6/4[c01]!/4/2/16,1:10)',
            timestamp: DateTime.now(),
            label: 'First',
          ),
          BookmarkEntry(
            id: 'bm-2',
            cfiPosition: 'epubcfi(/6/4[c02]!/4/2/16,1:10)',
            timestamp: DateTime.now(),
            label: 'Second',
          ),
        ];

        final BookMetadata metadata = BookMetadata(
          originalFilename: 'book.epub',
          title: 'Book',
          dateAdded: DateTime.now(),
          readingState: ReadingState(
            cfiPosition: 'epubcfi(/6/4[c01]!/4/2/16,1:10)',
            progress: 20.0,
            lastReadTime: DateTime.now(),
            totalSeconds: 3600,
          ),
          bookmarks: bookmarks,
        );

        // Assert
        expect(metadata.bookmarks, hasLength(2));
        expect(metadata.bookmarks[0].label, equals('First'));
        expect(metadata.bookmarks[1].label, equals('Second'));
      });

      test('should update metadata with copyWith', () {
        // Arrange
        final BookMetadata original = BookMetadata(
          originalFilename: 'book.epub',
          title: 'Original Title',
          dateAdded: DateTime.now(),
          readingState: ReadingState(
            cfiPosition: 'epubcfi(/6/4[c01]!/4/2/16,1:10)',
            progress: 20.0,
            lastReadTime: DateTime.now(),
            totalSeconds: 3600,
          ),
          bookmarks: const <BookmarkEntry>[],
        );

        final ReadingState newState = ReadingState(
          cfiPosition: 'epubcfi(/6/4[c02]!/4/2/16,1:10)',
          progress: 30.0,
          lastReadTime: DateTime.now(),
          totalSeconds: 5400,
        );

        // Act
        final BookMetadata updated = original.copyWith(
          readingState: newState,
        );

        // Assert
        expect(updated.title, equals(original.title)); // Unchanged
        expect(updated.readingState.progress, equals(30.0)); // Updated
      });
    });

    group('Scenario 4: Multiple books organization', () {
      test('should organize bookmarks by book ID', () {
        // Arrange
        final List<BookmarkItem> bookmarks = <BookmarkItem>[
          BookmarkItem(
            id: 'bm-a-1',
            bookId: 'book-a',
            bookTitle: 'Book A',
            position: 'epubcfi(/6/4[c01]!/4/2/16,1:10)',
            createdAt: DateTime.now(),
          ),
          BookmarkItem(
            id: 'bm-b-1',
            bookId: 'book-b',
            bookTitle: 'Book B',
            position: 'epubcfi(/6/4[c01]!/4/2/16,1:10)',
            createdAt: DateTime.now(),
          ),
          BookmarkItem(
            id: 'bm-a-2',
            bookId: 'book-a',
            bookTitle: 'Book A',
            position: 'epubcfi(/6/4[c02]!/4/2/16,1:10)',
            createdAt: DateTime.now(),
          ),
        ];

        // Act - Organize by book ID
        final Map<String, List<BookmarkItem>> organized =
            <String, List<BookmarkItem>>{};
        for (final BookmarkItem bm in bookmarks) {
          if (!organized.containsKey(bm.bookId)) {
            organized[bm.bookId] = <BookmarkItem>[];
          }
          organized[bm.bookId]!.add(bm);
        }

        // Assert
        expect(organized.keys, hasLength(2));
        expect(organized['book-a'], hasLength(2));
        expect(organized['book-b'], hasLength(1));
      });

      test('should display correct book titles', () {
        // Arrange
        final BookmarkItem item1 = BookmarkItem(
          id: 'bm-1',
          bookId: 'book-1',
          bookTitle: 'The Great Gatsby',
          position: 'pos1',
          createdAt: DateTime.now(),
        );

        final BookmarkItem item2 = BookmarkItem(
          id: 'bm-2',
          bookId: 'book-2',
          bookTitle: 'Moby Dick',
          position: 'pos2',
          createdAt: DateTime.now(),
        );

        // Act & Assert
        expect(item1.bookTitle, equals('The Great Gatsby'));
        expect(item2.bookTitle, equals('Moby Dick'));
      });
    });

    group('Scenario 5: Position format support', () {
      test('should support CFI format positions', () {
        // Arrange
        const String cfiPosition =
            'epubcfi(/6/4[chap01]!/4/2/16,1:10)';

        // Act
        final BookmarkItem bookmark = BookmarkItem(
          id: 'bm-1',
          bookId: 'book-1',
          bookTitle: 'Book',
          position: cfiPosition,
          createdAt: DateTime.now(),
        );

        // Assert
        expect(bookmark.position, startsWith('epubcfi'));
        expect(bookmark.position, equals(cfiPosition));
      });

      test('should support chapter identifier format', () {
        // Arrange
        const String chapterPosition = 'chapter-05';

        // Act
        final BookmarkItem bookmark = BookmarkItem(
          id: 'bm-2',
          bookId: 'book-1',
          bookTitle: 'Book',
          position: chapterPosition,
          createdAt: DateTime.now(),
        );

        // Assert
        expect(bookmark.position, equals(chapterPosition));
      });
    });

    group('Scenario 6: Bookmark operations', () {
      test('should create bookmarks with timestamps', () {
        // Arrange
        final DateTime creationTime = DateTime.now();

        // Act
        final BookmarkEntry entry = BookmarkEntry(
          id: 'bm-001',
          cfiPosition: 'epubcfi(/6/4[c01]!/4/2/16,1:10)',
          timestamp: creationTime,
          label: 'Test bookmark',
        );

        // Assert
        expect(entry.timestamp, equals(creationTime));
      });

      test('should handle bookmark deletion by ID', () {
        // Arrange
        final List<BookmarkItem> bookmarks = <BookmarkItem>[
          BookmarkItem(
            id: 'bm-1',
            bookId: 'book-1',
            bookTitle: 'Book',
            position: 'pos1',
            createdAt: DateTime.now(),
          ),
          BookmarkItem(
            id: 'bm-2',
            bookId: 'book-1',
            bookTitle: 'Book',
            position: 'pos2',
            createdAt: DateTime.now(),
          ),
        ];

        // Act - Remove by ID
        const String toDelete = 'bm-1';
        final List<BookmarkItem> remaining =
            bookmarks.where((item) => item.id != toDelete).toList();

        // Assert
        expect(remaining, hasLength(1));
        expect(remaining[0].id, equals('bm-2'));
      });

      test('should sort bookmarks by date (newest first)', () {
        // Arrange
        final DateTime now = DateTime.now();
        final List<BookmarkItem> bookmarks = <BookmarkItem>[
          BookmarkItem(
            id: 'bm-1',
            bookId: 'book-1',
            bookTitle: 'Book',
            position: 'pos1',
            createdAt: now.subtract(const Duration(days: 2)),
          ),
          BookmarkItem(
            id: 'bm-2',
            bookId: 'book-1',
            bookTitle: 'Book',
            position: 'pos2',
            createdAt: now.subtract(const Duration(days: 1)),
          ),
          BookmarkItem(
            id: 'bm-3',
            bookId: 'book-1',
            bookTitle: 'Book',
            position: 'pos3',
            createdAt: now,
          ),
        ];

        // Act - Sort newest first
        bookmarks.sort((a, b) => b.createdAt.compareTo(a.createdAt));

        // Assert
        expect(bookmarks[0].id, equals('bm-3'));
        expect(bookmarks[1].id, equals('bm-2'));
        expect(bookmarks[2].id, equals('bm-1'));
      });
    });

    group('Scenario 7: Reading state persistence', () {
      test('should persist position on close', () {
        // Arrange
        const String position = 'epubcfi(/6/4[c05]!/4/2/16,1:10)';
        const double progress = 45.0;
        const int totalSeconds = 14400;

        final ReadingState state = ReadingState(
          cfiPosition: position,
          progress: progress,
          lastReadTime: DateTime.now(),
          totalSeconds: totalSeconds,
        );

        // Act - Simulate persistence
        final Map<String, dynamic> persisted = <String, dynamic>{
          'cfiPosition': state.cfiPosition,
          'progress': state.progress,
          'totalSeconds': state.totalSeconds,
        };

        // Assert
        expect(persisted['cfiPosition'], equals(position));
        expect(persisted['progress'], equals(progress));
        expect(persisted['totalSeconds'], equals(totalSeconds));
      });

      test('should load resume position on init', () {
        // Arrange
        final ReadingState savedState = ReadingState(
          cfiPosition: 'epubcfi(/6/4[c05]!/4/2/16,1:10)',
          progress: 45.0,
          lastReadTime: DateTime.now(),
          totalSeconds: 14400,
        );

        // Act - Simulate loading
        final ReadingState loadedState = ReadingState(
          cfiPosition: savedState.cfiPosition,
          progress: savedState.progress,
          lastReadTime: savedState.lastReadTime,
          totalSeconds: savedState.totalSeconds,
        );

        // Assert
        expect(loadedState.cfiPosition, equals(savedState.cfiPosition));
        expect(loadedState.progress, equals(savedState.progress));
      });
    });

    group('Edge cases and error handling', () {
      test('should handle empty bookmark list', () {
        // Arrange
        final BookMetadata metadata = BookMetadata(
          originalFilename: 'book.epub',
          title: 'Book',
          dateAdded: DateTime.now(),
          readingState: ReadingState(
            cfiPosition: 'epubcfi(/6/4[c01]!/4/2/16,1:10)',
            progress: 0.0,
            lastReadTime: DateTime.now(),
            totalSeconds: 0,
          ),
          bookmarks: const <BookmarkEntry>[],
        );

        // Act & Assert
        expect(metadata.bookmarks, isEmpty);
      });

      test('should handle null labels', () {
        // Arrange & Act
        final BookmarkItem item = BookmarkItem(
          id: 'bm-1',
          bookId: 'book-1',
          bookTitle: 'Book',
          position: 'epubcfi(/6/4[c01]!/4/2/16,1:10)',
          createdAt: DateTime.now(),
        );

        // Assert
        expect(item.label, isNull);
      });

      test('should preserve data types on copy', () {
        // Arrange
        final ReadingState original = ReadingState(
          cfiPosition: 'epubcfi(/6/4[c01]!/4/2/16,1:10)',
          progress: 50.0,
          lastReadTime: DateTime.now(),
          totalSeconds: 7200,
        );

        // Act
        final BookMetadata metadata = BookMetadata(
          originalFilename: 'book.epub',
          title: 'Book',
          dateAdded: DateTime.now(),
          readingState: original,
          bookmarks: const <BookmarkEntry>[],
        );

        // Assert
        expect(metadata.readingState.progress, isA<double>());
        expect(metadata.readingState.totalSeconds, isA<int>());
      });

      test('should handle date comparisons', () {
        // Arrange
        final DateTime date1 = DateTime(2026, 1, 1);
        final DateTime date2 = DateTime(2026, 1, 2);

        final BookmarkItem bm1 =
            BookmarkItem(
              id: 'bm-1',
              bookId: 'book-1',
              bookTitle: 'Book',
              position: 'pos1',
              createdAt: date1,
            );

        final BookmarkItem bm2 =
            BookmarkItem(
              id: 'bm-2',
              bookId: 'book-1',
              bookTitle: 'Book',
              position: 'pos2',
              createdAt: date2,
            );

        // Act & Assert
        expect(bm2.createdAt.isAfter(bm1.createdAt), isTrue);
        expect(bm1.createdAt.isBefore(bm2.createdAt), isTrue);
      });
    });
  });
}
