import '../../../../../core/domain/use_cases/use_case.dart';
import '../../repositories/reader_location_cache_repository.dart';

class ReaderClearLocationCacheUseCase extends UseCase<Future<void>, void> {
  const ReaderClearLocationCacheUseCase(this._repository);

  final ReaderLocationCacheRepository _repository;

  @override
  Future<void> call([void parameter]) {
    return _repository.clear();
  }
}
