import '../../../css_parser/domain/entities/css_font_file.dart';
import '../../../domain/use_cases/use_case.dart';
import '../repositories/app_font_loader.dart';

class AppFontLoaderLoadCssFontUseCase
    extends UseCase<Future<void>, Set<CssFontFile>> {
  const AppFontLoaderLoadCssFontUseCase(this._fontLoader);

  final AppFontLoader _fontLoader;

  @override
  Future<void> call(Set<CssFontFile> parameter) {
    return _fontLoader.loadCssFont(parameter);
  }
}
