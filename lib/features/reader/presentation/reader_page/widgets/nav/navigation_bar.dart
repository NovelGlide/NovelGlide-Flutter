import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../domain/entities/reader_navigation_state_code.dart';
import '../../cubit/reader_cubit.dart';
import 'default/reader_nav_bookmark_button.dart';
import 'default/reader_nav_next_button.dart';
import 'default/reader_nav_previous_button.dart';
import 'default/reader_nav_settings_button.dart';
import 'default/reader_nav_tts_button.dart';
import 'tts/reader_tts_close_button.dart';
import 'tts/reader_tts_play_pause_button.dart';
import 'tts/reader_tts_settings_button.dart';
import 'tts/reader_tts_stop_button.dart';

class ReaderNavigationBar extends StatelessWidget {
  const ReaderNavigationBar({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 64.0,
      child: BlocBuilder<ReaderCubit, ReaderState>(
        builder: (BuildContext context, ReaderState state) {
          switch (state.navigationStateCode) {
            case ReaderNavigationStateCode.ttsState:
              return const Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  ReaderTtsPlayPauseButton(),
                  ReaderTtsStopButton(),
                  ReaderTtsCloseButton(),
                  ReaderTtsSettingsButton(),
                ],
              );

            default:
              return const Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  ReaderNavPreviousButton(),
                  ReaderNavNextButton(),
                  ReaderNavBookmarkButton(),
                  ReaderNavTtsButton(),
                  ReaderNavSettingsButton(),
                ],
              );
          }
        },
      ),
    );
  }
}
