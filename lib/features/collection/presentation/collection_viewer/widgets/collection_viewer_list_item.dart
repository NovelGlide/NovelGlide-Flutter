part of '../collection_viewer.dart';

class CollectionViewerListItem extends StatelessWidget {
  const CollectionViewerListItem({
    super.key,
    required this.bookData,
    required this.index,
  });

  final Book bookData;
  final int index;

  @override
  Widget build(BuildContext context) {
    final CollectionViewerCubit cubit =
        BlocProvider.of<CollectionViewerCubit>(context);
    return BlocBuilder<CollectionViewerCubit, CollectionViewerState>(
      buildWhen:
          (CollectionViewerState previous, CollectionViewerState current) =>
              previous.code != current.code ||
              previous.selectedSet.contains(bookData) !=
                  current.selectedSet.contains(bookData) ||
              previous.dataList != current.dataList ||
              previous.isSelecting != current.isSelecting,
      builder: (BuildContext context, CollectionViewerState state) {
        return BookCoverBuilder(
          bookData: bookData,
          builder: (_, BookCover coverData) {
            return _buildGestureListener(context, state, coverData);
          },
          placeholder: SharedListItemPlaceholder(
            listType: cubit.state.listType,
          ),
        );
      },
    );
  }

  Widget _buildGestureListener(
    BuildContext context,
    CollectionViewerState state,
    BookCover coverData,
  ) {
    final bool isDraggable =
        state.code.isLoaded && !state.isSelecting && state.dataList.length > 1;

    return ReorderableDragStartListener(
      index: index,
      enabled: isDraggable,
      child: _buildBookWidget(context, state, coverData, isDraggable),
    );
  }

  Widget _buildBookWidget(
    BuildContext context,
    CollectionViewerState state,
    BookCover coverData,
    bool isDraggable,
  ) {
    return InkWell(
      onTap: state.isSelecting ? null : () => _onTap(context, coverData),
      child: BookWidget(
        bookData: bookData,
        coverData: coverData,
        listType: SharedListType.list,
        isSelecting: state.isSelecting,
        isSelected: state.selectedSet.contains(bookData),
        onChanged: (_) => _onChanged(context),
        trailing: isDraggable ? const Icon(Icons.drag_handle_rounded) : null,
      ),
    );
  }

  void _onTap(BuildContext context, BookCover coverData) {
    Navigator.of(context).push(MaterialPageRoute<void>(
        builder: (_) => TableOfContents(
              bookData,
              coverData,
            )));
  }

  void _onChanged(BuildContext context) {
    final CollectionViewerCubit cubit =
        BlocProvider.of<CollectionViewerCubit>(context);
    if (cubit.state.selectedSet.contains(bookData)) {
      cubit.deselectSingle(bookData);
    } else {
      cubit.selectSingle(bookData);
    }
  }
}
