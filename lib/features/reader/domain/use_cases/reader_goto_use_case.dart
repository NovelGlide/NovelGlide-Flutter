import '../../../../core/domain/use_cases/use_case.dart';
import '../repositories/reader_core_repository.dart';

class ReaderGotoUseCase extends UseCase<void, String> {
  ReaderGotoUseCase(this._repository);

  final ReaderCoreRepository _repository;

  @override
  void call(String parameter) {
    _repository.goto(parameter);
  }
}
