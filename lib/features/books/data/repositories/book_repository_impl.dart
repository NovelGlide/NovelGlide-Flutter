import 'dart:async';
import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:novel_glide/core/utils/random_extension.dart';
import 'package:path/path.dart';

import '../../../../core/file_system/domain/repositories/file_system_repository.dart';
import '../../../../core/mime_resolver/domain/entities/mime_type.dart';
import '../../../../core/mime_resolver/domain/repositories/mime_repository.dart';
import '../../../../core/path_provider/domain/repositories/app_path_provider.dart';
import '../../../../core/utils/file_utils.dart';
import '../../../pick_file/domain/repositories/pick_file_repository.dart';
import '../../domain/entities/book.dart';
import '../../domain/entities/book_chapter.dart';
import '../../domain/entities/book_cover.dart';
import '../../domain/entities/book_html_content.dart';
import '../../domain/entities/book_pick_file_data.dart';
import '../../domain/repositories/book_repository.dart';
import '../data_sources/epub_data_source.dart';

class BookRepositoryImpl implements BookRepository {
  BookRepositoryImpl(
    this._epubDataSource,
    this._pathProvider,
    this._fileSystemRepository,
    this._pickFileRepository,
    this._mimeRepository,
  );

  final EpubDataSource _epubDataSource;

  final AppPathProvider _pathProvider;
  final FileSystemRepository _fileSystemRepository;
  final PickFileRepository _pickFileRepository;
  final MimeRepository _mimeRepository;

  final StreamController<void> _onChangedController =
      StreamController<void>.broadcast();

  Future<String> _getAbsolutePathFromIdentifier(String identifier) async {
    final String libraryPath = await _pathProvider.libraryPath;
    return join(libraryPath, identifier);
  }

  List<MimeType> get allowedMimeType => _epubDataSource.allowedMimeTypes;

  @override
  List<String> get allowedExtensions => _epubDataSource.allowedExtensions;

  @override
  StreamController<void> get onChangedController => _onChangedController;

  @override
  Future<void> addBooks(Set<String> externalPathSet) async {
    for (String path in externalPathSet) {
      final MimeType? mimeType = await _mimeRepository.lookupAll(path);
      if (mimeType == null || !allowedMimeType.contains(mimeType)) {
        // The mime was not allowed.
        continue;
      }

      // Start moving files to the library.
      final String fileName = basenameWithoutExtension(path);
      String ext = extension(path);
      ext = ext.isEmpty ? '' : ext.substring(1);

      if (!allowedExtensions.contains(ext)) {
        // Invalid extension of this file. Change its extension.
        ext = mimeType.extensionList.first;
      }

      // Duplication check.
      String identifier = '$fileName.$ext';
      final Random random = Random();
      while (await exists(identifier)) {
        // Already exists. Skip. Give a random name.
        identifier = '${random.nextString(10)}.$ext';
      }

      final String destination =
          await _getAbsolutePathFromIdentifier(identifier);
      _fileSystemRepository.copyFile(path, destination);
    }

    // Send a notification
    onChangedController.add(null);
  }

  @override
  Future<bool> delete(Set<String> identifierSet) async {
    bool result = true;

    for (String identifier in identifierSet) {
      final String destination =
          await _getAbsolutePathFromIdentifier(identifier);
      if (await _fileSystemRepository.existsFile(destination)) {
        await _fileSystemRepository.deleteFile(destination);
      }

      result &= !await _fileSystemRepository.existsFile(destination);
    }

    // Send a notification.
    onChangedController.add(null);

    return result;
  }

  @override
  Future<bool> exists(String identifier) async {
    final String destination = await _getAbsolutePathFromIdentifier(identifier);
    return _fileSystemRepository.existsFile(destination);
  }

  @override
  Future<Book> getBook(String identifier) async {
    return await _epubDataSource
        .getBook(await _getAbsolutePathFromIdentifier(identifier));
  }

  @override
  Stream<Book> getBooks([Set<String>? identifierSet]) async* {
    final String libraryPath = await _pathProvider.libraryPath;

    if (identifierSet == null) {
      // List all books
      await for (FileSystemEntity entity
          in _fileSystemRepository.listDirectory(libraryPath)) {
        if (entity is File && await isFileValid(entity.path)) {
          yield await getBook(entity.path);
        }
      }
    } else {
      // List specific books
      for (String id in identifierSet) {
        yield await getBook(id);
      }
    }
  }

  @override
  Future<Set<BookPickFileData>> pickBooks() async {
    final Set<String> pickedFileSet = await _pickFileRepository.pickFiles(
      allowedExtensions: allowedExtensions,
    );
    final Set<BookPickFileData> dataSet = <BookPickFileData>{};

    for (String absolutePath in pickedFileSet) {
      final String baseName = basename(absolutePath);
      dataSet.add(BookPickFileData(
        absolutePath: absolutePath,
        baseName: baseName,
        fileSize: parseFileLengthToString(
            await _fileSystemRepository.getFileSize(absolutePath)),
        existsInLibrary: await exists(baseName),
        isTypeValid: await isFileValid(absolutePath),
      ));
    }

    return dataSet;
  }

  @override
  Future<Uint8List> readBookBytes(String identifier) async {
    final String absolutePath =
        await _getAbsolutePathFromIdentifier(identifier);
    return _fileSystemRepository.readFileAsBytes(absolutePath);
  }

  @override
  Future<BookCover> getCover(String identifier) async {
    return _epubDataSource
        .getCover(await _getAbsolutePathFromIdentifier(identifier));
  }

  @override
  Future<List<BookChapter>> getChapterList(String identifier) async {
    return _epubDataSource
        .getChapterList(await _getAbsolutePathFromIdentifier(identifier));
  }

  @override
  Future<BookHtmlContent> getContent(
    String identifier, {
    String? chapterIdentifier,
  }) async {
    return _epubDataSource.getContent(
      await _getAbsolutePathFromIdentifier(identifier),
      contentHref: chapterIdentifier,
    );
  }

  @override
  Future<void> reset() async {
    final String libraryPath = await _pathProvider.libraryPath;
    await _fileSystemRepository.deleteDirectory(libraryPath);
    await _fileSystemRepository.createDirectory(libraryPath);

    // Send a notification.
    onChangedController.add(null);
  }

  @override
  Future<bool> isFileValid(String path) async {
    final MimeType? mimeType = await _mimeRepository.lookupAll(path);
    if (mimeType == null || !allowedMimeType.contains(mimeType)) {
      // MimeType is not allowed.
      return false;
    }

    // Get the extension of the file.
    String ext = extension(path);
    ext = ext.isEmpty ? '' : ext.substring(1);

    // Check the extension is in the list.
    return mimeType.extensionList.contains(ext);
  }
}
