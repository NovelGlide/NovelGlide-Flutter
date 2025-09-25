import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../../enum/window_size.dart';
import '../../../../../generated/i18n/app_localizations.dart';
import '../../../../reader/presentation/reader_page/reader.dart';
import '../../../domain/entities/book.dart';
import '../cubit/toc_cubit.dart';
import '../cubit/toc_state.dart';

class TocFabSection extends StatelessWidget {
  const TocFabSection({super.key, required this.bookData});

  final Book bookData;

  @override
  Widget build(BuildContext context) {
    final double windowWidth = MediaQuery.sizeOf(context).width;
    final WindowSize windowClass = WindowSize.fromWidth(windowWidth);
    double maxWidth = windowWidth - kFloatingActionButtonMargin;

    if (windowClass != WindowSize.compact) {
      maxWidth *= 0.618;
    }

    return Container(
      padding: const EdgeInsets.only(left: kFloatingActionButtonMargin),
      constraints: BoxConstraints(maxWidth: maxWidth),
      child: BlocBuilder<TocCubit, TocState>(
        builder: (BuildContext context, TocState state) {
          final List<Widget> children = <Widget>[
            ElevatedButton.icon(
              key: const ValueKey<String>('tocFabStartReading'),
              onPressed: () {
                Navigator.of(context).push(MaterialPageRoute<void>(
                  builder: (_) => ReaderWidget(
                    bookIdentifier: bookData.identifier,
                    bookData: bookData,
                  ),
                ));
              },
              style: ElevatedButton.styleFrom(
                iconColor: Theme.of(context).colorScheme.onPrimary,
                backgroundColor: Theme.of(context).colorScheme.primary,
                foregroundColor: Theme.of(context).colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(
                    horizontal: 24.0, vertical: 12.0),
                fixedSize: const Size.fromHeight(56.0),
                elevation: 5.0,
              ),
              icon: const Icon(Icons.menu_book_rounded),
              label: Text(AppLocalizations.of(context)!.tocStartReading),
            )
          ];

          if (state.bookmarkData != null) {
            children.add(Padding(
              padding: const EdgeInsets.only(left: 16.0),
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.of(context).push(MaterialPageRoute<void>(
                    builder: (_) => ReaderWidget(
                      bookIdentifier: bookData.identifier,
                      bookData: bookData,
                      chapterIdentifier: state.bookmarkData?.chapterIdentifier,
                      cfi: state.bookmarkData?.startCfi,
                    ),
                  ));
                },
                style: ElevatedButton.styleFrom(
                  iconColor: Theme.of(context).colorScheme.onPrimary,
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24.0,
                    vertical: 12.0,
                  ),
                  fixedSize: const Size.fromHeight(56.0),
                  elevation: 5.0,
                ),
                icon: const Icon(Icons.bookmark_rounded),
                label: Text(AppLocalizations.of(context)!.tocContinueReading),
              ),
            ));
          }

          return SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: children,
            ),
          );
        },
      ),
    );
  }
}
