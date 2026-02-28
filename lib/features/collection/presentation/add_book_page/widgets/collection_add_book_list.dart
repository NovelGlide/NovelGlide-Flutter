import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../enum/loading_state_code.dart';
import '../../../../shared_components/common_error_widgets/common_error_widget.dart';
import '../../../../shared_components/common_loading_widgets/common_loading_widget.dart';
import '../../../../shared_components/shared_list/shared_list.dart';
import '../../../domain/entities/collection_data.dart';
import '../cubit/collection_add_book_cubit.dart';
import '../cubit/collection_add_book_state.dart';
import 'collection_add_book_list_item.dart';

class CollectionAddBookList extends StatelessWidget {
  const CollectionAddBookList({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<CollectionAddBookCubit, CollectionAddBookState>(
      buildWhen:
          (CollectionAddBookState previous, CollectionAddBookState current) =>
              previous.code != current.code ||
              previous.collectionList != current.collectionList ||
              previous.selectedCollections != current.selectedCollections,
      builder: _buildList,
    );
  }

  Widget _buildList(BuildContext context, CollectionAddBookState state) {
    switch (state.code) {
      case LoadingStateCode.initial:
      case LoadingStateCode.loading:
      case LoadingStateCode.backgroundLoading:
        // Loading...
        return const CommonLoadingWidget();

      case LoadingStateCode.error:
        // Error
        return const CommonErrorWidget();

      case LoadingStateCode.loaded:
        if (state.collectionList.isEmpty) {
          // There is no collection.
          return const SharedListEmpty();
        } else {
          return ListView.builder(
            itemCount: state.collectionList.length,
            itemBuilder: (BuildContext context, int index) {
              final CollectionData data = state.collectionList[index];
              // Check if all selected books are in this collection using bookIds
              final bool? isSelected = state.selectedCollections.contains(data)
                  ? state.selectedCollections.every((CollectionData e) => e
                          .bookIds
                          .toSet()
                          .containsAll(state.bookRelativePathSet))
                      ? true
                      : null
                  : false;

              return CollectionAddBookListItem(
                data: data,
                isSelected: isSelected,
              );
            },
          );
        }
    }
  }
}
