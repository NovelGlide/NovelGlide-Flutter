import '../../../../core/domain/use_cases/use_case.dart';
import '../entities/reader_set_state_data.dart';
import '../repositories/reader_webview_repository.dart';

class ReaderObserveSetStateUseCase
    extends UseCase<Stream<ReaderSetStateData>, void> {
  ReaderObserveSetStateUseCase(this._repository);

  final ReaderWebViewRepository _repository;

  @override
  Stream<ReaderSetStateData> call([void parameter]) {
    return _repository.onSetState;
  }
}
