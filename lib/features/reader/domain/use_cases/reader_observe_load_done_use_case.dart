import '../../../../core/domain/use_cases/use_case.dart';
import '../repositories/reader_webview_repository.dart';

class ReaderObserveLoadDoneUseCase extends UseCase<Stream<void>, void> {
  ReaderObserveLoadDoneUseCase(this._repository);

  final ReaderWebViewRepository _repository;

  @override
  Stream<void> call([void parameter]) {
    return _repository.onLoadDone;
  }
}
