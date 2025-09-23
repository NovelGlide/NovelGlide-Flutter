import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../generated/i18n/app_localizations.dart';
import '../../bookmark/presentation/bookmark_list/cubit/bookmark_list_cubit.dart';
import '../../books/presentation/book_list/cubit/book_list_cubit.dart';
import '../../collection/presentation/collection_list/cubit/collection_list_cubit.dart';
import '../../explore/presentation/browser/explore_browser_icon.dart';
import '../cubit/homepage_cubit.dart';

class HomepageNavigationRail extends StatelessWidget {
  const HomepageNavigationRail({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: BlocBuilder<HomepageCubit, HomepageState>(
                buildWhen: (HomepageState previous, HomepageState current) =>
                    previous.navItem != current.navItem ||
                    previous.isEnabled != current.isEnabled,
                builder: _railBuilder,
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _railBuilder(BuildContext context, HomepageState state) {
    final AppLocalizations appLocalizations = AppLocalizations.of(context)!;
    final HomepageCubit cubit = BlocProvider.of<HomepageCubit>(context);
    final BookListCubit bookshelfCubit =
        BlocProvider.of<BookListCubit>(context);
    final BookmarkListCubit bookmarkListCubit =
        BlocProvider.of<BookmarkListCubit>(context);
    final CollectionListCubit collectionListCubit =
        BlocProvider.of<CollectionListCubit>(context);
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    final Color unselectedColor = colorScheme.onSurface.withAlpha(160);
    final Color selectedColor = colorScheme.onSurface;
    final TextStyle unselectedTextStyle = TextStyle(color: unselectedColor);
    final TextStyle selectedTextStyle = TextStyle(color: selectedColor);

    return NavigationRail(
      selectedIndex: HomepageNavigationItem.values.indexOf(state.navItem),
      indicatorColor: Colors.transparent,
      backgroundColor: colorScheme.surfaceContainer,
      labelType: NavigationRailLabelType.all,
      destinations: <NavigationRailDestination>[
        NavigationRailDestination(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          icon: Icon(
            Icons.shelves,
            color: unselectedColor,
          ),
          selectedIcon: Icon(
            Icons.shelves,
            color: selectedColor,
          ),
          label: Text(
            key: const ValueKey<String>('homepage_bookshelf'),
            appLocalizations.generalBookshelf,
            style: state.navItem.isBookshelf
                ? selectedTextStyle
                : unselectedTextStyle,
          ),
          disabled: state.navItem.isBookshelf || !state.isEnabled,
        ),
        NavigationRailDestination(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          icon: ExploreBrowserIcon.outlined(
            color: unselectedColor,
          ),
          selectedIcon: ExploreBrowserIcon(
            color: selectedColor,
          ),
          label: Text(
            key: const ValueKey<String>('homepage_explore'),
            appLocalizations.generalExplore,
            style: state.navItem.isDiscovery
                ? selectedTextStyle
                : unselectedTextStyle,
          ),
          disabled: state.navItem.isDiscovery || !state.isEnabled,
        ),
        NavigationRailDestination(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          icon: Icon(
            Icons.bookmarks_outlined,
            color: unselectedColor,
          ),
          selectedIcon: Icon(
            Icons.bookmarks_rounded,
            color: selectedColor,
          ),
          label: Text(
            key: const ValueKey<String>('homepage_bookmark'),
            appLocalizations.generalBookmark(2),
            style: state.navItem.isBookmark
                ? selectedTextStyle
                : unselectedTextStyle,
          ),
          disabled: state.navItem.isBookmark || !state.isEnabled,
        ),
        NavigationRailDestination(
          padding: const EdgeInsets.symmetric(vertical: 16.0),
          icon: Icon(
            Icons.settings_outlined,
            color: unselectedColor,
          ),
          selectedIcon: Icon(
            Icons.settings_rounded,
            color: selectedColor,
          ),
          label: Text(
            key: const ValueKey<String>('homepage_settings'),
            appLocalizations.generalSettings,
            style: state.navItem.isSettings
                ? selectedTextStyle
                : unselectedTextStyle,
          ),
          disabled: state.navItem.isSettings || !state.isEnabled,
        ),
      ],
      onDestinationSelected: (int index) {
        switch (state.navItem) {
          case HomepageNavigationItem.bookshelf:
            bookshelfCubit.unfocused();
            break;
          case HomepageNavigationItem.bookmark:
            bookmarkListCubit.unfocused();
            break;
          case HomepageNavigationItem.explore:
            collectionListCubit.unfocused();
            break;
          default:
        }
        cubit.item = HomepageNavigationItem.fromIndex(index);
      },
    );
  }
}
