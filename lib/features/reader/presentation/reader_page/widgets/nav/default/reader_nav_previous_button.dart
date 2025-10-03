import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../../../generated/i18n/app_localizations.dart';
import '../../../cubit/reader_cubit.dart';
import '../../../cubit/reader_tts_cubit.dart';
import '../../../cubit/reader_tts_state.dart';

class ReaderNavPreviousButton extends StatelessWidget {
  const ReaderNavPreviousButton({super.key});

  @override
  Widget build(BuildContext context) {
    final AppLocalizations appLocalizations = AppLocalizations.of(context)!;
    final ReaderCubit cubit = BlocProvider.of<ReaderCubit>(context);
    return BlocBuilder<ReaderCubit, ReaderState>(
      buildWhen: (ReaderState previous, ReaderState current) =>
          previous.code != current.code || previous.atStart != current.atStart,
      builder: (BuildContext context, ReaderState state) {
        return BlocBuilder<ReaderTtsCubit, ReaderTtsState>(
          buildWhen: (ReaderTtsState previous, ReaderTtsState current) =>
              previous.ttsState != current.ttsState,
          builder: (BuildContext context, ReaderTtsState ttsState) {
            final bool isEnabled = state.code.isLoaded &&
                !state.atStart &&
                (ttsState.ttsState.isIdle || ttsState.ttsState.isInitial);
            return IconButton(
              icon: const Icon(Icons.arrow_back_ios_rounded),
              tooltip: appLocalizations.generalPreviousPage,
              onPressed: isEnabled ? cubit.previousPage : null,
            );
          },
        );
      },
    );
  }
}
