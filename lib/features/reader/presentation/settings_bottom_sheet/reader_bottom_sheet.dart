import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../enum/common_button_state_code.dart';
import '../../../../generated/i18n/app_localizations.dart';
import '../../../preference/domain/entities/reader_preference_data.dart';
import '../../../settings_page/presentation/widgets/settings_card.dart';
import '../../domain/entities/reader_core_type.dart';
import '../../domain/entities/reader_page_num_type.dart';
import '../reader_page/cubit/reader_cubit.dart';

part 'settings_reset_button.dart';
part 'widgets/auto_save_switch.dart';
part 'widgets/engine_selector.dart';
part 'widgets/font_size_slider.dart';
part 'widgets/line_height_slider.dart';
part 'widgets/page_num_selector.dart';
part 'widgets/settings_slider.dart';
part 'widgets/smooth_scroll_switch.dart';

class ReaderBottomSheet extends StatelessWidget {
  const ReaderBottomSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final ReaderCubit cubit = BlocProvider.of<ReaderCubit>(context);
    final ReaderCoreType? coreType = cubit.state.coreType;

    return DraggableScrollableSheet(
      initialChildSize: 0.5,
      minChildSize: 0.25,
      maxChildSize: 0.8,
      expand: false,
      snap: true,
      snapSizes: const <double>[0.25, 0.5, 0.8],
      builder: (BuildContext context, ScrollController scrollController) {
        return SingleChildScrollView(
          controller: scrollController,
          child: Column(
            children: <Widget>[
              const SettingsCard(
                margin: EdgeInsets.fromLTRB(24.0, 0.0, 24.0, 24.0),
                child: Column(
                  children: <Widget>[
                    _FontSizeSlider(),
                    _LineHeightSlider(),
                  ],
                ),
              ),
              SettingsCard(
                margin: const EdgeInsets.fromLTRB(24.0, 0.0, 24.0, 24.0),
                child: Column(
                  children: <Widget?>[
                    const _AutoSaveSwitch(),

                    // Show the smooth scroll switcher only in WebView mode.
                    switch (coreType) {
                      ReaderCoreType.webView => const _SmoothScrollSwitch(),
                      _ => null,
                    },
                  ].whereType<Widget>().toList(),
                ),
              ),
              const SettingsCard(
                margin: EdgeInsets.fromLTRB(24.0, 0.0, 24.0, 24.0),
                child: Column(
                  children: <Widget>[
                    _PageNumSelector(),
                  ],
                ),
              ),
              const SettingsCard(
                margin: EdgeInsets.fromLTRB(24.0, 0.0, 24.0, 24.0),
                child: Column(
                  children: <Widget>[
                    _EngineSelector(),
                  ],
                ),
              ),
              const SettingsCard(
                margin: EdgeInsets.fromLTRB(24.0, 0.0, 24.0, 24.0),
                child: Column(
                  children: <Widget>[
                    Align(
                      alignment: Alignment.centerRight,
                      child: _SettingsResetButton(),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
