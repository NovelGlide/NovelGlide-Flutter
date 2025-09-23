import '../../../../../core/domain/use_cases/use_case.dart';
import '../../repositories/reader_location_cache_repository.dart';

class ReaderDeleteLocationCacheUseCase
    extends UseCase<Future<void>, Set<String>> {
  const ReaderDeleteLocationCacheUseCase(this._repository);

  final ReaderLocationCacheRepository _repository;

  @override
  Future<void> call(Set<String> parameter) {
    return _repository.delete(parameter);
  }
}
