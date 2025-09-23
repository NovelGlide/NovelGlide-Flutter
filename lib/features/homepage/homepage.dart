import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../enum/window_size.dart';
import '../../main.dart';
import '../advertisement/domain/entities/ad_unit_id.dart';
import '../advertisement/presentation/advertisement.dart';
import '../bookmark/presentation/bookmark_list/cubit/bookmark_list_cubit.dart';
import '../books/presentation/book_list/cubit/book_list_cubit.dart';
import '../books/presentation/bookshelf/cubit/bookshelf_cubit.dart';
import '../collection/presentation/collection_list/cubit/collection_list_cubit.dart';
import '../explore/presentation/browser/cubits/explore_browser_cubit.dart';
import 'cubit/homepage_cubit.dart';
import 'widgets/homepage_app_bar_builder.dart';
import 'widgets/homepage_floating_action_widget.dart';
import 'widgets/homepage_navigation_bar.dart';
import 'widgets/homepage_navigation_rail.dart';
import 'widgets/homepage_scaffold_body.dart';

part 'homepage_app_bar.dart';
part 'view/homepage_compact_view.dart';
part 'view/homepage_medium_view.dart';

/// The homepage of the app
class Homepage extends StatelessWidget {
  const Homepage({super.key});

  @override
  Widget build(BuildContext context) {
    final WindowSize windowClass = WindowSize.of(context);

    return MultiBlocProvider(
      providers: <BlocProvider<dynamic>>[
        BlocProvider<HomepageCubit>(
          create: (_) => HomepageCubit(),
        ),
        BlocProvider<BookshelfCubit>(
          create: (_) => BookshelfCubit(),
        ),
        BlocProvider<BookListCubit>(
          create: (_) => sl<BookListCubit>(),
        ),
        BlocProvider<CollectionListCubit>(
          create: (_) => sl<CollectionListCubit>(),
        ),
        BlocProvider<ExploreBrowserCubit>(
          create: (_) => sl<ExploreBrowserCubit>(),
        ),
        BlocProvider<BookmarkListCubit>(
          create: (_) => sl<BookmarkListCubit>(),
        ),
      ],
      child: switch (windowClass) {
        WindowSize.compact => const HomepageCompactView(),
        _ => const HomepageMediumView(),
      },
    );
  }
}
