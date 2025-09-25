import 'package:flutter/material.dart';

import '../../../../bookmark/domain/entities/bookmark_data.dart';
import '../../../../reader/presentation/reader_page/reader.dart';
import '../../../domain/entities/book.dart';
import '../../../domain/entities/book_chapter.dart';

class TocListItem extends StatelessWidget {
  const TocListItem({
    super.key,
    required this.bookData,
    required this.bookChapter,
    required this.chapterNestedLevel,
    this.bookmark,
  });

  final Book bookData;
  final BookChapter bookChapter;
  final int chapterNestedLevel;
  final BookmarkData? bookmark;

  @override
  Widget build(BuildContext context) {
    final bool isBookmarked =
        bookmark?.chapterIdentifier == bookChapter.identifier;
    final ThemeData themeData = Theme.of(context);

    return ListTile(
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => ReaderWidget(
              bookData: bookData,
              bookIdentifier: bookData.identifier,
              chapterIdentifier: bookChapter.identifier,
            ),
          ),
        );
      },
      dense: true,
      contentPadding: EdgeInsets.only(
        left: 12.0 + 16 * chapterNestedLevel,
        right: 12.0,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
      ),
      leading: Icon(
        isBookmarked ? Icons.bookmark_rounded : Icons.numbers_rounded,
        color: isBookmarked ? themeData.colorScheme.secondary : null,
        size: 20.0,
      ),
      title: Text(
        bookChapter.title,
        style: themeData.textTheme.bodyLarge,
      ),
    );
  }
}
