import 'package:html/dom.dart';
import 'package:html/parser.dart' as html;
import 'package:path/path.dart';

import 'domain/entities/html_document.dart';

class HtmlParser {
  HtmlDocument parseDocument(String rawData, {String? sourceUrl}) {
    final Document domTree = html.parse(rawData, sourceUrl: sourceUrl);

    final String dirName = dirname(sourceUrl ?? '');

    // Get all stylesheets.
    final List<String>? stylePathList = domTree.documentElement
        ?.getElementsByTagName('link')
        .where((Element e) =>
            e.attributes['rel'] == 'stylesheet' && e.attributes['href'] != null)
        .map((Element e) => normalize(join(dirName, e.attributes['href'])))
        .toList();

    // Get all inline styles
    final List<String>? inlineStyles = domTree.documentElement
        ?.getElementsByTagName('style')
        .map((Element e) => e.text)
        .toList();

    // Get all images in this document.
    final List<String>? imgSrcList = domTree.documentElement
        ?.getElementsByTagName('img')
        .where((Element e) => e.attributes['src'] != null)
        .map((Element e) => normalize(join(dirName, e.attributes['src'])))
        .toList();

    // Get the text content in the body.
    final String? textContent = domTree.body?.text;

    return HtmlDocument(
      stylePathList: stylePathList ?? <String>[],
      inlineStyles: inlineStyles ?? <String>[],
      imgSrcList: imgSrcList ?? <String>[],
      textContent: textContent ?? '',
      domTree: domTree,
    );
  }
}
