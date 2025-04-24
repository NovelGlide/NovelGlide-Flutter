import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../enum/reader_navigation_state_code.dart';
import '../cubit/reader_cubit.dart';
import '../tts/reader_tts_close_button.dart';
import '../tts/reader_tts_play_pause_button.dart';
import '../tts/reader_tts_settings_button.dart';
import '../tts/reader_tts_stop_button.dart';
import 'default/reader_default_navigation.dart';

class ReaderNavigationRail extends StatelessWidget {
  const ReaderNavigationRail({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 64.0,
      child: BlocBuilder<ReaderCubit, ReaderState>(
        builder: (BuildContext context, ReaderState state) {
          switch (state.navigationStateCode) {
            case ReaderNavigationStateCode.ttsState:
              return const Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  ReaderTtsSettingsButton(),
                  ReaderTtsCloseButton(),
                  ReaderTtsPlayPauseButton(),
                  ReaderTtsStopButton(),
                ],
              );

            default:
              return const Column(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  ReaderNavSettingsButton(),
                  ReaderNavTtsButton(),
                  ReaderNavBookmarkButton(),
                  ReaderNavPreviousButton(),
                  ReaderNavNextButton(),
                ],
              );
          }
        },
      ),
    );
  }
}
