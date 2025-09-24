part of '../reader.dart';

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
        const ReaderBreadcrumb(),
        Expanded(
          child: GestureDetector(
            behavior: HitTestBehavior.translucent,

            /// Swipe to prev/next page
            onHorizontalDragStart: cubit.gestureHandler.onStart,
            onHorizontalDragEnd: cubit.gestureHandler.onEnd,
            onHorizontalDragCancel: cubit.gestureHandler.onCancel,
            child: const ReaderCoreWebView(),
          ),
        ),
        const ReaderPagination(),
      ],
    );
  }
}
