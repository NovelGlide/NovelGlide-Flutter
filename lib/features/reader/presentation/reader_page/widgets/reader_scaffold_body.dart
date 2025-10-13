import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../advertisement/domain/entities/ad_unit_id.dart';
import '../../../../advertisement/presentation/advertisement.dart';
import '../../../domain/entities/reader_core_type.dart';
import '../core_html/reader_core_html_wrapper.dart';
import '../core_webview/reader_core_webview.dart';
import '../cubit/reader_cubit.dart';
import 'reader_overlap_widget.dart';
import 'reader_pagination.dart';

class ReaderScaffoldBody extends StatelessWidget {
  const ReaderScaffoldBody({super.key});

  @override
  Widget build(BuildContext context) {
    final ReaderCubit cubit = BlocProvider.of<ReaderCubit>(context);
    return Column(
      children: <Widget>[
        const Advertisement(
          unitId: AdUnitId.reader,
          height: 60.0,
        ),
        Expanded(
          child: Stack(
            children: <Widget>[
              /// Reader WebView
              Positioned.fill(
                child: BlocBuilder<ReaderCubit, ReaderState>(
                  buildWhen: (ReaderState previous, ReaderState current) =>
                      previous.code != current.code,
                  builder: (BuildContext context, ReaderState state) {
                    return state.code.isInitial
                        ? const SizedBox.shrink()
                        : _buildReader(cubit);
                  },
                ),
              ),

              /// Reader Overlay (including loading and searching widgets.)
              const Positioned.fill(
                child: ReaderOverlapWidget(),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReader(ReaderCubit cubit) {
    return Column(
      children: <Widget>[
        Expanded(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,

            /// Swipe to prev/next page
            onHorizontalDragStart: cubit.gestureHandler.onStart,
            onHorizontalDragEnd: cubit.gestureHandler.onEnd,
            onHorizontalDragCancel: cubit.gestureHandler.onCancel,
            child: BlocBuilder<ReaderCubit, ReaderState>(
              builder: (BuildContext context, ReaderState state) {
                return switch (state.coreType) {
                  ReaderCoreType.webView => const ReaderCoreWebView(),
                  ReaderCoreType.html => const ReaderCoreHtmlWrapper(),
                  null => const SizedBox.shrink(),
                };
              },
            ),
          ),
        ),
        const ReaderPagination(),
      ],
    );
  }
}
