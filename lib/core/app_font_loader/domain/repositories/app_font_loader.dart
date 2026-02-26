import '../../../css_parser/domain/entities/css_font_file.dart';

abstract class AppFontLoader {
  Future<void> loadCssFont(Set<CssFontFile> fileSet);
}
