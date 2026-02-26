import 'package:flutter/services.dart';

import '../../../css_parser/domain/entities/css_font_file.dart';
import '../../domain/repositories/app_font_loader.dart';

class AppFontLoaderImpl implements AppFontLoader {
  @override
  Future<void> loadCssFont(Set<CssFontFile> fileSet) async {
    for (CssFontFile fontFile in fileSet) {
      final String fontFamily = fontFile.fontFace.fontFamily;
      final FontLoader loader = FontLoader(fontFamily);

      loader.addFont(
        Future<ByteData>.value(
          ByteData.sublistView(
            fontFile.bytes,
          ),
        ),
      );

      await loader.load();
    }
  }
}
