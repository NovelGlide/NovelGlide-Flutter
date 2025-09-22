import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_archive/flutter_archive.dart';
import 'package:path/path.dart';

import '../../../../core/file_system/domain/repositories/file_system_repository.dart';
import '../../../../core/log_system/log_system.dart';
import '../../../../core/path_provider/domain/repositories/app_path_provider.dart';
import '../../../books/domain/repositories/book_repository.dart';
import '../../../cloud/domain/entities/cloud_file.dart';
import '../../../cloud/domain/entities/cloud_providers.dart';
import '../../../cloud/domain/repositories/cloud_repository.dart';
import '../../domain/repositories/book_backup_repository.dart';

class BookBackupRepositoryImpl implements BookBackupRepository {
  BookBackupRepositoryImpl(
    this._pathProvider,
    this._fileSystemRepository,
    this._bookRepository,
    this._cloudRepository,
  );

  final AppPathProvider _pathProvider;
  final FileSystemRepository _fileSystemRepository;
  final BookRepository _bookRepository;
  final CloudRepository _cloudRepository;

  final CloudProviders _cloudProvider = CloudProviders.google;

  Future<CloudFile?> get _file async =>
      await _cloudRepository.getFile(_cloudProvider, await archiveName);

  @override
  Future<String> get archiveName async => 'Library.zip';

  @override
  Future<DateTime?> get lastBackupTime async {
    final CloudFile? file = await _file;
    return file?.modifiedTime;
  }

  @override
  Future<String> archive(
    String tempDirectoryPath,
    void Function(double progress)? onZipping,
  ) async {
    final String libraryFolder = await _pathProvider.libraryPath;

    // Create the zip file
    final String path = join(tempDirectoryPath, await archiveName);

    // Start archiving books
    await ZipFile.createFromDirectory(
      sourceDir: Directory(libraryFolder),
      zipFile: File(path),
      onZipping: (String fileName, bool isDirectory, double progress) {
        // Call callback for sending the progress.
        onZipping?.call((progress / 100).clamp(0, 1));

        // Only check the extension is acceptable.
        final String ext = extension(fileName);
        return _bookRepository.allowedExtensions.contains(ext.substring(1))
            ? ZipFileOperation.includeItem
            : ZipFileOperation.skipItem;
      },
    );

    return path;
  }

  @override
  Future<bool> deleteFromCloud() async {
    final CloudFile? file = await _file;

    if (file == null) {
      LogSystem.error(
        'Delete library zip from cloud failed '
        'because the file does not exist.',
      );
      return false;
    }

    // Delete the file from Google Drive.
    await _cloudRepository.deleteFile(_cloudProvider, file.identifier);

    // Success if it doesn't exist.
    return !(await isBackupExists());
  }

  @override
  Future<String?> downloadFromCloud(
    String tempDirectoryPath,
    void Function(double progress)? onDownload,
  ) async {
    final CloudFile? file = await _file;

    if (file == null) {
      LogSystem.error(
        'Download library zip from cloud failed '
        'because the file does not exist.',
      );
      return null;
    }

    // Create an empty file to store the downloaded zip file.
    final String zipFilePath = join(tempDirectoryPath, await archiveName);
    await _fileSystemRepository.createFile(zipFilePath);

    try {
      // Create the stream of the file.
      final Stream<Uint8List> cloudFileStream = _cloudRepository.downloadFile(
        _cloudProvider,
        file,
        onDownload: onDownload,
      );

      // Create the buffer to store the downloaded data.
      final Uint8List buffer = Uint8List(file.length);

      // Read the data from the stream and write it to the buffer.
      int offset = 0;
      await for (Uint8List chunk in cloudFileStream) {
        buffer.setAll(offset, chunk);
        offset += chunk.length;
      }

      // Write the buffer to the file.
      await _fileSystemRepository.writeFileAsBytes(zipFilePath, buffer);
    } catch (e, s) {
      // An error occurred.
      LogSystem.error(
        'An error occurred while downloading and '
        'processing the book backup file from cloud',
        error: e,
        stackTrace: s,
      );
      return null;
    }

    return zipFilePath;
  }

  @override
  Future<void> extract(
    String zipFilePath,
    String tempDirectoryPath,
    void Function(double progress)? onExtracting,
  ) async {
    // Extract files to temporary directory.
    await ZipFile.extractToDirectory(
      zipFile: File(zipFilePath),
      destinationDir: Directory(tempDirectoryPath),
      onExtracting: (ZipEntry entry, double progress) {
        // Only extract epub files.
        onExtracting?.call(progress / 100);

        // Determine if the file should be extracted or not.
        return !entry.isDirectory && extension(entry.name) == '.epub'
            ? ZipFileOperation.includeItem
            : ZipFileOperation.skipItem;
      },
    );

    final Set<String> importSet = <String>{};

    // Get all paths of every book.
    await for (FileSystemEntity entity
        in _fileSystemRepository.listDirectory(tempDirectoryPath)) {
      // Only import the valid files.
      if (entity is File && await _bookRepository.isFileValid(entity.path)) {
        importSet.add(entity.path);
      }
    }

    // Delete all books in the library
    await _bookRepository.reset();

    // Perform add book procedures
    await _bookRepository.addBooks(importSet);
  }

  @override
  Future<bool> isBackupExists() async => await _file != null;

  @override
  Future<bool> uploadToCloud(
    String zipFilePath,
    void Function(double progress)? onUpload,
  ) async {
    try {
      await _cloudRepository.uploadFile(
        _cloudProvider,
        zipFilePath,
        onUpload: onUpload,
      );
    } catch (e, s) {
      // An error occurred.
      LogSystem.error(
        'Upload library zip to cloud failed.',
        error: e,
        stackTrace: s,
      );
      return false;
    }

    return isBackupExists();
  }
}
