import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;

import '../../domain/repositories/file_system_repository.dart';

class FileSystemRepositoryImpl implements FileSystemRepository {
  Future<void> _createParentDirectory(String path) async {
    final Directory parentDir = Directory(p.dirname(path));
    if (!await parentDir.exists()) {
      await parentDir.create(recursive: true);
    }
  }

  @override
  Future<Directory> createDirectory(String path) async {
    final Directory directory = Directory(path);
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    return directory;
  }

  @override
  Future<File> createFile(String path) async {
    final File file = File(path);
    await _createParentDirectory(path);
    if (!await file.exists()) {
      await file.create();
    }
    return file;
  }

  @override
  Future<void> copyFile(String sourcePath, String destinationPath) async {
    await File(sourcePath).copy(destinationPath);
  }

  @override
  Future<bool> existsDirectory(String path) async {
    final Directory directory = Directory(path);
    return directory.exists();
  }

  @override
  Future<bool> existsFile(String path) async {
    final File file = File(path);
    return file.exists();
  }

  @override
  Future<void> writeFileAsBytes(String path, Uint8List bytes) async {
    final File file = await createFile(path);
    await file.writeAsBytes(bytes);
  }

  @override
  Future<Uint8List> readFileAsBytes(String path, {int? start, int? end}) async {
    List<int> bytes = <int>[];

    final File entry = File(path);
    if (await entry.exists()) {
      final RandomAccessFile file = await entry.open(mode: FileMode.read);

      if (start != null && end != null && start <= end) {
        bytes = List<int>.filled(end - start + 1, 0);
        await file.readInto(bytes, start, end);
      } else {
        bytes = await entry.readAsBytes();
      }

      await file.close();
    }

    return Uint8List.fromList(bytes);
  }

  @override
  Stream<Uint8List> streamFileAsBytes(
    String path, {
    int? start,
    int? end,
  }) async* {
    final File entry = File(path);
    yield* entry.openRead(start, end).transform(
      StreamTransformer<List<int>, Uint8List>.fromHandlers(
        handleData: (List<int> chunk, EventSink<Uint8List> sink) {
          // Convert the List<int> chunk to Uint8List
          final Uint8List uint8ListChunk = Uint8List.fromList(chunk);

          // Add the converted chunk to the output stream
          sink.add(uint8ListChunk);
        },
      ),
    );
  }

  @override
  Future<void> writeFileAsString(String path, String content) async {
    final File file = await createFile(path);
    await file.writeAsString(content);
  }

  @override
  Future<String> readFileAsString(String path) async {
    final File file = File(path);
    if (!await file.exists()) {
      throw FileSystemException('File not found', path);
    }
    return file.readAsString();
  }

  @override
  Future<void> deleteFile(String path) async {
    final File file = File(path);
    if (await file.exists()) {
      await file.delete();
    }
  }

  @override
  Future<void> deleteDirectory(String path) async {
    final Directory directory = Directory(path);
    if (await directory.exists()) {
      await directory.delete(recursive: true);
    }
  }

  @override
  Stream<FileSystemEntity> listDirectory(String path) async* {
    final Directory directory = Directory(path);
    if (!await directory.exists()) {
      throw FileSystemException('Directory not found', path);
    }

    yield* directory.list();
  }

  @override
  Future<int> getFileSize(String path) async {
    final File file = File(path);
    if (!await file.exists()) {
      throw FileSystemException('File not found', path);
    }
    return file.length();
  }

  @override
  Future<DateTime> getModifiedDate(String path) async {
    final File file = File(path);
    if (!await file.exists()) {
      throw FileSystemException('File not found', path);
    }
    return file.lastModified();
  }
}
