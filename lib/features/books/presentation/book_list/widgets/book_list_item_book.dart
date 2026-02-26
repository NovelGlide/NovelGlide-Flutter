import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../generated/i18n/app_localizations.dart';
import '../../../../shared_components/common_error_widgets/common_error_dialog.dart';
import '../../../domain/entities/book.dart';
import '../../../domain/entities/book_cover.dart';
import '../../table_of_contents_page/table_of_contents.dart';
import '../cubit/book_list_cubit.dart';
import 'book_list_draggable_book.dart';

class BookListItemBook extends StatelessWidget {
  const BookListItemBook({
    super.key,
    required this.bookData,
    required this.coverData,
  });

  final Book bookData;
  final BookCover coverData;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations appLocalizations = AppLocalizations.of(context)!;
    final BookListCubit cubit = BlocProvider.of<BookListCubit>(context);
    return InkWell(
      onTap: () => _onTap(context, coverData),
      borderRadius: BorderRadius.circular(24.0),
      splashFactory: InkRipple.splashFactory,
      child: Semantics(
        label: appLocalizations.generalBook,
        onTapHint: appLocalizations.tapToOpenBook,
        onLongPressHint: appLocalizations.dragToDeleteBook,
        child: BlocBuilder<BookListCubit, BookListState>(
          buildWhen: (BookListState previous, BookListState current) =>
              previous.code != current.code ||
              previous.isSelecting != current.isSelecting ||
              previous.isDragging != current.isDragging ||
              previous.selectedSet.contains(bookData) !=
                  current.selectedSet.contains(bookData) ||
              previous.listType != current.listType,
          builder: (BuildContext context, BookListState state) {
            return BookListDraggableBook(
              bookData: bookData,
              coverData: coverData,
              listType: state.listType,
              isDraggable: state.code.isLoaded &&
                  !state.isDragging &&
                  !state.isSelecting,
              isSelecting: state.isSelecting,
              isSelected: state.selectedSet.contains(bookData),
              onChanged: (_) => cubit.toggleSelectSingle(bookData),
            );
          },
        ),
      ),
    );
  }

  Future<void> _onTap(BuildContext context, BookCover coverData) async {
    final AppLocalizations appLocalizations = AppLocalizations.of(context)!;
    final BookListCubit cubit = BlocProvider.of<BookListCubit>(context);

    final bool isExists = await cubit.bookExists(bookData);

    if (cubit.state.isSelecting) {
      cubit.toggleSelectSingle(bookData);
    } else if (context.mounted) {
      if (isExists) {
        // Navigate to the table of contents page.
        Navigator.of(context).push(MaterialPageRoute<void>(
            builder: (_) => TableOfContents(
                  bookData,
                  coverData,
                )));
      } else {
        // Show the book is not exist dialog.
        showDialog(
          context: context,
          builder: (BuildContext context) => CommonErrorDialog(
            content: appLocalizations.bookNotExists,
          ),
        ).then((_) => cubit.refresh());
      }
    }
  }
}
