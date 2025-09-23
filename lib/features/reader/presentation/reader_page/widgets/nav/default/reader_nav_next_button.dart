import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../../../generated/i18n/app_localizations.dart';
import '../../../cubit/reader_cubit.dart';
import '../../../cubit/reader_tts_cubit.dart';
import '../../../cubit/reader_tts_state.dart';

class ReaderNavNextButton extends StatelessWidget {
  const ReaderNavNextButton({
    super.key = const ValueKey<String>('reader_next_button'),
  });

  @override
  Widget build(BuildContext context) {
    final AppLocalizations appLocalizations = AppLocalizations.of(context)!;
    final ReaderCubit cubit = BlocProvider.of<ReaderCubit>(context);
    return BlocBuilder<ReaderCubit, ReaderState>(
      buildWhen: (ReaderState previous, ReaderState current) =>
          previous.code != current.code,
      builder: (BuildContext context, ReaderState state) {
        return BlocBuilder<ReaderTtsCubit, ReaderTtsState>(
          buildWhen: (ReaderTtsState previous, ReaderTtsState current) =>
              previous.ttsState != current.ttsState,
          builder: (BuildContext context, ReaderTtsState ttsState) {
            final bool isEnabled = state.code.isLoaded &&
                (ttsState.ttsState.isIdle || ttsState.ttsState.isInitial);
            return IconButton(
              icon: const Icon(Icons.arrow_forward_ios_rounded),
              tooltip: appLocalizations.generalNextPage,
              onPressed: isEnabled ? cubit.nextPage : null,
            );
          },
        );
      },
    );
  }
}
