import '../../../../../core/domain/use_cases/use_case.dart';
import '../../repositories/reader_core_repository.dart';

class ReaderSearchInCurrentChapterUseCase extends UseCase<void, String> {
  ReaderSearchInCurrentChapterUseCase(this._coreRepository);

  final ReaderCoreRepository _coreRepository;

  @override
  void call(String parameter) {
    _coreRepository.searchInCurrentChapter(parameter);
  }
}
