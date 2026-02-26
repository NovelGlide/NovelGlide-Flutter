import '../../../../core/domain/use_cases/use_case.dart';
import '../repositories/reader_core_repository.dart';

class ReaderPreviousPageUseCase extends UseCase<Future<void>, void> {
  ReaderPreviousPageUseCase(this._repository);

  final ReaderCoreRepository _repository;

  @override
  Future<void> call([void parameter]) {
    return _repository.previousPage();
  }
}
