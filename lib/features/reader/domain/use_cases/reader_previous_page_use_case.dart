import '../../../../core/domain/use_cases/use_case.dart';
import '../repositories/reader_webview_repository.dart';

class ReaderPreviousPageUseCase extends UseCase<void, void> {
  ReaderPreviousPageUseCase(this._repository);

  final ReaderWebViewRepository _repository;

  @override
  void call([void parameter]) {
    _repository.previousPage();
  }
}
