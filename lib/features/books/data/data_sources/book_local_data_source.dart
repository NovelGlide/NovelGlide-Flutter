import 'dart:typed_data';

import '../../../../core/mime_resolver/domain/entities/mime_type.dart';
import '../../domain/entities/book.dart';
import '../../domain/entities/book_chapter.dart';
import '../../domain/entities/book_cover.dart';

abstract class BookLocalDataSource {
  BookLocalDataSource();

  List<String> get allowedExtensions;
  List<MimeType> get allowedMimeTypes;

  Future<void> addBooks(Set<String> externalPathSet);

  Future<bool> exists(String identifier);

  Future<bool> delete(String identifier);

  Future<void> deleteAllBooks();

  Future<Book> getBook(String identifier);

  Stream<Book> getBooks([Set<String>? identifierSet]);

  Future<Uint8List> readBookBytes(String identifier);

  Future<BookCover> getCover(String identifier);

  Future<List<BookChapter>> getChapterList(String identifier);

  Future<String?> getContent(
    String identifier, {
    String? manifestHref,
  });

  // Validator
  Future<bool> isFileValid(String path);
}
