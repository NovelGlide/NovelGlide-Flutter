import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/reader_cubit.dart';
import 'reader_core_html.dart';

class ReaderCoreHtmlWrapper extends StatelessWidget {
  const ReaderCoreHtmlWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: BlocBuilder<ReaderCubit, ReaderState>(
        buildWhen: (ReaderState previous, ReaderState current) =>
            previous.htmlContent != current.htmlContent ||
            previous.readerPreference != current.readerPreference,
        builder: (BuildContext context, ReaderState state) {
          return Scrollbar(
            child: SingleChildScrollView(
              child: ReaderCoreHtml(
                state: state,
              ),
            ),
          );
        },
      ),
    );
  }
}
