import 'dart:typed_data';

import 'package:equatable/equatable.dart';
import 'package:html/dom.dart';

import 'book_page.dart';

class BookHtmlContent extends Equatable {
  const BookHtmlContent({
    required this.bookIdentifier,
    required this.pageIdentifier,
    required this.domTree,
    required this.textContent,
    required this.stylesheet,
    required this.pageList,
    required this.imgFiles,
  });

  final String bookIdentifier;
  final String pageIdentifier;
  final Document domTree;
  final String textContent;
  final String stylesheet;
  final List<BookPage> pageList;
  final Map<String, Uint8List> imgFiles;

  @override
  List<Object?> get props => <Object>[
        bookIdentifier,
        pageIdentifier,
        domTree,
        textContent,
        stylesheet,
        pageList,
        imgFiles,
      ];
}
