import '../../main.dart';
import 'html_parser.dart';

void setupHtmlParserDependencies() {
  sl.registerLazySingleton<HtmlParser>(
    () => HtmlParser(),
  );
}
