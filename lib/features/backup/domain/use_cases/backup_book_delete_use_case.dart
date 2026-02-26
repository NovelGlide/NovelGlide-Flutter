import 'dart:async';

import '../../../../core/domain/use_cases/use_case.dart';
import '../../../../core/log_system/log_system.dart';
import '../entities/backup_progress_data.dart';
import '../entities/backup_progress_step_code.dart';
import '../repositories/book_backup_repository.dart';

class BackupBookDeleteUseCase
    extends UseCase<Stream<BackupProgressData>, void> {
  BackupBookDeleteUseCase(this._bookBackupRepository);

  final BookBackupRepository _bookBackupRepository;

  final StreamController<BackupProgressData> _controller =
      StreamController<BackupProgressData>();

  @override
  Stream<BackupProgressData> call([void parameter]) {
    _runner();
    return _controller.stream;
  }

  Future<void> _runner() async {
    // Start deleting the backup file
    _controller
        .add(const BackupProgressData(step: BackupProgressStepCode.delete));

    // Check if backup exists
    final bool backupExists = await _bookBackupRepository.isBackupExists();
    if (!backupExists) {
      _controller
          .add(const BackupProgressData(step: BackupProgressStepCode.disabled));
      await _controller.close();
      return;
    }

    try {
      // Delete the backup file from cloud
      final bool isSuccessful = await _bookBackupRepository.deleteFromCloud();

      // Emit the result
      if (isSuccessful) {
        _controller
            .add(const BackupProgressData(step: BackupProgressStepCode.done));
      } else {
        _controller
            .add(const BackupProgressData(step: BackupProgressStepCode.error));
      }
    } catch (e, s) {
      _controller
          .add(const BackupProgressData(step: BackupProgressStepCode.error));
      // Optionally rethrow or log the error
      LogSystem.error('Backup book delete failed', error: e, stackTrace: s);
    } finally {
      await _controller.close();
    }
  }
}
