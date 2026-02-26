import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:novel_glide/features/books/domain/entities/book_cover.dart';

import '../../../../shared_components/shared_list/presentation/widgets/shared_list_item_placeholder.dart';
import '../../../domain/entities/book.dart';
import '../../book_cover/book_cover_builder.dart';
import '../cubit/book_list_cubit.dart';
import 'book_list_item_book.dart';

class BookListItem extends StatelessWidget {
  const BookListItem({super.key, required this.bookData});

  final Book bookData;

  @override
  Widget build(BuildContext context) {
    final BookListCubit cubit = BlocProvider.of<BookListCubit>(context);

    return BookCoverBuilder(
      bookData: bookData,
      builder: (_, BookCover coverData) => BookListItemBook(
        bookData: bookData,
        coverData: coverData,
      ),
      placeholder: SharedListItemPlaceholder(
        listType: cubit.state.listType,
      ),
    );
  }
}
