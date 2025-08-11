import 'dart:async';

import '../../../../core/file_system/domain/repositories/file_system_repository.dart';
import '../../../../core/file_system/domain/repositories/json_repository.dart';
import '../../../../core/file_system/domain/repositories/temp_repository.dart';
import '../../../../core/domain/use_cases/use_case.dart';
import '../../../bookmark/domain/entities/bookmark_data.dart';
import '../../../bookmark/domain/repositories/bookmark_repository.dart';
import '../entities/backup_progress_data.dart';
import '../entities/backup_progress_step_code.dart';
import '../repositories/bookmark_backup_repository.dart';

class BackupBookmarkRestoreUseCase
    extends UseCase<Stream<BackupProgressData>, void> {
  BackupBookmarkRestoreUseCase(
    this._repository,
    this._fileSystemRepository,
    this._jsonRepository,
    this._tempRepository,
    this._bookmarkRepository,
  );

  final BookmarkBackupRepository _repository;
  final FileSystemRepository _fileSystemRepository;
  final TempRepository _tempRepository;
  final JsonRepository _jsonRepository;
  final BookmarkRepository _bookmarkRepository;

  final StreamController<BackupProgressData> _controller =
      StreamController<BackupProgressData>();

  @override
  Stream<BackupProgressData> call([void parameter]) {
    _runner();
    return _controller.stream;
  }

  Future<void> _runner() async {
    // Check if the backup exists
    if (!(await _repository.isBackupExists())) {
      _controller.add(const BackupProgressData(
        step: BackupProgressStepCode.disabled,
      ));
      return;
    }

    // Get a temporary work directory
    final String tempDirectoryPath = await _tempRepository.getDirectoryPath();

    // Start the download process
    _controller.add(const BackupProgressData(
      step: BackupProgressStepCode.download,
    ));

    // Download the file
    final String? jsonFilePath = await _repository.downloadFromCloud(
      tempDirectoryPath,
      (int downloaded, int total) {
        _controller.add(BackupProgressData(
          step: BackupProgressStepCode.download,
          progress: (downloaded / total).clamp(0, 1),
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

      final Set<BookmarkData> importSet = <BookmarkData>{};

      for (final dynamic value in data.values) {
        if (value is Map<String, dynamic>) {
          // Try to parse as a bookmark data
          try {
            final BookmarkData bookmarkData = BookmarkData(
              bookIdentifier: value['bookIdentifier'],
              bookName: value['bookName'],
              chapterTitle: value['chapterTitle'],
              chapterIdentifier: value['chapterIdentifier'],
              startCfi: value['startCfi'],
              savedTime: DateTime.parse(value['savedTime']),
            );
            importSet.add(bookmarkData);
          } catch (_) {
            // Failed to parse as a bookmark data.
            // Let it go~
          }
        }
      }

      // Clear all bookmarks
      await _bookmarkRepository.reset();

      // Import the data.
      await _bookmarkRepository.updateData(importSet);

      _controller.add(const BackupProgressData(
        step: BackupProgressStepCode.done,
      ));
    }

    // Post-job
    _fileSystemRepository.deleteDirectory(tempDirectoryPath);
    _controller.close();
  }
}
