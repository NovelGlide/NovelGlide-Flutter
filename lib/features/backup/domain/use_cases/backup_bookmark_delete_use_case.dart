import 'dart:async';

import '../../../../core/domain/use_cases/use_case.dart';
import '../entities/backup_progress_data.dart';
import '../entities/backup_progress_step_code.dart';
import '../repositories/bookmark_backup_repository.dart';

class BackupBookmarkDeleteUseCase
    extends UseCase<Stream<BackupProgressData>, void> {
  BackupBookmarkDeleteUseCase(
    this._repository,
  );

  final BookmarkBackupRepository _repository;

  final StreamController<BackupProgressData> _controller =
      StreamController<BackupProgressData>();

  @override
  Stream<BackupProgressData> call([void parameter]) {
    _runner();
    return _controller.stream;
  }

  Future<void> _runner() async {
    // Start the delete process
    _controller.add(const BackupProgressData(
      step: BackupProgressStepCode.delete,
    ));

    // Check if the backup exists
    if (!(await _repository.isBackupExists())) {
      _controller.add(const BackupProgressData(
        step: BackupProgressStepCode.disabled,
      ));
      return;
    }

    // Request the deleting operation
    final bool result = await _repository.deleteFromCloud();

    // Send the result.
    _controller.add(BackupProgressData(
      step: result ? BackupProgressStepCode.done : BackupProgressStepCode.error,
    ));

    // Post-job
    _controller.close();
  }
}
