import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:novel_glide/generated/i18n/app_localizations.dart';

import '../../collection/presentation/collection_list/cubit/collection_list_cubit.dart';
import '../../settings_page/presentation/widgets/settings_list_tile.dart';
import 'reset_page.dart';

class ResetServiceSettingsListTile extends StatelessWidget {
  const ResetServiceSettingsListTile({super.key});

  @override
  Widget build(BuildContext context) {
    final AppLocalizations appLocalizations = AppLocalizations.of(context)!;

    return SettingsListTile(
      onTap: () => Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => MultiBlocProvider(
            providers: <BlocProvider<dynamic>>[
              BlocProvider<CollectionListCubit>.value(
                value: BlocProvider.of<CollectionListCubit>(context),
              ),
            ],
            child: const ResetPage(),
          ),
        ),
      ),
      iconData: Icons.refresh_rounded,
      title: appLocalizations.resetPageTitle,
    );
  }
}
