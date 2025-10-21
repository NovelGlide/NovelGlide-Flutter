import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:url_launcher/url_launcher.dart';

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
          ..._browserDefaultStyle,
          'a': Style(
            color: Theme.of(context).colorScheme.brightness == Brightness.light
                ? const Color(0xFF044C9F)
                : const Color(0xFF99C3FF),
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
    final RegExp regExp = RegExp(r'(http(s)?:)?//(.*)');
    final String url = href ?? '';

    if (regExp.hasMatch(url)) {
      // It's a http(s) link.
      final Uri? uri = Uri.tryParse(url);
      if (uri != null) {
        launchUrl(uri);
      }
    } else {
      final String path =
          cubit.getInBookPath(bookHtmlContent.pageIdentifier, url);
      if (!await cubit.goto(pageIdentifier: path)) {
        // This page is not in the book.
      }
    }

    return null;
  }

  static final Map<String, Style> _browserDefaultStyle = <String, Style>{
    'h1': Style(
      display: Display.block,
      margin: Margins.symmetric(
        vertical: 0.67,
        unit: Unit.em,
      ),
      fontSize: FontSize(2, Unit.rem),
      fontWeight: FontWeight.bold,
    ),
    'h2': Style(
      display: Display.block,
      margin: Margins.symmetric(
        vertical: 0.83,
        unit: Unit.em,
      ),
      fontSize: FontSize(1.5, Unit.rem),
      fontWeight: FontWeight.bold,
    ),
    'h3': Style(
      display: Display.block,
      margin: Margins.symmetric(
        vertical: 1,
        unit: Unit.em,
      ),
      fontSize: FontSize(1.17, Unit.rem),
      fontWeight: FontWeight.bold,
    ),
    'h4': Style(
      display: Display.block,
      margin: Margins.symmetric(
        vertical: 1.33,
        unit: Unit.em,
      ),
      fontSize: FontSize(1, Unit.rem),
      fontWeight: FontWeight.bold,
    ),
    'h5': Style(
      display: Display.block,
      margin: Margins.symmetric(
        vertical: 0.83,
        unit: Unit.em,
      ),
      fontSize: FontSize(1.67, Unit.rem),
      fontWeight: FontWeight.bold,
    ),
    'h6': Style(
      display: Display.block,
      margin: Margins.symmetric(
        vertical: 0.67,
        unit: Unit.em,
      ),
      fontSize: FontSize(2.33, Unit.rem),
      fontWeight: FontWeight.bold,
    ),
  };
}
