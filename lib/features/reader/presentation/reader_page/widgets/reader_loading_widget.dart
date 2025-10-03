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

        return Container(
          width: double.infinity,
          height: double.infinity,
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surface,
          ),
          child: Center(
            child: CommonLoadingWidget(
                title: switch (state.code) {
              // Initial state.
              ReaderLoadingStateCode.initial =>
                appLocalizations.readerLoadingInitialize,
              // Loading the preference. TODO(kai): Localization
              ReaderLoadingStateCode.preferenceLoading =>
                'Loading preference...',
              // Loading the book.
              ReaderLoadingStateCode.bookLoading =>
                appLocalizations.readerLoadingBookLoading,
              // Rendering the content.
              ReaderLoadingStateCode.rendering =>
                appLocalizations.readerLoadingRendering,
              // Loading the page. TODO(kai): Localization
              ReaderLoadingStateCode.pageLoading => 'Loading page...',
              ReaderLoadingStateCode.loaded => null,
            }),
          ),
        );
      },
    );
  }
}
