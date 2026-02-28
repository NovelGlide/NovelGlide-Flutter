import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../enum/loading_state_code.dart';
import '../../../../../generated/i18n/app_localizations.dart';
import '../../../../shared_components/common_error_widgets/common_error_sliver_widget.dart';
import '../../../../shared_components/common_loading_widgets/common_loading_sliver_widget.dart';
import '../../../../shared_components/shared_list/shared_list.dart';
import '../../../domain/entities/book.dart';
import '../cubit/toc_cubit.dart';
import '../cubit/toc_state.dart';
import 'toc_list_item.dart';

class TocSliverList extends StatelessWidget {
  const TocSliverList({super.key, required this.bookData});

  final Book bookData;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations appLocalizations = AppLocalizations.of(context)!;
    return BlocBuilder<TocCubit, TocState>(
      buildWhen: (TocState previous, TocState current) =>
          previous.code != current.code ||
          previous.chapterList != current.chapterList ||
          previous.currentPositionCfi != current.currentPositionCfi,
      builder: (BuildContext context, TocState state) {
        switch (state.code) {
          case LoadingStateCode.initial:
          case LoadingStateCode.loading:
          case LoadingStateCode.backgroundLoading:
            return const CommonLoadingSliverWidget();

          case LoadingStateCode.error:
            // Error
            return const CommonErrorSliverWidget();

          case LoadingStateCode.loaded:
            if (state.chapterList.isEmpty) {
              return SharedListSliverEmpty(
                title: appLocalizations.tocNoChapter,
              );
            } else {
              return _buildList(context, state);
            }
        }
      },
    );
  }

  Widget _buildList(BuildContext context, TocState state) {
    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (BuildContext context, int index) {
          return TocListItem(
            key: ValueKey<String>('tocList_$index'),
            bookData: bookData,
            bookChapter: state.chapterList[index].chapterData,
            chapterNestedLevel: state.chapterList[index].nestedLevel,
            currentPositionCfi: state.currentPositionCfi,
          );
        },
        childCount: state.chapterList.length,
      ),
    );
  }
}
