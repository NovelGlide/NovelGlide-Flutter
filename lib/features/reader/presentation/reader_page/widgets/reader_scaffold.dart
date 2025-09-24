import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../enum/window_size.dart';
import '../cubit/reader_cubit.dart';
import '../views/reader_compact_view.dart';
import '../views/reader_medium_view.dart';

class ReaderScaffold extends StatelessWidget {
  const ReaderScaffold({super.key});

  @override
  Widget build(BuildContext context) {
    final double windowWidth = MediaQuery.sizeOf(context).width;
    final WindowSize windowClass = WindowSize.fromWidth(windowWidth);
    final ReaderCubit cubit = BlocProvider.of<ReaderCubit>(context);

    cubit.sendThemeData(Theme.of(context));

    return switch (windowClass) {
      WindowSize.compact => const ReaderCompactView(),
      _ => const ReaderMediumView(),
    };
  }
}
