import 'dart:typed_data';

import 'package:equatable/equatable.dart';

import 'book_page.dart';

class BookHtmlContent extends Equatable {
  const BookHtmlContent({
    required this.bookIdentifier,
    required this.pageIdentifier,
    required this.content,
    required this.stylesheet,
    required this.pageList,
    required this.imgFiles,
  });

  final String bookIdentifier;
  final String pageIdentifier;
  final String content;
  final String stylesheet;
  final List<BookPage> pageList;
  final Map<String, Uint8List> imgFiles;

  @override
  List<Object?> get props => <Object>[
        bookIdentifier,
        pageIdentifier,
        content,
        stylesheet,
        pageList,
        imgFiles,
      ];
}
