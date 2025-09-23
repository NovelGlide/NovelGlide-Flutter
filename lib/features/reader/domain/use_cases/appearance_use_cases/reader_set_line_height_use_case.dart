import '../../../../../core/domain/use_cases/use_case.dart';
import '../../repositories/reader_webview_repository.dart';

class ReaderSetLineHeightUseCase extends UseCase<void, double> {
  ReaderSetLineHeightUseCase(this._repository);

  final ReaderWebViewRepository _repository;

  @override
  void call(double parameter) {
    _repository.lineHeight = parameter;
  }
}
