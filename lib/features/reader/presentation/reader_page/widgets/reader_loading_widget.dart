import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../generated/i18n/app_localizations.dart';
import '../../../../shared_components/common_loading_widgets/common_loading_widget.dart';
import '../cubit/reader_cubit.dart';

class ReaderLoadingWidget extends StatelessWidget {
  const ReaderLoadingWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ReaderCubit, ReaderState>(
      buildWhen: (ReaderState previous, ReaderState current) =>
          previous.code != current.code,
      builder: (BuildContext context, ReaderState state) {
        final AppLocalizations appLocalizations = AppLocalizations.of(context)!;
        final String? title = switch (state.code) {
          ReaderLoadingStateCode.initial =>
            appLocalizations.readerLoadingInitialize,
          ReaderLoadingStateCode.preferenceLoading => 'Preference Loading...',
          ReaderLoadingStateCode.bookLoading =>
            appLocalizations.readerLoadingBookLoading,
          ReaderLoadingStateCode.rendering =>
            appLocalizations.readerLoadingRendering,
          ReaderLoadingStateCode.loaded => null,
        };

        return Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
          ),
          child: Center(
            child: CommonLoadingWidget(title: title),
          ),
        );
      },
    );
  }
}
