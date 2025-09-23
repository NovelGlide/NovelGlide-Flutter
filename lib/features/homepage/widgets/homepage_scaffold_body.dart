import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../bookmark/presentation/bookmark_list/bookmark_list_scaffold_body.dart';
import '../../books/presentation/bookshelf/bookshelf.dart';
import '../../explore/presentation/browser/explore_browser.dart';
import '../../settings_page/presentation/settings_page.dart';
import '../cubit/homepage_cubit.dart';

class HomepageScaffoldBody extends StatelessWidget {
  const HomepageScaffoldBody({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomepageCubit, HomepageState>(
      buildWhen: (HomepageState previous, HomepageState current) =>
          previous.navItem != current.navItem,
      builder: (BuildContext context, HomepageState state) {
        switch (state.navItem) {
          case HomepageNavigationItem.bookshelf:
            return const Bookshelf();

          case HomepageNavigationItem.explore:
            return const ExploreBrowser();

          case HomepageNavigationItem.bookmark:
            return const BookmarkListScaffoldBody();

          case HomepageNavigationItem.settings:
            return const SettingsPage();
        }
      },
    );
  }
}
