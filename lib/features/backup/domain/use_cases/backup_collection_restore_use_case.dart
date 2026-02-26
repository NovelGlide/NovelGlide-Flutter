import 'dart:async';

import '../../../../core/domain/use_cases/use_case.dart';
import '../../../../core/file_system/domain/repositories/file_system_repository.dart';
import '../../../../core/file_system/domain/repositories/json_repository.dart';
import '../../../../core/file_system/domain/repositories/temp_repository.dart';
import '../../../collection/domain/entities/collection_data.dart';
import '../../../collection/domain/repositories/collection_repository.dart';
import '../entities/backup_progress_data.dart';
import '../entities/backup_progress_step_code.dart';
import '../repositories/collection_backup_repository.dart';

class BackupCollectionRestoreUseCase
    extends UseCase<Stream<BackupProgressData>, void> {
  BackupCollectionRestoreUseCase(
    this._repository,
    this._fileSystemRepository,
    this._jsonRepository,
    this._tempRepository,
    this._collectionRepository,
  );

  final CollectionBackupRepository _repository;
  final FileSystemRepository _fileSystemRepository;
  final TempRepository _tempRepository;
  final JsonRepository _jsonRepository;
  final CollectionRepository _collectionRepository;

  final StreamController<BackupProgressData> _controller =
      StreamController<BackupProgressData>();

  @override
  Stream<BackupProgressData> call([void parameter]) {
    _runner();
    return _controller.stream;
  }

  Future<void> _runner() async {
    // Start the download process
    _controller
        .add(const BackupProgressData(step: BackupProgressStepCode.download));

    // Check if the backup exists
    if (!(await _repository.isBackupExists())) {
      _controller.add(const BackupProgressData(
        step: BackupProgressStepCode.disabled,
      ));
      return;
    }

    // Get a temporary work directory
    final String tempDirectoryPath = await _tempRepository.getDirectoryPath();

    // Download the file
    final String? jsonFilePath = await _repository.downloadFromCloud(
      tempDirectoryPath,
      (double progress) {
        _controller.add(BackupProgressData(
          step: BackupProgressStepCode.download,
          progress: progress,
        ));
      },
    );

    if (jsonFilePath == null) {
      // Download the file failed.
      _controller.add(const BackupProgressData(
        step: BackupProgressStepCode.error,
      ));
    } else {
      // Read the json file
      final Map<String, dynamic> data =
          await _jsonRepository.readJson(path: jsonFilePath);

      final Set<CollectionData> importSet = <CollectionData>{};

      for (final dynamic value in data.values) {
        if (value is Map<String, dynamic>) {
          // Try to parse as a collection data
          try {
            final CollectionData data = CollectionData(
              id: value['id'],
              name: value['name'],
              pathList: List<String>.from(value['pathList']),
            );
            importSet.add(data);
          } catch (_) {
            // Failed to parse as a collection data.
            // Let it go~
          }
        }
      }

      // Clear all collections
      await _collectionRepository.reset();

      // Import the data.
      await _collectionRepository.updateData(importSet);

      _controller.add(const BackupProgressData(
        step: BackupProgressStepCode.done,
      ));
    }

    // Post-job
    _fileSystemRepository.deleteDirectory(tempDirectoryPath);
    _controller.close();
  }
}
