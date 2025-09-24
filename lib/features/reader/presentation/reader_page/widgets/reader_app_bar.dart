import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../search_page/widgets/reader_search_button.dart';
import '../cubit/reader_cubit.dart';

class ReaderAppBar extends StatelessWidget implements PreferredSizeWidget {
  const ReaderAppBar({super.key});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: BlocBuilder<ReaderCubit, ReaderState>(
        buildWhen: (ReaderState previous, ReaderState current) =>
            previous.bookName != current.bookName,
        builder: (BuildContext context, ReaderState state) {
          return Text(state.bookName);
        },
      ),
      actions: const <Widget>[
        ReaderSearchButton(),
      ],
    );
  }
}
