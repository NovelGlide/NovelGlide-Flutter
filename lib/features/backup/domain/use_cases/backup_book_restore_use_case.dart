import 'dart:async';

import '../../../../core/domain/use_cases/use_case.dart';
import '../../../../core/file_system/domain/repositories/file_system_repository.dart';
import '../../../../core/file_system/domain/repositories/temp_repository.dart';
import '../../../../core/log_system/log_system.dart';
import '../entities/backup_progress_data.dart';
import '../entities/backup_progress_step_code.dart';
import '../repositories/book_backup_repository.dart';

class BackupBookRestoreUseCase
    extends UseCase<Stream<BackupProgressData>, void> {
  BackupBookRestoreUseCase(
    this._fileSystemRepository,
    this._tempRepository,
    this._bookBackupRepository,
  );

  final FileSystemRepository _fileSystemRepository;
  final TempRepository _tempRepository;
  final BookBackupRepository _bookBackupRepository;

  final StreamController<BackupProgressData> _controller =
      StreamController<BackupProgressData>();

  @override
  Stream<BackupProgressData> call([void parameter]) {
    _runner();
    return _controller.stream;
  }

  Future<void> _runner() async {
    // Emit download step
    _controller
        .add(const BackupProgressData(step: BackupProgressStepCode.download));

    // Check if the file exists
    if (!await _bookBackupRepository.isBackupExists()) {
      // File is not exists.
      _controller
          .add(const BackupProgressData(step: BackupProgressStepCode.disabled));
      return;
    }

    // Get and create a temporary directory for download and extraction
    final String tempDirectoryPath = await _tempRepository.getDirectoryPath();
    await _fileSystemRepository.createDirectory(tempDirectoryPath);

    try {
      // Download the backup file from the cloud
      final String? zipFilePath = await _bookBackupRepository.downloadFromCloud(
        tempDirectoryPath,
        (double progress) {
          _controller.add(BackupProgressData(
            step: BackupProgressStepCode.download,
            progress: progress,
          ));
        },
      );

      if (zipFilePath == null) {
        throw Exception('BackupBookRestoreUseCase: Download failed.');
      }

      // Emit unzip step
      _controller
          .add(const BackupProgressData(step: BackupProgressStepCode.unzip));

      // Extract the downloaded zip file
      await _bookBackupRepository.extract(
        zipFilePath,
        tempDirectoryPath,
        (double progress) {
          _controller.add(BackupProgressData(
            step: BackupProgressStepCode.unzip,
            progress: progress,
          ));
        },
      );

      // Emit completion step
      _controller
          .add(const BackupProgressData(step: BackupProgressStepCode.done));
    } catch (e, s) {
      // Emit error step if any exception occurs
      _controller
          .add(const BackupProgressData(step: BackupProgressStepCode.error));

      // Optionally log stack trace s
      LogSystem.error('Backup book restore failed', error: e, stackTrace: s);
    } finally {
      // Clean up the temporary directory
      await _fileSystemRepository.deleteDirectory(tempDirectoryPath);

      // Close the stream controller
      _controller.close();
    }
  }
}
