import '../../../../../core/domain/use_cases/use_case.dart';
import '../../repositories/reader_core_repository.dart';

class ReaderSetLineHeightUseCase extends UseCase<void, double> {
  ReaderSetLineHeightUseCase(this._repository);

  final ReaderCoreRepository _repository;

  @override
  void call(double parameter) {
    _repository.lineHeight = parameter;
  }
}
