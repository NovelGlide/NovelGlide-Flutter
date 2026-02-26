import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../../../generated/i18n/app_localizations.dart';
import '../../../cubit/reader_cubit.dart';

class ReaderNavBookmarkButton extends StatelessWidget {
  const ReaderNavBookmarkButton({super.key});

  @override
  Widget build(BuildContext context) {
    final AppLocalizations appLocalizations = AppLocalizations.of(context)!;
    final ReaderCubit cubit = BlocProvider.of<ReaderCubit>(context);
    final ColorScheme colorScheme = Theme.of(context).colorScheme;

    return BlocBuilder<ReaderCubit, ReaderState>(
      buildWhen: (ReaderState previous, ReaderState current) =>
          previous.code != current.code ||
          previous.bookmarkData != current.bookmarkData ||
          previous.chapterFileName != current.chapterFileName ||
          previous.startCfi != current.startCfi ||
          previous.readerPreference.isAutoSaving !=
              current.readerPreference.isAutoSaving,
      builder: (BuildContext context, ReaderState state) {
        // Can the current page be bookmarked?
        final bool isEnabled =
            state.code.isLoaded && !state.readerPreference.isAutoSaving;

        // Was the current page bookmarked?
        final bool isBookmarked = !state.readerPreference.isAutoSaving &&
            state.bookmarkData?.startCfi == state.startCfi &&
            state.bookmarkData?.chapterIdentifier == state.chapterFileName;

        return IconButton(
          icon: Icon(
            isBookmarked
                ? Icons.bookmark_rounded
                : Icons.bookmark_outline_rounded,
          ),
          tooltip: appLocalizations.readerBookmark,
          style: IconButton.styleFrom(
            foregroundColor: isBookmarked ? colorScheme.error : null,
          ),
          onPressed: isEnabled
              ? () =>
                  isBookmarked ? cubit.removeBookmark() : cubit.saveBookmark()
              : null,
        );
      },
    );
  }
}
