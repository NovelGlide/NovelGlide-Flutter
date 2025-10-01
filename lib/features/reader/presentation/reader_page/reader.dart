import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../main.dart';
import '../../../books/domain/entities/book.dart';
import '../search_page/cubit/reader_search_cubit.dart';
import 'cubit/reader_cubit.dart';
import 'cubit/reader_tts_cubit.dart';
import 'widgets/reader_scaffold.dart';

class ReaderWidget extends StatelessWidget {
  const ReaderWidget({
    super.key,
    required this.bookIdentifier,
    this.bookData,
    this.chapterIdentifier,
    this.cfi,
  });

  final String bookIdentifier;
  final Book? bookData;
  final String? chapterIdentifier;
  final String? cfi;

  @override
  Widget build(BuildContext context) {
    final ReaderCubit cubit = sl<ReaderCubit>();
    return MultiBlocProvider(
      providers: <BlocProvider<dynamic>>[
        BlocProvider<ReaderCubit>(
          create: (_) => cubit
            ..init(
              bookData: bookData,
              bookIdentifier: bookIdentifier,
              chapterIdentifier: chapterIdentifier,
              currentTheme: Theme.of(context),
              cfi: cfi,
            ),
        ),
        BlocProvider<ReaderTtsCubit>(
          create: (_) => cubit.ttsCubit,
        ),
        BlocProvider<ReaderSearchCubit>(
          create: (_) => cubit.searchCubit,
        ),
      ],
      child: const ReaderScaffold(),
    );
  }
}
