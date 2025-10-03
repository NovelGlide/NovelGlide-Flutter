import 'package:flutter/material.dart';

import '../../../../core/utils/datetime_extension.dart';
import '../../generated/i18n/app_localizations.dart';
import 'domain/entities/app_locale.dart';

class LocaleUtils {
  LocaleUtils._();

  static List<AppLocale> get supportedLocales =>
      AppLocalizations.supportedLocales
          .map((Locale locale) => convertLocaleToAppLocale(locale))
          .toList();

  static String languageNameOf(BuildContext context, AppLocale locale) {
    final AppLocalizations appLocalizations = AppLocalizations.of(context)!;
    return switch (locale) {
      const AppLocale('en') => appLocalizations.languageCodeEnUS,
      const AppLocale('zh') => appLocalizations.languageCodeZh,
      const AppLocale('zh', 'Hant', 'TW') => appLocalizations.languageCodeZhTW,
      const AppLocale('zh', 'Hans', 'CN') => appLocalizations.languageCodeZhCN,
      const AppLocale('ja') => appLocalizations.languageCodeJaJP,
      _ => locale.toString(),
    };
  }

  static String? dateTimeOf(BuildContext context, DateTime? dateTime) {
    return dateTime
        ?.format(AppLocalizations.of(context)!.generalDatetimeFormat);
  }

  static Locale convertAppLocaleToLocale(AppLocale appLocale) {
    return Locale.fromSubtags(
      languageCode: appLocale.languageCode,
      scriptCode: appLocale.scriptCode,
      countryCode: appLocale.countryCode,
    );
  }

  static AppLocale convertLocaleToAppLocale(Locale locale) {
    return AppLocale(
      locale.languageCode,
      locale.scriptCode,
      locale.countryCode,
    );
  }
}
