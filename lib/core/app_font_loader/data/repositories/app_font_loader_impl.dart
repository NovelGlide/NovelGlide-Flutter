import 'package:flutter/services.dart';

import '../../../domain/entities/font_file.dart';
import '../../domain/repositories/app_font_loader.dart';

class AppFontLoaderImpl implements AppFontLoader {
  @override
  Future<void> loadCssFont(Set<FontFile> fileSet) async {
    for (FontFile fontFile in fileSet) {
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
