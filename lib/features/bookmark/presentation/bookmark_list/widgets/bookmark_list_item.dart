import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../generated/i18n/app_localizations.dart';
import '../../../../reader/presentation/reader_page/reader.dart';
import '../../../domain/entities/bookmark_data.dart';
import '../cubit/bookmark_list_cubit.dart';
import 'bookmark_list_draggable_bookmark.dart';

class BookmarkListItem extends StatelessWidget {
  const BookmarkListItem({super.key, required this.bookmarkData});

  final BookmarkData bookmarkData;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations appLocalizations = AppLocalizations.of(context)!;
    final BookmarkListCubit cubit = BlocProvider.of<BookmarkListCubit>(context);
    return InkWell(
      onTap: () => _onTap(context),
      borderRadius: BorderRadius.circular(24.0),
      child: Semantics(
        label: appLocalizations.generalBookmark(1),
        onTapHint: appLocalizations.bookmarkListStartReading,
        onLongPressHint: appLocalizations.bookmarkListDragToDelete,
        child: BlocBuilder<BookmarkListCubit, BookmarkListState>(
          buildWhen: (BookmarkListState previous, BookmarkListState current) =>
              previous.code != current.code ||
              previous.isSelecting != current.isSelecting ||
              previous.isDragging != current.isDragging ||
              previous.selectedSet.contains(bookmarkData) !=
                  current.selectedSet.contains(bookmarkData) ||
              previous.listType != current.listType,
          builder: (BuildContext context, BookmarkListState state) {
            return BookmarkListDraggableBookmark(
              bookmarkData: bookmarkData,
              listType: state.listType,
              isDraggable: state.code.isLoaded &&
                  !state.isDragging &&
                  !state.isSelecting,
              isSelecting: state.isSelecting,
              isSelected: state.selectedSet.contains(bookmarkData),
              onChanged: (_) => cubit.toggleSelectSingle(bookmarkData),
            );
          },
        ),
      ),
    );
  }

  void _onTap(BuildContext context) {
    final BookmarkListCubit cubit = BlocProvider.of<BookmarkListCubit>(context);

    if (cubit.state.isSelecting) {
      cubit.toggleSelectSingle(bookmarkData);
    } else {
      Navigator.of(context)
          .push(
            MaterialPageRoute<void>(
              builder: (_) => ReaderWidget(
                bookIdentifier: bookmarkData.bookIdentifier,
                chapterIdentifier: bookmarkData.chapterIdentifier,
                cfi: bookmarkData.startCfi,
              ),
            ),
          )
          .then((_) => cubit.refresh());
    }
  }
}
