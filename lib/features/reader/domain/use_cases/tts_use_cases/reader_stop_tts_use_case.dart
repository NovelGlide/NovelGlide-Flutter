import '../../../../../core/domain/use_cases/use_case.dart';
import '../../repositories/reader_tts_repository.dart';

class ReaderStopTtsUseCase extends UseCase<void, void> {
  ReaderStopTtsUseCase(this._repository);

  final ReaderTtsRepository _repository;

  @override
  void call([void parameter]) {
    _repository.ttsStop();
  }
}
