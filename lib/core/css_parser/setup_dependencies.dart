import '../../main.dart';
import 'css_parser.dart';

void setupCssParserDependencies() {
  sl.registerLazySingleton<CssParser>(
    () => CssParser(),
  );
}
