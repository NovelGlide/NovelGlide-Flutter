import '../../../../core/domain/use_cases/use_case.dart';
import '../repositories/pick_file_repository.dart';

class PickFileClearTempUseCase extends UseCase<Future<void>, void> {
  PickFileClearTempUseCase(this._pickFileRepository);

  final PickFileRepository _pickFileRepository;

  @override
  Future<void> call([void parameter]) {
    return _pickFileRepository.clearTemporaryFiles();
  }
}
