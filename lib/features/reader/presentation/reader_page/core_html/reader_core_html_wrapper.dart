import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/reader_cubit.dart';
import 'reader_core_html.dart';

class ReaderCoreHtmlWrapper extends StatefulWidget {
  const ReaderCoreHtmlWrapper({super.key});

  @override
  State<ReaderCoreHtmlWrapper> createState() => _ReaderCoreHtmlWrapperState();
}

class _ReaderCoreHtmlWrapperState extends State<ReaderCoreHtmlWrapper> {
  final ScrollController _scrollController = ScrollController();

  @override
  Widget build(BuildContext context) {
    return SizedBox.expand(
      child: Scrollbar(
        controller: _scrollController,
        child: SingleChildScrollView(
          controller: _scrollController,
          child: BlocConsumer<ReaderCubit, ReaderState>(
            listenWhen: (ReaderState previous, ReaderState current) =>
                previous.htmlContent != current.htmlContent,
            listener: (BuildContext context, ReaderState state) {
              // Scroll to top.
              _scrollController.jumpTo(0.0);
            },
            buildWhen: (ReaderState previous, ReaderState current) =>
                previous.htmlContent != current.htmlContent ||
                previous.readerPreference != current.readerPreference,
            builder: (BuildContext context, ReaderState state) {
              return ReaderCoreHtml(
                state: state,
              );
            },
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }
}
