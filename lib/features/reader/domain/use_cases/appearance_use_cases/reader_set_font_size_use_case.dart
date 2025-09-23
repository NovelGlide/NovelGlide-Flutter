import '../../../../../core/domain/use_cases/use_case.dart';
import '../../repositories/reader_webview_repository.dart';

class ReaderSetFontSizeUseCase extends UseCase<void, double> {
  ReaderSetFontSizeUseCase(this._repository);

  final ReaderWebViewRepository _repository;

  @override
  void call(double parameter) {
    _repository.fontSize = parameter;
  }
}
