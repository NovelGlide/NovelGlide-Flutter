import '../../../../../core/domain/use_cases/use_case.dart';
import '../../entities/reader_search_result_data.dart';
import '../../repositories/reader_search_repository.dart';

class ReaderObserveSearchListUseCase
    extends UseCase<Stream<List<ReaderSearchResultData>>, void> {
  ReaderObserveSearchListUseCase(this._repository);

  final ReaderSearchRepository _repository;

  @override
  Stream<List<ReaderSearchResultData>> call([void parameter]) {
    return _repository.onSetSearchResultList;
  }
}
