import 'dart:async';

import '../../../../core/domain/use_cases/use_case.dart';
import '../entities/downloader_task.dart';
import '../repositories/downloader_repository.dart';

class DownloaderDownloadFileUseCaseParam {
  DownloaderDownloadFileUseCaseParam({
    required this.uri,
    required this.name,
    required this.onSuccess,
    this.onError,
  });

  final Uri uri;
  final String name;
  final Future<void> Function(DownloaderTask) onSuccess;
  final Future<void> Function()? onError;
}

class DownloaderDownloadFileUseCase
    extends UseCase<Future<void>, DownloaderDownloadFileUseCaseParam> {
  DownloaderDownloadFileUseCase(this._repository);

  final DownloaderRepository _repository;

  @override
  Future<void> call(DownloaderDownloadFileUseCaseParam parameter) async {
    final String identifier = await _repository.downloadFile(
      uri: parameter.uri,
      name: parameter.name,
    );
    final DownloaderTask? task =
        await _repository.getTaskByIdentifier(identifier);

    if (task != null) {
      // File downloading.
      await task.onDownloadStream.drain();
      // File downloaded.
      await parameter.onSuccess(task);
    } else {
      await parameter.onError?.call();
    }
  }
}
