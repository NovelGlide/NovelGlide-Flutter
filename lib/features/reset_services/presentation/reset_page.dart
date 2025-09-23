import 'package:flutter/material.dart';

import '../../../enum/window_size.dart';
import '../../../generated/i18n/app_localizations.dart';
import 'widgets/settings_page_cache_card.dart';
import 'widgets/settings_page_data_card.dart';
import 'widgets/settings_page_preference_card.dart';

class ResetPage extends StatelessWidget {
  const ResetPage({super.key});

  @override
  Widget build(BuildContext context) {
    final AppLocalizations appLocalizations = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(appLocalizations.resetPageTitle),
      ),
      body: SafeArea(
        child: Scrollbar(
          child: CustomScrollView(
            slivers: <Widget>[
              SliverGrid.extent(
                maxCrossAxisExtent: WindowSize.compact.maxWidth,
                children: const <Widget>[
                  SettingsPagePreferenceCard(),
                  SettingsPageCacheCard(),
                  SettingsPageDataCard(),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
