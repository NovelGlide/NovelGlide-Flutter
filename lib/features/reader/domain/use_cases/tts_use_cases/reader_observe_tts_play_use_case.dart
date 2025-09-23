import '../../../../../core/domain/use_cases/use_case.dart';
import '../../repositories/reader_tts_repository.dart';

class ReaderObserveTtsPlayUseCase extends UseCase<Stream<String>, void> {
  ReaderObserveTtsPlayUseCase(this._repository);

  final ReaderTtsRepository _repository;

  @override
  Stream<String> call([void parameter]) {
    return _repository.onPlayTts;
  }
}
