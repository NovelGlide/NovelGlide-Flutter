import 'package:equatable/equatable.dart';
import 'package:html/dom.dart';

import '../../../../core/css_parser/domain/entities/css_font_file.dart';
import '../../../../core/domain/entities/image_file.dart';
import 'book_page.dart';

class BookHtmlContent extends Equatable {
  const BookHtmlContent({
    required this.bookIdentifier,
    required this.pageIdentifier,
    required this.domTree,
    required this.stylesheet,
    required this.fonts,
    required this.pageList,
    required this.imgFiles,
  });

  final String bookIdentifier;
  final String pageIdentifier;
  final Document domTree;
  final String stylesheet;
  final Set<CssFontFile> fonts;
  final List<BookPage> pageList;
  final Map<String, ImageFile> imgFiles;

  String get textContent => domTree.body?.text ?? '';

  @override
  List<Object?> get props => <Object>[
        bookIdentifier,
        pageIdentifier,
        domTree,
        stylesheet,
        fonts,
        pageList,
        imgFiles,
      ];

  BookHtmlContent copyWith({
    String? bookIdentifier,
    String? pageIdentifier,
    Document? domTree,
    String? stylesheet,
    Set<CssFontFile>? fonts,
    List<BookPage>? pageList,
    Map<String, ImageFile>? imgFiles,
  }) {
    return BookHtmlContent(
      bookIdentifier: bookIdentifier ?? this.bookIdentifier,
      pageIdentifier: pageIdentifier ?? this.pageIdentifier,
      domTree: domTree ?? this.domTree,
      stylesheet: stylesheet ?? this.stylesheet,
      fonts: fonts ?? this.fonts,
      pageList: pageList ?? this.pageList,
      imgFiles: imgFiles ?? this.imgFiles,
    );
  }
}
