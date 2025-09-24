import '../../../../core/domain/use_cases/use_case.dart';
import '../repositories/reader_core_repository.dart';

class ReaderNextPageUseCase extends UseCase<void, void> {
  ReaderNextPageUseCase(this._repository);

  final ReaderCoreRepository _repository;

  @override
  void call([void parameter]) {
    _repository.nextPage();
  }
}
