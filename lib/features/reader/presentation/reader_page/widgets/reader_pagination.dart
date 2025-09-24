import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../domain/entities/reader_page_num_type.dart';
import '../cubit/reader_cubit.dart';

class ReaderPagination extends StatelessWidget {
  const ReaderPagination({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ReaderCubit, ReaderState>(
      buildWhen: (ReaderState prev, ReaderState curr) =>
          prev.readerPreference.pageNumType !=
              curr.readerPreference.pageNumType ||
          curr.readerPreference.pageNumType != ReaderPageNumType.hidden &&
              prev.chapterCurrentPage != curr.chapterCurrentPage ||
          prev.chapterTotalPage != curr.chapterTotalPage,
      builder: (BuildContext context, ReaderState state) {
        switch (state.readerPreference.pageNumType) {
          case ReaderPageNumType.hidden:
            return const SizedBox();

          case ReaderPageNumType.number:
            return Text(
                '${state.chapterCurrentPage} / ${state.chapterTotalPage}');

          case ReaderPageNumType.percentage:
            final num percentage =
                (state.chapterCurrentPage / state.chapterTotalPage * 100)
                    .clamp(0, 100);
            return Text('${percentage.toStringAsFixed(1)}%');

          case ReaderPageNumType.progressBar:
            final double percentage =
                state.chapterCurrentPage / state.chapterTotalPage;
            return LinearProgressIndicator(value: percentage);
        }
      },
    );
  }
}
