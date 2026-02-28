import 'dart:async';
import 'dart:typed_data';

import 'package:googleapis/drive/v3.dart';
import 'package:path/path.dart' as p;

import 'package:novel_glide/core/file_system/domain/repositories/file_system_repository.dart';
import 'package:novel_glide/core/log_system/log_system.dart';
import 'package:novel_glide/core/mime_resolver/domain/repositories/mime_repository.dart';
import 'package:novel_glide/features/auth/domain/entities/auth_providers.dart';
import 'package:novel_glide/features/auth/domain/repositories/auth_repository.dart';
import 'package:novel_glide/features/cloud/domain/entities/cloud_file.dart';
import 'package:novel_glide/features/cloud/domain/entities/drive_file_metadata.dart';
import 'package:novel_glide/features/cloud/data/data_sources/cloud_drive_api.dart';

/// Concrete implementation of [CloudDriveApi] using Google Drive API.
///
/// Handles all interactions with Google Drive, including file upload/download,
/// folder management, and metadata operations.
class GoogleDriveApi implements CloudDriveApi {
  /// Creates a [GoogleDriveApi] instance.
  ///
  /// Requires [AuthRepository] for authentication, [FileSystemRepository]
  /// for local file operations, and [MimeRepository] for MIME type resolution.
  GoogleDriveApi(
    this._authRepository,
    this._fileSystemRepository,
    this._mimeRepository,
  );

  final AuthRepository _authRepository;
  final FileSystemRepository _fileSystemRepository;
  final MimeRepository _mimeRepository;

  final String _appDataFolder = 'appDataFolder';
  final String _folderMimeType = 'application/vnd.google-apps.folder';

  /// Get the authenticated Google Drive API instance.
  Future<DriveApi> get _driveApi async {
    return DriveApi(
      await _authRepository.getClient(
        AuthProviders.google,
        <String>[
          DriveApi.driveAppdataScope,
          DriveApi.driveFileScope,
        ],
      ),
    );
  }

  /// Get the files resource for making Drive API calls.
  Future<FilesResource> get _files async => (await _driveApi).files;

  @override
  Future<void> deleteFile(String fileId) async {
    return (await _files).delete(fileId);
  }

  @override
  Stream<Uint8List> downloadFile(
    CloudFile cloudFile, {
    void Function(double progress)? onDownload,
  }) {
    final StreamController<Uint8List> streamController =
        StreamController<Uint8List>();
    _downloadFileRunner(cloudFile, onDownload, streamController);
    return streamController.stream;
  }

  /// Internal runner for downloading a file and emitting progress.
  Future<void> _downloadFileRunner(
    CloudFile cloudFile,
    void Function(double progress)? onDownload,
    StreamController<Uint8List> streamController,
  ) async {
    final int fileSize = cloudFile.length;
    final Media media = await (await _files).get(
      cloudFile.identifier,
      downloadOptions: DownloadOptions.fullMedia,
    ) as Media;
    int transferredByteCount = 0;

    media.stream.listen(
      (List<int> data) {
        streamController.add(Uint8List.fromList(data));
        transferredByteCount += data.length;
        onDownload?.call((transferredByteCount / fileSize).clamp(0, 1));
      },
      onDone: () {
        streamController.close();
        onDownload?.call(1);
      },
      onError: (Object e) {
        LogSystem.error(
          'An error occurred while downloading a file from Google Drive',
          error: e,
        );
        streamController.close();
      },
    );
  }

  @override
  Future<CloudFile?> getFile(String fileName) async {
    final String? fileId = await _getFileId(fileName);

    if (fileId == null) {
      return null;
    } else {
      final File metadata = await (await _files).get(
        fileId,
        $fields: 'id, name, mimeType, createdTime, modifiedTime, size',
      ) as File;
      return CloudFile(
        identifier: metadata.id ?? fileId,
        name: metadata.name ?? '',
        length: int.tryParse(metadata.size ?? '0') ?? 0,
        modifiedTime: metadata.modifiedTime!,
      );
    }
  }

  @override
  Future<void> uploadFile(
    String path, {
    void Function(double progress)? onUpload,
  }) async {
    final String? fileId = await _getFileId(p.basename(path));

    int byteCount = 0;
    final int fileLength = await _fileSystemRepository.getFileSize(path);
    final Stream<List<int>> stream =
        _fileSystemRepository.streamFileAsBytes(path).transform(
              StreamTransformer<Uint8List, List<int>>.fromHandlers(
                handleData: (
                  List<int> data,
                  EventSink<List<int>> sink,
                ) {
                  byteCount += data.length;
                  onUpload?.call((byteCount / fileLength).clamp(0, 1));
                  sink.add(data);
                },
                handleError: (
                  Object e,
                  StackTrace s,
                  EventSink<List<int>> sink,
                ) {
                  LogSystem.error(
                    'An error occurred while uploading a file to '
                    'Google Drive.',
                    error: e,
                    stackTrace: s,
                  );
                  sink.close();
                },
                handleDone: (EventSink<List<int>> sink) {
                  sink.close();
                },
              ),
            );

    final File metadata = File();
    metadata.name = p.basename(path);
    metadata.mimeType =
        (await _mimeRepository.lookupAll(path))?.tagList.firstOrNull;

    final Media media = Media(stream, fileLength);

    if (fileId == null) {
      metadata.parents = <String>[_appDataFolder];
      await (await _files).create(metadata, uploadMedia: media);
    } else {
      await (await _files).update(metadata, fileId, uploadMedia: media);
    }
  }

  @override
  Future<String> uploadFileToPath(
    dynamic file,
    String folderPath, {
    void Function(double progress)? onUpload,
  }) async {
    try {
      final String folderId = await _getOrCreateFolderPath(folderPath);
      final String filePath = file.toString();
      final String fileName = p.basename(filePath);

      int byteCount = 0;
      final int fileLength = await _fileSystemRepository.getFileSize(filePath);
      final Stream<List<int>> stream =
          _fileSystemRepository.streamFileAsBytes(filePath).transform(
                StreamTransformer<Uint8List, List<int>>.fromHandlers(
                  handleData: (
                    List<int> data,
                    EventSink<List<int>> sink,
                  ) {
                    byteCount += data.length;
                    onUpload?.call((byteCount / fileLength).clamp(0, 1));
                    sink.add(data);
                  },
                  handleError: (
                    Object e,
                    StackTrace s,
                    EventSink<List<int>> sink,
                  ) {
                    LogSystem.error(
                      'An error occurred while uploading a file to '
                      'Google Drive.',
                      error: e,
                      stackTrace: s,
                    );
                    sink.close();
                  },
                  handleDone: (EventSink<List<int>> sink) {
                    sink.close();
                  },
                ),
              );

      final File metadata = File();
      metadata.name = fileName;
      metadata.mimeType =
          (await _mimeRepository.lookupAll(filePath))?.tagList.firstOrNull;
      metadata.parents = <String>[folderId];

      final Media media = Media(stream, fileLength);
      final File createdFile =
          await (await _files).create(metadata, uploadMedia: media);

      return createdFile.id ?? '';
    } catch (e) {
      LogSystem.error(
        'An error occurred while uploading a file to a path in '
        'Google Drive.',
        error: e,
      );
      rethrow;
    }
  }

  @override
  Future<List<DriveFileMetadata>> listFolderContents(
    String folderPath,
  ) async {
    try {
      final String? folderId = await _getFolderIdByPath(folderPath);

      if (folderId == null) {
        LogSystem.error('Folder not found: $folderPath');
        throw Exception('Folder not found: $folderPath');
      }

      final FileList fileList = await (await _files).list(
        q: "'$folderId' in parents",
        spaces: _appDataFolder,
        $fields: 'files(id, name, mimeType, modifiedTime)',
      );

      final List<DriveFileMetadata> metadata = <DriveFileMetadata>[];

      if (fileList.files != null) {
        for (final File file in fileList.files!) {
          metadata.add(
            DriveFileMetadata(
              fileId: file.id ?? '',
              name: file.name ?? '',
              mimeType: file.mimeType ?? '',
              modifiedTime: file.modifiedTime ?? DateTime.now(),
            ),
          );
        }
      }

      return metadata;
    } catch (e) {
      LogSystem.error(
        'An error occurred while listing folder contents: $folderPath',
        error: e,
      );
      rethrow;
    }
  }

  @override
  Future<void> deleteFolder(String folderPath) async {
    try {
      final String? folderId = await _getFolderIdByPath(folderPath);

      if (folderId == null) {
        LogSystem.error('Folder not found: $folderPath');
        throw Exception('Folder not found: $folderPath');
      }

      await _deleteRecursive(folderId);
      await (await _files).delete(folderId);
    } catch (e) {
      LogSystem.error(
        'An error occurred while deleting folder: $folderPath',
        error: e,
      );
      rethrow;
    }
  }

  /// Get or create a folder at the specified path.
  ///
  /// If any folder in the path doesn't exist, it will be created.
  /// Path format: "folder1/folder2/folder3" uses "/" as separator.
  /// Root is appDataFolder.
  ///
  /// Returns: The folder ID of the final folder in the path.
  Future<String> _getOrCreateFolderPath(String folderPath) async {
    if (folderPath.isEmpty) {
      return _appDataFolder;
    }

    final List<String> pathParts = folderPath.split('/');
    String currentParentId = _appDataFolder;

    for (final String folderName in pathParts) {
      if (folderName.isEmpty) {
        continue;
      }

      final String? existingFolderId =
          await _getFolderIdByName(folderName, currentParentId);

      if (existingFolderId != null) {
        currentParentId = existingFolderId;
      } else {
        final File folderMetadata = File();
        folderMetadata.name = folderName;
        folderMetadata.mimeType = _folderMimeType;
        folderMetadata.parents = <String>[currentParentId];

        final File createdFolder = await (await _files).create(folderMetadata);
        currentParentId = createdFolder.id ?? '';
      }
    }

    return currentParentId;
  }

  /// Get folder ID by path without creating.
  ///
  /// Returns null if any folder in the path doesn't exist.
  /// Path format: "folder1/folder2/folder3" uses "/" as separator.
  /// Root is appDataFolder.
  Future<String?> _getFolderIdByPath(String folderPath) async {
    if (folderPath.isEmpty) {
      return _appDataFolder;
    }

    final List<String> pathParts = folderPath.split('/');
    String currentParentId = _appDataFolder;

    for (final String folderName in pathParts) {
      if (folderName.isEmpty) {
        continue;
      }

      final String? folderId =
          await _getFolderIdByName(folderName, currentParentId);

      if (folderId == null) {
        return null;
      }

      currentParentId = folderId;
    }

    return currentParentId;
  }

  /// Get folder ID by name within a specific parent folder.
  ///
  /// Returns null if the folder doesn't exist.
  Future<String?> _getFolderIdByName(
    String folderName,
    String parentId,
  ) async {
    try {
      final FileList fileList = await (await _files).list(
        spaces: _appDataFolder,
        q: "'$parentId' in parents and name = '$folderName' and "
            'mimeType = \'$_folderMimeType\'',
        pageSize: 1,
      );

      return fileList.files?.isNotEmpty == true
          ? fileList.files?.first.id
          : null;
    } catch (e) {
      LogSystem.error(
        'An error occurred while getting folder ID by name: $folderName',
        error: e,
      );
      return null;
    }
  }

  /// Recursively delete all files and folders within a parent folder.
  Future<void> _deleteRecursive(String parentId) async {
    try {
      final FileList fileList = await (await _files).list(
        q: "'$parentId' in parents",
        spaces: _appDataFolder,
        $fields: 'files(id, mimeType)',
      );

      if (fileList.files != null) {
        for (final File file in fileList.files!) {
          if (file.mimeType == _folderMimeType) {
            await _deleteRecursive(file.id ?? '');
          }

          await (await _files).delete(file.id ?? '');
        }
      }
    } catch (e) {
      LogSystem.error(
        'An error occurred while recursively deleting folder contents.',
        error: e,
      );
      rethrow;
    }
  }

  /// Get file ID by name in the app data folder.
  ///
  /// Returns null if the file doesn't exist.
  Future<String?> _getFileId(String fileName) async {
    final FileList fileList = await (await _files).list(
      spaces: _appDataFolder,
      q: "name = '$fileName'",
      pageSize: 1,
    );

    return fileList.files?.isNotEmpty == true ? fileList.files?.first.id : null;
  }
}
