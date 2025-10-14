import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_html/flutter_html.dart';

import '../../../../books/domain/entities/book_html_content.dart';
import '../cubit/reader_cubit.dart';
import 'widgets/reader_core_html_image.dart';

class ReaderCoreHtml extends StatelessWidget {
  const ReaderCoreHtml({
    super.key,
    required this.state,
  });

  final ReaderState state;

  @override
  Widget build(BuildContext context) {
    final BookHtmlContent? htmlContent = state.htmlContent;
    if (htmlContent == null) {
      return const SizedBox.shrink();
    }

    final ReaderCubit cubit = BlocProvider.of<ReaderCubit>(context);

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Html.fromDom(
        document: htmlContent.domTree,
        onLinkTap: (String? href, __, ___) => _onLinkTap(
          href,
          htmlContent,
          cubit,
        ),
        extensions: <HtmlExtension>[
          ReaderCoreHtmlImage.tagExtension(htmlContent),
        ],
        style: <String, Style>{
          // Reader styles
          'html': Style(
            fontSize: FontSize(state.readerPreference.fontSize),
            lineHeight: LineHeight(state.readerPreference.lineHeight),
          ),
          'a': Style(
            textDecoration: TextDecoration.none,
          ),
          ...Style.fromCss(htmlContent.stylesheet, null),
        },
      ),
    );
  }

  Future<String?> _onLinkTap(
    String? href,
    BookHtmlContent bookHtmlContent,
    ReaderCubit cubit,
  ) async {
    final String path =
        cubit.getInBookPath(bookHtmlContent.pageIdentifier, href ?? '');
    if (!await cubit.goto(pageIdentifier: path)) {
      // This page is not in the book.
    }

    return null;
  }
}
