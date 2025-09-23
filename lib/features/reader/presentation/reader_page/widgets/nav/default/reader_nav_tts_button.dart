part of '../../../reader.dart';

class ReaderNavTtsButton extends StatelessWidget {
  const ReaderNavTtsButton({super.key});

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
            final bool isEnabled =
                state.code.isLoaded && ttsState.ttsState.isIdle;
            return IconButton(
              icon: const Icon(Icons.record_voice_over_rounded),
              tooltip: appLocalizations.readerTtsButton,
              onPressed: isEnabled
                  ? () => cubit.setNavState(ReaderNavigationStateCode.ttsState)
                  : null,
            );
          },
        );
      },
    );
  }
}
