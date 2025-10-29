import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/utils/popup_menu_utils.dart';
import '../../../../enum/loading_state_code.dart';
import '../../../../features/shared_components/common_delete_dialog.dart';
import '../../../../features/shared_components/shared_list/shared_list.dart';
import '../../../../main.dart';
import '../../../books/domain/entities/book.dart';
import '../../../books/domain/entities/book_cover.dart';
import '../../../books/presentation/book_cover/book_cover_builder.dart';
import '../../../books/presentation/book_widget/book_widget.dart';
import '../../../books/presentation/table_of_contents_page/table_of_contents.dart';
import '../../../shared_components/common_error_widgets/common_error_widget.dart';
import '../../../shared_components/common_loading_widgets/common_loading_widget.dart';
import '../../../shared_components/shared_list/presentation/widgets/shared_list_item_placeholder.dart';
import '../../domain/entities/collection_data.dart';
import 'cubit/collection_viewer_cubit.dart';

part 'widgets/collection_viewer_list_item.dart';
part 'widgets/collection_viewer_list_view.dart';
part 'widgets/collection_viewer_menu_button.dart';

class CollectionViewer extends StatelessWidget {
  const CollectionViewer({super.key, required this.collectionData});

  final CollectionData collectionData;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<CollectionViewerCubit>(
      create: (_) => sl<CollectionViewerCubit>()..init(collectionData),
      child: Scaffold(
        appBar: AppBar(
          title: Text(collectionData.name),
          actions: const <Widget>[
            SharedListSelectAllButton<CollectionViewerCubit>(),
            SharedListDoneButton<CollectionViewerCubit>(),
            CollectionViewerMenuButton(),
          ],
        ),
        body: const SafeArea(
          child: CollectionViewerListView(),
        ),
      ),
    );
  }
}
