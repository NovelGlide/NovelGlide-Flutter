import 'package:flutter/material.dart';

import '../../../../generated/i18n/app_localizations.dart';
import '../../../../main.dart';
import '../../../reader/domain/use_cases/location_cache_use_cases/reader_clear_location_cache_use_case.dart';
import '../../../settings_page/presentation/widgets/settings_card.dart';
import 'settings_page_list_tile.dart';

class SettingsPageCacheCard extends StatelessWidget {
  const SettingsPageCacheCard({super.key});

  @override
  Widget build(BuildContext context) {
    final AppLocalizations appLocalizations = AppLocalizations.of(context)!;
    return SettingsCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(bottom: 12.0),
            child: Text(
              appLocalizations.resetPageCacheTitle,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
          ),

          // Clear cache (Currently only for Reader)
          SettingsPageListTile(
            onAccept: sl<ReaderClearLocationCacheUseCase>(),
            iconData: Icons.delete_forever_rounded,
            title: appLocalizations.resetPageCacheClear,
            isDangerous: false,
          ),
        ],
      ),
    );
  }
}
