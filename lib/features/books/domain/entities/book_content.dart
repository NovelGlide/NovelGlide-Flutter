import 'package:equatable/equatable.dart';

import 'book_page.dart';

class BookContent extends Equatable {
  const BookContent({
    required this.bookIdentifier,
    required this.chapterIdentifier,
    required this.styleFiles,
    required this.content,
    required this.pageList,
  });

  final String bookIdentifier;
  final String chapterIdentifier;
  final Map<String, String> styleFiles;
  final String content;
  final List<BookPage> pageList;

  @override
  List<Object?> get props => <Object>[
        bookIdentifier,
        chapterIdentifier,
        styleFiles,
        content,
        pageList,
      ];
}
