import '../../../../core/domain/use_cases/use_case.dart';
import '../repositories/reader_core_repository.dart';

class ReaderNextPageUseCase extends UseCase<Future<void>, void> {
  ReaderNextPageUseCase(this._repository);

  final ReaderCoreRepository _repository;

  @override
  Future<void> call([void parameter]) {
    return _repository.nextPage();
  }
}
