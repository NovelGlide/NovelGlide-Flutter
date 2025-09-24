import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../main.dart';
import '../../../books/domain/entities/book.dart';
import '../../domain/entities/reader_destination_type.dart';
import 'cubit/reader_cubit.dart';
import 'cubit/reader_tts_cubit.dart';
import 'widgets/reader_scaffold.dart';

class ReaderWidget extends StatelessWidget {
  const ReaderWidget({
    super.key,
    required this.bookIdentifier,
    this.bookData,
    this.destinationType = ReaderDestinationType.none,
    this.destination,
  });

  final String bookIdentifier;
  final Book? bookData;
  final ReaderDestinationType destinationType;
  final String? destination;

  @override
  Widget build(BuildContext context) {
    final ReaderCubit cubit = sl<ReaderCubit>();
    return MultiBlocProvider(
      providers: <BlocProvider<dynamic>>[
        BlocProvider<ReaderCubit>(
          create: (_) => cubit
            ..initAsync(
              bookData: bookData,
              bookIdentifier: bookIdentifier,
              currentTheme: Theme.of(context),
              destinationType: destinationType,
              destination: destination,
            ),
        ),
        BlocProvider<ReaderTtsCubit>(
          create: (_) => cubit.ttsCubit..startLoading(),
        )
      ],
      child: const ReaderScaffold(),
    );
  }
}
