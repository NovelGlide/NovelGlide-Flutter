import '../../../../../core/domain/use_cases/use_case.dart';
import '../../repositories/reader_tts_repository.dart';

class ReaderObserveTtsStopUseCase extends UseCase<Stream<void>, void> {
  ReaderObserveTtsStopUseCase(this._repository);

  final ReaderTtsRepository _repository;

  @override
  Stream<void> call([void parameter]) {
    return _repository.onStopTts;
  }
}
