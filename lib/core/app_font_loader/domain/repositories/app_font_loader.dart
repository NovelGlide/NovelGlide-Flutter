import '../../../domain/entities/font_file.dart';

abstract class AppFontLoader {
  Future<void> loadCssFont(Set<FontFile> fileSet);
}
