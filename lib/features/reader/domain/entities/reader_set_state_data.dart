import 'package:equatable/equatable.dart';

import '../../../books/domain/entities/book_html_content.dart';

class ReaderSetStateData extends Equatable {
  const ReaderSetStateData({
    required this.breadcrumb,
    required this.chapterIdentifier,
    required this.startCfi,
    required this.chapterCurrentPage,
    required this.chapterTotalPage,
    required this.content,
    required this.atStart,
    required this.atEnd,
  });

  final String? breadcrumb;
  final String? chapterIdentifier;
  final String? startCfi;
  final int? chapterCurrentPage;
  final int? chapterTotalPage;
  final BookHtmlContent? content;
  final bool? atStart;
  final bool? atEnd;

  @override
  List<Object?> get props => <Object?>[
        breadcrumb,
        chapterIdentifier,
        startCfi,
        chapterCurrentPage,
        chapterTotalPage,
        content,
        atStart,
        atEnd,
      ];
}
