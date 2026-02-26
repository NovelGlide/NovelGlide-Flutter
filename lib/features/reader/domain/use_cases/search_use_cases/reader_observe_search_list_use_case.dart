import '../../../../../core/domain/use_cases/use_case.dart';
import '../../entities/reader_search_result_data.dart';
import '../../repositories/reader_core_repository.dart';

class ReaderObserveSearchListUseCase
    extends UseCase<Stream<List<ReaderSearchResultData>>, void> {
  ReaderObserveSearchListUseCase(this._coreRepository);

  final ReaderCoreRepository _coreRepository;

  @override
  Stream<List<ReaderSearchResultData>> call([void parameter]) {
    return _coreRepository.onSetSearchResultList;
  }
}
