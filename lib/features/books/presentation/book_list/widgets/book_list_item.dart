import 'package:flutter/material.dart';
import 'package:novel_glide/features/books/domain/entities/book_cover.dart';

import '../../../../shared_components/animated_placeholders/ease_flash_placeholder.dart';
import '../../../domain/entities/book.dart';
import '../../book_cover/book_cover_builder.dart';
import 'book_list_item_book.dart';

class BookListItem extends StatelessWidget {
  const BookListItem({super.key, required this.bookData});

  final Book bookData;

  @override
  Widget build(BuildContext context) {
    return BookCoverBuilder(
      bookData: bookData,
      builder: (_, BookCover coverData) => BookListItemBook(
        bookData: bookData,
        coverData: coverData,
      ),
      placeholder: Container(
        margin: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24.0),
        ),
        clipBehavior: Clip.hardEdge,
        child: const EaseFlashPlaceholder(),
      ),
    );
  }
}
