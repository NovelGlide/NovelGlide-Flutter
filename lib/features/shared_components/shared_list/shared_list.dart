import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../enum/loading_state_code.dart';
import '../../../enum/sort_order_code.dart';
import '../../../generated/i18n/app_localizations.dart';
import '../animated_switchers/simple_fade_switcher.dart';
import '../random_shock_emoticon_text.dart';

part 'presentation/button/shared_list_delete_button.dart';
part 'presentation/button/shared_list_done_button.dart';
part 'presentation/button/shared_list_select_all_button.dart';
part 'presentation/cubit/shared_list_cubit.dart';
part 'presentation/cubit/shared_list_state.dart';
part 'presentation/cubit/shared_list_type.dart';
part 'presentation/widgets/shared_list_empty.dart';
part 'presentation/widgets/shared_list_grid_item.dart';
part 'presentation/widgets/shared_list_more_menu_tile.dart';
part 'presentation/widgets/shared_list_sliver_empty.dart';
part 'presentation/widgets/shared_list_tile.dart';

class SharedList extends StatelessWidget {
  const SharedList({
    super.key,
    required this.listType,
    required this.gridDelegate,
    required this.delegate,
  });

  final SharedListType listType;
  final SliverGridDelegate gridDelegate;
  final SliverChildDelegate delegate;

  @override
  Widget build(BuildContext context) {
    switch (listType) {
      case SharedListType.list:
        return SliverList(
          delegate: delegate,
        );

      case SharedListType.grid:
        return SliverGrid(
          gridDelegate: gridDelegate,
          delegate: delegate,
        );
    }
  }

  /// **************************************************************************
  /// Static methods

  /// Build selection mode button
  static PopupMenuItem<void> buildSelectionModeButton({
    required BuildContext context,
    required SharedListCubit<dynamic> cubit,
  }) {
    return PopupMenuItem<void>(
      onTap: () => cubit.isSelecting = true,
      child: SharedListMoreMenuTile(
        title: AppLocalizations.of(context)!.generalSelect,
        trailing: const Icon(Icons.check_circle_outline_rounded),
      ),
    );
  }

  /// Build the sort menu
  static List<PopupMenuItem<void>> buildSortMenu({
    required List<String> titleList,
    required List<SortOrderCode> sortOrderList,
    required SharedListCubit<dynamic> cubit,
  }) {
    return List<PopupMenuItem<void>>.generate(sortOrderList.length, (int i) {
      final SortOrderCode sortOrderCode = sortOrderList[i];
      final bool isSelected = cubit.state.sortOrder == sortOrderCode;
      return PopupMenuItem<void>(
        onTap: () {
          if (cubit.state.sortOrder == sortOrderCode) {
            cubit.isAscending = !cubit.state.isAscending;
          } else {
            cubit.sortOrder = sortOrderCode;
          }
        },
        child: SharedListMoreMenuTile(
          isSelected: isSelected,
          trailing: isSelected
              ? Icon(cubit.state.isAscending
                  ? CupertinoIcons.chevron_up
                  : CupertinoIcons.chevron_down)
              : null,
          title: titleList[i],
        ),
      );
    });
  }

  /// Build changing list view menu
  static List<PopupMenuItem<void>> buildViewMenu({
    required List<String> titleList,
    required List<SharedListType> typeList,
    required List<IconData> iconList,
    required SharedListCubit<dynamic> cubit,
  }) {
    return List<PopupMenuItem<void>>.generate(typeList.length, (int i) {
      final SharedListType type = typeList[i];
      return PopupMenuItem<void>(
        onTap: () => cubit.listType = type,
        child: SharedListMoreMenuTile(
          isSelected: cubit.state.listType == type,
          title: titleList[i],
          trailing: Icon(iconList[i]),
        ),
      );
    });
  }

  static List<PopupMenuItem<void>> buildGeneralViewMenu({
    required BuildContext context,
    required SharedListCubit<dynamic> cubit,
  }) {
    final AppLocalizations appLocalizations = AppLocalizations.of(context)!;
    return buildViewMenu(
      titleList: <String>[
        appLocalizations.generalIcon,
        appLocalizations.generalList,
      ],
      typeList: <SharedListType>[
        SharedListType.grid,
        SharedListType.list,
      ],
      iconList: <IconData>[
        Icons.grid_view_rounded,
        Icons.list_rounded,
      ],
      cubit: cubit,
    );
  }
}
