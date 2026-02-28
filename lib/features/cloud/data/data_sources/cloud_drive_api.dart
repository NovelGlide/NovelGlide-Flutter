import 'dart:typed_data';

import 'package:novel_glide/features/cloud/domain/entities/cloud_file.dart';
import 'package:novel_glide/features/cloud/domain/entities/drive_file_metadata.dart';

/// Abstract interface for cloud drive API operations.
///
/// Provides low-level operations for interacting with cloud storage
/// (Google Drive). Concrete implementations (like [GoogleDriveApi]) provide
/// the actual API integration.
abstract class CloudDriveApi {
  /// Retrieves a file from cloud storage by its file name.
  Future<CloudFile?> getFile(String fileName);

  /// Uploads a file to cloud storage at the root level.
  Future<void> uploadFile(
    String path, {
    void Function(double progress)? onUpload,
  });

  /// Deletes a file from cloud storage by its ID.
  Future<void> deleteFile(String fileId);

  /// Downloads a file from cloud storage as a stream of bytes.
  Stream<Uint8List> downloadFile(
    CloudFile cloudFile, {
    void Function(double progress)? onDownload,
  });

  /// Uploads a file to a specific folder path.
  ///
  /// Creates the folder structure if it doesn't exist.
  /// Returns the file ID of the uploaded file.
  Future<String> uploadFileToPath(
    dynamic file,
    String folderPath, {
    void Function(double progress)? onUpload,
  });

  /// Lists all files and folders within a specific folder path.
  ///
  /// Returns metadata for each item in the folder.
  Future<List<DriveFileMetadata>> listFolderContents(
    String folderPath,
  );

  /// Deletes an entire folder and all its contents recursively.
  Future<void> deleteFolder(String folderPath);
}
