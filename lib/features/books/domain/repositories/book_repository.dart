import 'dart:async';
import 'dart:typed_data';

import '../entities/book.dart';
import '../entities/book_chapter.dart';
import '../entities/book_cover.dart';
import '../entities/book_html_content.dart';
import '../entities/book_pick_file_data.dart';

abstract class BookRepository {
  List<String> get allowedExtensions;

  StreamController<void> get onChangedController;

  Future<void> addBooks(Set<String> externalPathSet);

  Future<bool> exists(String identifier);

  Future<bool> delete(Set<String> identifierSet);

  Future<Book> getBook(String identifier);

  Stream<Book> getBooks([Set<String>? identifierSet]);

  Future<Set<BookPickFileData>> pickBooks();

  Future<Uint8List> readBookBytes(String identifier);

  Future<BookCover> getCover(String identifier);

  Future<List<BookChapter>> getChapterList(String identifier);

  Future<BookHtmlContent> getContent(
    String identifier, {
    String? chapterIdentifier,
  });

  Future<void> reset();

  Future<bool> isFileValid(String path);
}
