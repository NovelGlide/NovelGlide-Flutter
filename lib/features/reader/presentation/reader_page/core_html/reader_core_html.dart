import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_html/flutter_html.dart';

import '../../../../shared_components/common_error_widgets/common_error_widget.dart';
import '../cubit/reader_cubit.dart';

class ReaderCoreHtml extends StatelessWidget {
  const ReaderCoreHtml({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ReaderCubit, ReaderState>(
      buildWhen: (ReaderState previous, ReaderState current) =>
          previous.content != current.content,
      builder: (BuildContext context, ReaderState state) {
        if (state.content == null) {
          return const CommonErrorWidget();
        } else {
          return Html(
            data: state.content,
          );
        }
      },
    );
  }
}
