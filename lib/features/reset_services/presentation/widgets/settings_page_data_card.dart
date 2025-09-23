import 'package:flutter/material.dart';

import '../../../../generated/i18n/app_localizations.dart';
import '../../../../main.dart';
import '../../../bookmark/domain/use_cases/bookmark_reset_use_case.dart';
import '../../../books/domain/use_cases/book_reset_use_case.dart';
import '../../../collection/domain/use_cases/collection_reset_use_case.dart';
import '../../../settings_page/presentation/widgets/settings_card.dart';
import 'settings_page_list_tile.dart';

class SettingsPageDataCard extends StatelessWidget {
  const SettingsPageDataCard({super.key});

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
              appLocalizations.resetPageDataTitle,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
            ),
          ),

          // Delete all books
          SettingsPageListTile(
            onAccept: sl<BookResetUseCase>(),
            iconData: Icons.delete_forever_rounded,
            title: appLocalizations.resetPageDeleteAllBooks,
          ),

          // Delete all collections
          SettingsPageListTile(
            onAccept: sl<CollectionResetUseCase>(),
            iconData: Icons.delete_forever_rounded,
            title: appLocalizations.resetPageDeleteAllCollections,
          ),

          // Delete all bookmarks
          SettingsPageListTile(
            onAccept: sl<BookmarkResetUseCase>(),
            iconData: Icons.delete_forever_rounded,
            title: appLocalizations.resetPageDeleteAllBookmarks,
          ),
        ],
      ),
    );
  }
}
