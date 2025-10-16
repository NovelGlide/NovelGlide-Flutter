import 'package:equatable/equatable.dart';
import 'package:html/dom.dart';

import '../../../../core/domain/entities/font_file.dart';
import '../../../../core/domain/entities/image_bytes_data.dart';
import 'book_page.dart';

class BookHtmlContent extends Equatable {
  const BookHtmlContent({
    required this.bookIdentifier,
    required this.pageIdentifier,
    required this.domTree,
    required this.textContent,
    required this.stylesheet,
    required this.fonts,
    required this.pageList,
    required this.imgFiles,
  });

  final String bookIdentifier;
  final String pageIdentifier;
  final Document domTree;
  final String textContent;
  final String stylesheet;
  final Set<FontFile> fonts;
  final List<BookPage> pageList;
  final Map<String, ImageBytesData> imgFiles;

  @override
  List<Object?> get props => <Object>[
        bookIdentifier,
        pageIdentifier,
        domTree,
        textContent,
        stylesheet,
        fonts,
        pageList,
        imgFiles,
      ];
}
