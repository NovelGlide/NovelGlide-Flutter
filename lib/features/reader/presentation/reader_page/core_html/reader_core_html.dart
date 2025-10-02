import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_html/flutter_html.dart';

import '../cubit/reader_cubit.dart';

class ReaderCoreHtml extends StatelessWidget {
  const ReaderCoreHtml({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ReaderCubit, ReaderState>(
      buildWhen: (ReaderState previous, ReaderState current) =>
          previous.content != current.content,
      builder: (BuildContext context, ReaderState state) {
        return Scrollbar(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Html(
                data: state.content,
                onLinkTap: (_, __, ___) {},
                shrinkWrap: true,
              ),
            ),
          ),
        );
      },
    );
  }
}
