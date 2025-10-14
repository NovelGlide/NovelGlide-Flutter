import 'dart:typed_data';

import 'package:equatable/equatable.dart';

import 'book_page.dart';

class BookHtmlContent extends Equatable {
  const BookHtmlContent({
    required this.bookIdentifier,
    required this.pageIdentifier,
    required this.htmlContent,
    required this.textContent,
    required this.stylesheet,
    required this.pageList,
    required this.imgFiles,
  });

  final String bookIdentifier;
  final String pageIdentifier;
  final String htmlContent;
  final String textContent;
  final String stylesheet;
  final List<BookPage> pageList;
  final Map<String, Uint8List> imgFiles;

  @override
  List<Object?> get props => <Object>[
        bookIdentifier,
        pageIdentifier,
        htmlContent,
        textContent,
        stylesheet,
        pageList,
        imgFiles,
      ];
}
