import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../enum/window_size.dart';
import '../../../../generated/i18n/app_localizations.dart';
import '../../../../main.dart';
import 'cubit/tts_settings_cubit.dart';
import 'cubit/tts_settings_state.dart';
import 'widgets/tts_demo_section.dart';
import 'widgets/tts_settings_slider.dart';
import 'widgets/tts_voice_select_tile.dart';

class TtsSettingsPage extends StatelessWidget {
  const TtsSettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<TtsSettingsCubit>(
      create: (_) => sl<TtsSettingsCubit>()..startLoading(),
      child: const _PageScaffold(),
    );
  }
}

class _PageScaffold extends StatelessWidget {
  const _PageScaffold();

  @override
  Widget build(BuildContext context) {
    final AppLocalizations appLocalizations = AppLocalizations.of(context)!;
    final TtsSettingsCubit cubit = BlocProvider.of<TtsSettingsCubit>(context);
    return Scaffold(
      appBar: AppBar(
        title: Text(appLocalizations.ttsSettingsTitle),
      ),
      body: SafeArea(
        child: Scrollbar(
          child: SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: WindowSize.compact.maxWidth,
              ),
              child: Column(
                children: <Widget>[
                  const TtsDemoSection(),
                  const TtsVoiceSelectTile(),
                  TtsSettingSlider(
                    title: appLocalizations.ttsSettingsPitch,
                    onChanged: cubit.setPitch,
                    min: 0.5,
                    max: 2.0,
                    divisions: 15,
                    valueSelector: (TtsSettingsState state) => state.data.pitch,
                  ),
                  TtsSettingSlider(
                    title: appLocalizations.ttsSettingsVolume,
                    onChanged: cubit.setVolume,
                    min: 0.0,
                    max: 1.0,
                    divisions: 10,
                    valueSelector: (TtsSettingsState state) =>
                        state.data.volume,
                  ),
                  TtsSettingSlider(
                    title: appLocalizations.ttsSettingsSpeechRate,
                    onChanged: cubit.setSpeechRate,
                    min: 0.5,
                    max: 2.0,
                    divisions: 15,
                    valueSelector: (TtsSettingsState state) =>
                        state.data.speechRate,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
