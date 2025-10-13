import 'package:flutter/material.dart';

import '../../search_page/widgets/reader_search_button.dart';
import 'reader_breadcrumb.dart';

class ReaderAppBar extends StatelessWidget implements PreferredSizeWidget {
  const ReaderAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: const ReaderBreadcrumb(),
      actions: const <Widget>[
        ReaderSearchButton(),
      ],
    );
  }
}
