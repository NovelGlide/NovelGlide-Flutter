import '../../../../../core/domain/use_cases/use_case.dart';
import '../../repositories/reader_search_repository.dart';

class ReaderSearchInWholeBookUseCase extends UseCase<void, String> {
  ReaderSearchInWholeBookUseCase(this._repository);

  final ReaderSearchRepository _repository;

  @override
  void call(String parameter) {
    _repository.searchInWholeBook(parameter);
  }
}
