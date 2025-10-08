import 'package:csslib/src/messages.dart';
import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';

import '../../../../../core/log_system/log_system.dart';
import '../cubit/reader_cubit.dart';

class ReaderCoreHtml extends StatelessWidget {
  const ReaderCoreHtml({
    super.key,
    required this.state,
  });

  final ReaderState state;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Html(
        data: state.htmlContent?.content ?? '',
        onLinkTap: (_, __, ___) {},
        style: <String, Style>{
          // Reader styles
          'html': Style(
            fontSize: FontSize(state.readerPreference.fontSize),
            lineHeight: LineHeight(state.readerPreference.lineHeight),
          ),
          ...Style.fromCss(
            state.htmlContent?.stylesheet ?? '',
            (String css, List<Message> errors) {
              LogSystem.error(
                'ReaderCoreHtml parse CSS Error',
                error: errors,
              );

              return null;
            },
          ),
        },
      ),
    );
  }
}
