import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../app/widgets/app_version_widget.dart';
import '../../../enum/window_size.dart';
import '../../../generated/i18n/app_localizations.dart';
import '../../appearance/presentation/appearance_settings_page/appearance_settings_page.dart';
import '../../backup/presentation/backup_service_page.dart';
import '../../developer_page/developer_page.dart';
import '../../locale_system/domain/entities/app_locale.dart';
import '../../locale_system/locale_utils.dart';
import '../../locale_system/presentation/locale_settings_page/locale_settings_page.dart';
import '../../manual/domain/entities/shared_manual_path_enum.dart';
import '../../manual/presentation/shared_manual.dart';
import '../../reset_services/presentation/reset_service_settings_list_tile.dart';
import '../../tts_service/presentation/tts_settings_page/tts_settings_page.dart';
import 'widgets/settings_list_tile.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final AppLocalizations appLocalizations = AppLocalizations.of(context)!;
    final double windowWidth = MediaQuery.sizeOf(context).width;
    final WindowSize windowClass = WindowSize.fromWidth(windowWidth);

    return Scrollbar(
      child: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.only(
            top: windowClass == WindowSize.compact ? 0.0 : 16.0,
            bottom: MediaQuery.paddingOf(context).bottom,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget?>[
              // Appearance settings
              SettingsListTile(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                      builder: (_) => const AppearanceSettingsPage()),
                ),
                iconData: Icons.format_paint_outlined,
                title: appLocalizations.appearance,
              ),

              // Backup settings
              SettingsListTile(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                      builder: (_) => const BackupServicePage()),
                ),
                iconData: Icons.cloud_outlined,
                title: appLocalizations.generalBackup,
              ),

              // TTS settings
              SettingsListTile(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                      builder: (_) => const TtsSettingsPage()),
                ),
                iconData: Icons.volume_up_outlined,
                title: appLocalizations.ttsSettingsTitle,
              ),

              // Locale settings
              SettingsListTile(
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute<void>(
                      builder: (_) => const LocaleSettingsPage()),
                ),
                iconData: Icons.language_rounded,
                title: appLocalizations.generalLanguages,
              ),

              // Reset settings
              const ResetServiceSettingsListTile(),

              // Feedback
              SettingsListTile(
                onTap: () {
                  final AppLocale currentLocale =
                      LocaleUtils.convertLocaleToAppLocale(
                          Localizations.localeOf(context));
                  final String id = switch (currentLocale) {
                    const AppLocale('en') =>
                      '1FAIpQLScMbqxt1GTgz3-VyGpSk8avoPgWxvB9crIFvgdYrGZYbtE2zg',
                    const AppLocale('zh') =>
                      '1FAIpQLSdo77Am6qvaoIz9K9FWmySt21p9VnLiikUv0KfxWKV1jf01jQ',
                    const AppLocale('zh', 'Hant', 'TW') =>
                      '1FAIpQLSdo77Am6qvaoIz9K9FWmySt21p9VnLiikUv0KfxWKV1jf01jQ',
                    const AppLocale('zh', 'Hans', 'CN') =>
                      '1FAIpQLSdlDoVsZdyt9GBEivAUxNcv7ohDOKaEv5OornD-DMTxiQWm7g',
                    const AppLocale('ja') =>
                      '1FAIpQLSeibENYH3G57PWw28pawmnJF_rMtzrr-3QbQpiuhF6W6HfLnw',
                    _ => '',
                  };

                  if (id.isNotEmpty) {
                    launchUrl(Uri.parse(
                        'https://docs.google.com/forms/d/e/$id/viewform'));
                  }
                },
                iconData: Icons.feedback_outlined,
                title: appLocalizations.generalFeedback,
                trailing: const Icon(Icons.north_east_rounded),
              ),

              // Privacy policy
              SettingsListTile(
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => SharedManual(
                        title: appLocalizations.privacyPolicy,
                        filePath: SharedManualPathEnum.privacyPolicy,
                      ),
                    ),
                  );
                },
                iconData: Icons.shield_outlined,
                title: appLocalizations.privacyPolicy,
              ),

              /// ========== Development Sections Start!!! ==========

              // Developer Page
              kDebugMode
                  ? SettingsListTile(
                      onTap: () => Navigator.of(context).push(
                        MaterialPageRoute<void>(
                            builder: (_) => const DeveloperPage()),
                      ),
                      iconData: Icons.code_rounded,
                      title: 'Developer Page',
                    )
                  : null,

              /// ========== End of Development Sections!!! ==========

              // About
              const AppVersionWidget(),
            ].whereType<Widget>().toList(),
          ),
        ),
      ),
    );
  }
}
