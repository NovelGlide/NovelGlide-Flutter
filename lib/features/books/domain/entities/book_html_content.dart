import 'package:equatable/equatable.dart';

import 'book_page.dart';

class BookHtmlContent extends Equatable {
  const BookHtmlContent({
    required this.bookIdentifier,
    required this.chapterIdentifier,
    required this.content,
    required this.stylesheet,
    required this.pageList,
  });

  final String bookIdentifier;
  final String chapterIdentifier;
  final String content;
  final String stylesheet;
  final List<BookPage> pageList;

  @override
  List<Object?> get props => <Object>[
        bookIdentifier,
        chapterIdentifier,
        content,
        stylesheet,
        pageList,
      ];
}
