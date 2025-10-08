import 'package:html/dom.dart';
import 'package:html/parser.dart' as html;
import 'package:path/path.dart';

import 'domain/entities/html_document.dart';

class HtmlParser {
  HtmlDocument parseDocument(String rawData, {String? sourceUrl}) {
    final Document parsedContent = html.parse(rawData, sourceUrl: sourceUrl);

    final String dirName = dirname(sourceUrl ?? '');

    // Get all stylesheets.
    final List<String> stylePathList = parsedContent.documentElement
            ?.getElementsByTagName('link')
            .where((Element e) => e.attributes['rel'] == 'stylesheet')
            .map((Element e) => normalize(join(dirName, e.attributes['href'])))
            .toList() ??
        <String>[];

    // Get all inline styles
    final List<String> inlineStyles = parsedContent.documentElement
            ?.getElementsByTagName('style')
            .map((Element e) => e.text)
            .toList() ??
        <String>[];

    return HtmlDocument(
      stylePathList: stylePathList,
      inlineStyles: inlineStyles,
    );
  }
}
