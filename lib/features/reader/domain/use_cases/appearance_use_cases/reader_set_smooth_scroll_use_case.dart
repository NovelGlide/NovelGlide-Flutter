import '../../../../../core/domain/use_cases/use_case.dart';
import '../../repositories/reader_core_repository.dart';

class ReaderSetSmoothScrollUseCase extends UseCase<void, bool> {
  ReaderSetSmoothScrollUseCase(this._repository);

  final ReaderCoreRepository _repository;

  @override
  void call(bool parameter) {
    _repository.smoothScroll = parameter;
  }
}
