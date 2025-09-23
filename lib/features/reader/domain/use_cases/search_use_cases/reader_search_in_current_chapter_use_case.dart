import '../../../../../core/domain/use_cases/use_case.dart';
import '../../repositories/reader_search_repository.dart';

class ReaderSearchInCurrentChapterUseCase extends UseCase<void, String> {
  ReaderSearchInCurrentChapterUseCase(this._repository);

  final ReaderSearchRepository _repository;

  @override
  void call(String parameter) {
    _repository.searchInCurrentChapter(parameter);
  }
}
