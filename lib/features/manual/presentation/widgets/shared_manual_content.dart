import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:markdown_widget/widget/markdown.dart';

import '../../../../enum/loading_state_code.dart';
import '../../../shared_components/common_error_widgets/common_error_widget.dart';
import '../../../shared_components/common_loading_widgets/common_loading_widget.dart';
import '../cubit/shared_manual_cubit.dart';
import '../cubit/shared_manual_state.dart';

class SharedManualContent extends StatelessWidget {
  const SharedManualContent({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<SharedManualCubit, SharedManualState>(
      buildWhen: (SharedManualState previous, SharedManualState current) =>
          current.code != previous.code,
      builder: (BuildContext context, SharedManualState state) {
        switch (state.code) {
          case LoadingStateCode.initial:
          case LoadingStateCode.loading:
          case LoadingStateCode.backgroundLoading:
            return const CommonLoadingWidget();

          case LoadingStateCode.loaded:
            if (state.markdown != null) {
              return Scrollbar(
                child: MarkdownWidget(
                  data: state.markdown!,
                ),
              );
            }
            break;

          default:
        }

        return const CommonErrorWidget();
      },
    );
  }
}
