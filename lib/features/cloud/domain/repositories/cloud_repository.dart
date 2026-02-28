import 'dart:typed_data';

import '../entities/cloud_file.dart';
import '../entities/cloud_providers.dart';
import '../entities/drive_file_metadata.dart';

abstract class CloudRepository {
  /// Retrieves a file from cloud storage by its file name.
  ///
  /// Parameters:
  ///   - [providers]: The cloud provider to use for this operation.
  ///   - [fileName]: The name of the file to retrieve.
  ///
  /// Returns: The [CloudFile] metadata if found, null otherwise.
  Future<CloudFile?> getFile(CloudProviders providers, String fileName);

  /// Uploads a file to cloud storage.
  ///
  /// Parameters:
  ///   - [providers]: The cloud provider to use for this operation.
  ///   - [path]: The local file path to upload.
  ///   - [onUpload]: Optional callback to track upload progress (0.0 to 1.0).
  Future<void> uploadFile(
    CloudProviders providers,
    String path, {
    void Function(double progress)? onUpload,
  });

  /// Deletes a file from cloud storage.
  ///
  /// Parameters:
  ///   - [providers]: The cloud provider to use for this operation.
  ///   - [fileId]: The unique identifier of the file to delete.
  Future<void> deleteFile(CloudProviders providers, String fileId);

  /// Downloads a file from cloud storage as a stream of bytes.
  ///
  /// Parameters:
  ///   - [providers]: The cloud provider to use for this operation.
  ///   - [cloudFile]: The [CloudFile] metadata of the file to download.
  ///   - [onDownload]: Optional callback to track download progress (0.0 to 1.0).
  ///
  /// Returns: A stream of byte chunks from the downloaded file.
  Stream<Uint8List> downloadFile(
    CloudProviders providers,
    CloudFile cloudFile, {
    void Function(double progress)? onDownload,
  });

  /// Uploads a file to a specific folder path in cloud storage.
  ///
  /// Creates the folder structure if it doesn't exist. The root folder is
  /// 'appDataFolder' on Google Drive, so paths are relative to that.
  ///
  /// Parameters:
  ///   - [providers]: The cloud provider to use for this operation.
  ///   - [file]: The local file (dart:io File) to upload.
  ///   - [folderPath]: The destination folder path using "/" separator.
  ///     Example: "books/uuid123" creates structure: appDataFolder/books/uuid123/
  ///   - [onUpload]: Optional callback to track upload progress (0.0 to 1.0).
  ///
  /// Returns: The unique file ID of the uploaded file on Google Drive.
  ///
  /// Throws:
  ///   - Exception if the file cannot be read or upload fails.
  Future<String> uploadFileToPath(
    CloudProviders providers,
    dynamic file,
    String folderPath, {
    void Function(double progress)? onUpload,
  });

  /// Lists all files and folders within a specific folder path.
  ///
  /// Parameters:
  ///   - [providers]: The cloud provider to use for this operation.
  ///   - [folderPath]: The folder path to list, using "/" separator.
  ///     Example: "books/uuid123" lists contents of appDataFolder/books/uuid123/
  ///     Empty string lists immediate children of appDataFolder.
  ///
  /// Returns: A list of [DriveFileMetadata] for all items in the folder.
  ///
  /// Throws:
  ///   - Exception if the folder doesn't exist or access is denied.
  Future<List<DriveFileMetadata>> listFolderContents(
    CloudProviders providers,
    String folderPath,
  );

  /// Deletes an entire folder and all its contents recursively.
  ///
  /// Parameters:
  ///   - [providers]: The cloud provider to use for this operation.
  ///   - [folderPath]: The folder path to delete, using "/" separator.
  ///     Example: "books/uuid123" deletes appDataFolder/books/uuid123/ and everything in it.
  ///
  /// Throws:
  ///   - Exception if the folder doesn't exist or deletion fails.
  Future<void> deleteFolder(
    CloudProviders providers,
    String folderPath,
  );
}
