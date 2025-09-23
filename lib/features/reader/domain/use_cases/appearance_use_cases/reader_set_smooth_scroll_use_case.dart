import '../../../../../core/domain/use_cases/use_case.dart';
import '../../repositories/reader_webview_repository.dart';

class ReaderSetSmoothScrollUseCase extends UseCase<void, bool> {
  ReaderSetSmoothScrollUseCase(this._repository);

  final ReaderWebViewRepository _repository;

  @override
  void call(bool parameter) {
    _repository.smoothScroll = parameter;
  }
}
