import 'dart:typed_data';

import '../../../../main.dart';
import '../../domain/entities/cloud_file.dart';
import '../../domain/entities/cloud_providers.dart';
import '../../domain/entities/drive_file_metadata.dart';
import '../../domain/repositories/cloud_repository.dart';
import '../data_sources/cloud_drive_api.dart';

class CloudRepositoryImpl implements CloudRepository {
  @override
  Future<void> deleteFile(CloudProviders providers, String fileId) {
    final CloudDriveApi cloudDriveApi = sl<CloudDriveApi>(param1: providers);
    return cloudDriveApi.deleteFile(fileId);
  }

  @override
  Stream<Uint8List> downloadFile(
    CloudProviders providers,
    CloudFile cloudFile, {
    void Function(double progress)? onDownload,
  }) {
    final CloudDriveApi cloudDriveApi = sl<CloudDriveApi>(param1: providers);
    return cloudDriveApi.downloadFile(cloudFile, onDownload: onDownload);
  }

  @override
  Future<CloudFile?> getFile(CloudProviders providers, String fileName) {
    final CloudDriveApi cloudDriveApi = sl<CloudDriveApi>(param1: providers);
    return cloudDriveApi.getFile(fileName);
  }

  @override
  Future<void> uploadFile(
    CloudProviders providers,
    String path, {
    void Function(double progress)? onUpload,
  }) {
    final CloudDriveApi cloudDriveApi = sl<CloudDriveApi>(param1: providers);
    return cloudDriveApi.uploadFile(path, onUpload: onUpload);
  }

  @override
  Future<String> uploadFileToPath(
    CloudProviders providers,
    dynamic file,
    String folderPath, {
    void Function(double progress)? onUpload,
  }) {
    final CloudDriveApi cloudDriveApi = sl<CloudDriveApi>(param1: providers);
    return cloudDriveApi.uploadFileToPath(file, folderPath, onUpload: onUpload);
  }

  @override
  Future<List<DriveFileMetadata>> listFolderContents(
    CloudProviders providers,
    String folderPath,
  ) {
    final CloudDriveApi cloudDriveApi = sl<CloudDriveApi>(param1: providers);
    return cloudDriveApi.listFolderContents(folderPath);
  }

  @override
  Future<void> deleteFolder(
    CloudProviders providers,
    String folderPath,
  ) {
    final CloudDriveApi cloudDriveApi = sl<CloudDriveApi>(param1: providers);
    return cloudDriveApi.deleteFolder(folderPath);
  }
}
