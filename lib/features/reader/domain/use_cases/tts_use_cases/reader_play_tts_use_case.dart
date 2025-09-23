import '../../../../../core/domain/use_cases/use_case.dart';
import '../../repositories/reader_tts_repository.dart';

class ReaderPlayTtsUseCase extends UseCase<void, void> {
  ReaderPlayTtsUseCase(this._repository);

  final ReaderTtsRepository _repository;

  @override
  void call([void parameter]) {
    _repository.ttsPlay();
  }
}
