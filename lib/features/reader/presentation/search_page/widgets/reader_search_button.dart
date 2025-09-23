import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../generated/i18n/app_localizations.dart';
import '../../reader_page/cubit/reader_cubit.dart';
import '../../reader_page/cubit/reader_tts_cubit.dart';
import '../../reader_page/cubit/reader_tts_state.dart';
import '../cubit/reader_search_cubit.dart';
import '../search_scaffold.dart';

class ReaderSearchButton extends StatelessWidget {
  const ReaderSearchButton({super.key});

  @override
  Widget build(BuildContext context) {
    final AppLocalizations appLocalizations = AppLocalizations.of(context)!;
    return BlocBuilder<ReaderCubit, ReaderState>(
      buildWhen: (ReaderState previous, ReaderState current) =>
          previous.code != current.code,
      builder: (BuildContext context, ReaderState state) {
        return BlocBuilder<ReaderTtsCubit, ReaderTtsState>(
          buildWhen: (ReaderTtsState previous, ReaderTtsState current) =>
              previous.ttsState != current.ttsState,
          builder: (BuildContext context, ReaderTtsState ttsState) {
            final bool isEnabled =
                state.code.isLoaded && ttsState.ttsState.isIdle;
            return IconButton(
              icon: const Icon(Icons.search),
              tooltip: appLocalizations.readerSearch,
              onPressed: isEnabled ? () => _onPressed(context) : null,
            );
          },
        );
      },
    );
  }

  void _onPressed(BuildContext context) {
    final ReaderCubit cubit = BlocProvider.of<ReaderCubit>(context);
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => BlocProvider<ReaderSearchCubit>(
          create: (_) => cubit.searchCubit,
          child: const SearchScaffold(),
        ),
      ),
    );
  }
}
