import 'dart:ui';

import 'domain/entities/css_document.dart';
import 'domain/entities/declarations/css_declaration.dart';
import 'domain/entities/rule_sets/css_font_face.dart';

class CssParser {
  CssDocument parseDocument(String content) {
    return CssDocument(
      content: content,
      fontFaces: parseFontFaceList(content),
    );
  }

  List<CssFontFace> parseFontFaceList(String content) {
    final List<CssFontFace> list = <CssFontFace>[];

    // Parse the font-face
    int startIndex = content.indexOf('@font-face');
    while (startIndex != -1) {
      final int endIndex = content.indexOf('}', startIndex);

      if (endIndex == -1) {
        // The bracket is not closed.
        break;
      } else {
        final CssFontFace? fontFace =
            parseFontFace(content.substring(startIndex, endIndex + 1));
        if (fontFace != null) {
          list.add(fontFace);
        }

        startIndex = content.indexOf('@font-face', endIndex + 1);
      }
    }

    return list;
  }

  CssFontFace? parseFontFace(String rule) {
    final int leftBracket = rule.indexOf('{');
    final int rightBracket = rule.indexOf('}');
    final String declarations = rule.substring(leftBracket + 1, rightBracket);
    final List<String> validDeclarations = declarations
        .split(';')
        .where((String str) => str.contains(':'))
        .toList();

    String? fontFamily;
    FontStyle? fontStyle;
    FontWeight? fontWeight;
    String? url;
    for (String declaration in validDeclarations) {
      final CssDeclaration cssDeclaration = parseDeclaration(declaration);

      switch (cssDeclaration.property) {
        case 'font-family':
          fontFamily = cssDeclaration.value;
          break;
        case 'font-style':
          fontStyle = switch (cssDeclaration.value) {
            'normal' => FontStyle.normal,
            'initial' => FontStyle.normal,
            'italic' => FontStyle.italic,
            'oblique' => FontStyle.italic,
            _ => FontStyle.normal,
          };
          break;
        case 'font-weight':
          fontWeight = switch (cssDeclaration.value) {
            'normal' => FontWeight.normal,
            'bold' => FontWeight.bold,
            '100' => FontWeight.w100,
            '200' => FontWeight.w200,
            '300' => FontWeight.w300,
            '400' => FontWeight.w400,
            '500' => FontWeight.w500,
            '600' => FontWeight.w600,
            '700' => FontWeight.w700,
            '800' => FontWeight.w800,
            '900' => FontWeight.w900,
            _ => FontWeight.normal,
          };
          break;
        case 'src':
          final RegExp srcRegExp = RegExp('url\\(["\']?(.*?)["\']?\\)');
          final RegExpMatch? match = srcRegExp.firstMatch(cssDeclaration.value);
          if (match != null) {
            url = match.group(1)!;
          }
      }
    }

    if (fontFamily == null || url == null) {
      return null;
    }

    return CssFontFace(
      fontFamily: fontFamily,
      fontStyle: fontStyle ?? FontStyle.normal,
      fontWeight: fontWeight ?? FontWeight.normal,
      url: url,
    );
  }

  CssDeclaration parseDeclaration(String declaration) {
    final int colonIndex = declaration.indexOf(':');
    final String property = declaration.substring(0, colonIndex).trim();
    final String value = declaration.substring(colonIndex + 1).trim();
    return CssDeclaration(property, value);
  }
}
