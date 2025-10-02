import 'dart:async';
import 'dart:io';
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:epubx/epubx.dart' as epub;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:image/image.dart';
import 'package:novel_glide/core/utils/random_extension.dart';
import 'package:path/path.dart';

import '../../../../../core/file_system/domain/repositories/file_system_repository.dart';
import '../../../../../core/log_system/log_system.dart';
import '../../../../../core/mime_resolver/domain/entities/mime_type.dart';
import '../../../../../core/mime_resolver/domain/repositories/mime_repository.dart';
import '../../../../../core/path_provider/domain/repositories/app_path_provider.dart';
import '../../../domain/entities/book.dart';
import '../../../domain/entities/book_chapter.dart';
import '../../../domain/entities/book_cover.dart';
import '../book_local_data_source.dart';

class EpubDataSource extends BookLocalDataSource {
  EpubDataSource(
    this._pathProvider,
    this._fileSystemRepository,
    this._mimeRepository,
  );

  final AppPathProvider _pathProvider;
  final FileSystemRepository _fileSystemRepository;
  final MimeRepository _mimeRepository;

  final Map<String, BookCover> _coverBytesCache = <String, BookCover>{};

  Future<String> _getAbsolutePathFromIdentifier(String identifier) async {
    final String libraryPath = await _pathProvider.libraryPath;
    return join(libraryPath, identifier);
  }

  @override
  List<String> get allowedExtensions {
    final List<String> extensions = <String>[];

    for (MimeType type in allowedMimeTypes) {
      extensions.addAll(type.extensionList);
    }

    return extensions;
  }

  @override
  List<MimeType> get allowedMimeTypes => <MimeType>[MimeType.epub];

  @override
  Future<void> addBooks(Set<String> externalPathSet) async {
    for (String path in externalPathSet) {
      final MimeType? mimeType = await _mimeRepository.lookupAll(path);
      if (mimeType == null || !allowedMimeTypes.contains(mimeType)) {
        LogSystem.warn(
            '<EpubDataSource.addBooks> Invalid mime type of this file: $path');
        continue;
      }

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
  }

  @override
  Future<bool> delete(String identifier) async {
    final String destination = await _getAbsolutePathFromIdentifier(identifier);
    if (await _fileSystemRepository.existsFile(destination)) {
      await _fileSystemRepository.deleteFile(destination);
    }

    return !await _fileSystemRepository.existsFile(destination);
  }

  @override
  Future<void> deleteAllBooks() async {
    final String libraryPath = await _pathProvider.libraryPath;
    await _fileSystemRepository.deleteDirectory(libraryPath);
    await _fileSystemRepository.createDirectory(libraryPath);
  }

  @override
  Future<bool> exists(String identifier) async {
    final String destination = await _getAbsolutePathFromIdentifier(identifier);
    return _fileSystemRepository.existsFile(destination);
  }

  @override
  Future<Book> getBook(String identifier) async {
    final String absolutePath =
        await _getAbsolutePathFromIdentifier(identifier);
    final epub.EpubBook epubBook = await _loadEpubBook(absolutePath);
    final epub.Image? coverImage = _findCoverImage(epubBook);

    // Cache cover image
    final String bookIdentifier = basename(absolutePath);
    _coverBytesCache[bookIdentifier] = BookCover(
      identifier: bookIdentifier,
      width: coverImage?.width.toDouble(),
      height: coverImage?.height.toDouble(),
      bytes: coverImage == null
          ? null
          : Uint8List.fromList(img.encodePng(coverImage)),
    );

    return Book(
      identifier: bookIdentifier,
      title: epubBook.Title ?? '',
      modifiedDate: await _fileSystemRepository.getModifiedDate(absolutePath),
      coverIdentifier: bookIdentifier,
      ltr: epubBook.Schema?.Package?.Spine?.ltr ?? true,
    );
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
  Future<Uint8List> readBookBytes(String identifier) async {
    final String absolutePath =
        await _getAbsolutePathFromIdentifier(identifier);
    return _fileSystemRepository.readFileAsBytes(absolutePath);
  }

  @override
  Future<BookCover> getCover(String identifier) async {
    if (!_coverBytesCache.containsKey(identifier)) {
      // Cover was not loaded. Load the book data first.
      await getBook(identifier);
    }
    return _coverBytesCache[identifier]!;
  }

  @override
  Future<List<BookChapter>> getChapterList(String identifier) async {
    final String absolutePath =
        await _getAbsolutePathFromIdentifier(identifier);
    final epub.EpubBook epubBook = await _loadEpubBook(absolutePath);

    return (epubBook.Chapters ?? <epub.EpubChapter>[])
        .map((epub.EpubChapter e) => _createBookChapter(e))
        .toList();
  }

  @override
  Future<String?> getContent(
    String identifier, {
    String? contentHref,
  }) async {
    // Load the book file.
    final String absolutePath =
        await _getAbsolutePathFromIdentifier(identifier);
    final epub.EpubBook epubBook = await _loadEpubBook(absolutePath);
    final Map<String, epub.EpubTextContentFile> htmlFiles =
        epubBook.Content?.Html ?? <String, epub.EpubTextContentFile>{};

    // The information of this book.
    final epub.EpubPackage? package = epubBook.Schema?.Package;
    final epub.EpubManifest? manifest = package?.Manifest;
    final epub.EpubSpine? spine = package?.Spine;

    // Get the first idRef in the spine list.
    final String? idRef = spine?.Items?.firstOrNull?.IdRef;

    // Use the requested href first.
    final String? href = contentHref ??
        // Find the href of the first spine.
        manifest?.Items
            ?.firstWhereOrNull((epub.EpubManifestItem item) => item.Id == idRef)
            ?.Href;

    LogSystem.info(href.toString());

    return htmlFiles[href]?.Content;
  }

  @override
  Future<bool> isFileValid(String path) async {
    final MimeType? mimeType = await _mimeRepository.lookupAll(path);
    if (mimeType == null) {
      // MimeType is not found.
      return false;
    }

    // Get the extension of the file.
    String ext = extension(path);
    ext = ext.isEmpty ? '' : ext.substring(1);

    // Check the extension is in the list.
    return mimeType.extensionList.contains(ext);
  }

  /// Loads an EpubBook asynchronously, potentially a heavy operation.
  Future<epub.EpubBook> _loadEpubBook(String filePath) async {
    final RootIsolateToken rootIsolateToken = RootIsolateToken.instance!;
    return await compute<Map<String, dynamic>, epub.EpubBook>(
        _loadEpubBookIsolate, <String, dynamic>{
      'rootIsolateToken': rootIsolateToken,
      'path': filePath,
    });
  }

  /// Isolate function to load an EpubBook.
  Future<epub.EpubBook> _loadEpubBookIsolate(
      Map<String, dynamic> message) async {
    final RootIsolateToken rootIsolateToken = message['rootIsolateToken'];
    final String path = message['path'];
    BackgroundIsolateBinaryMessenger.ensureInitialized(rootIsolateToken);
    return await epub.EpubReader.readBook(File(path).readAsBytes());
  }

  /// Find the possible cover image of the book.
  Image? _findCoverImage(epub.EpubBook epubBook) {
    // The cover image found by epub package.
    if (epubBook.CoverImage != null) {
      return epubBook.CoverImage!;
    }

    // Search the cover image in the manifest.
    if (epubBook.Schema?.Package?.Manifest != null) {
      final epub.EpubManifest manifest = epubBook.Schema!.Package!.Manifest!;
      final epub.EpubManifestItem? coverItem = manifest.Items!.firstWhereOrNull(
          (epub.EpubManifestItem item) =>
              item.Href != null &&
              (item.Id?.toLowerCase() == 'cover' ||
                  item.Id?.toLowerCase() == 'cover-image' ||
                  item.Properties?.toLowerCase() == 'cover' ||
                  item.Properties?.toLowerCase() == 'cover-image') &&
              MimeType.tryParse(item.MediaType?.toLowerCase())?.isImage ==
                  true);
      if (coverItem != null) {
        return _readImage(epubBook, coverItem.Href!);
      }
    }

    // Not found.
    return null;
  }

  /// Read an image from the book_service.
  Image? _readImage(epub.EpubBook epubBook, String href) {
    if (epubBook.Content?.Images?.containsKey(href) == true) {
      final epub.EpubByteContentFile ref = epubBook.Content!.Images![href]!;
      final List<int>? content = ref.Content;
      return content == null ? null : decodeImage(content);
    }
    return null;
  }

  /// Recursively create the nested chapter list.
  BookChapter _createBookChapter(epub.EpubChapter epubChapter) {
    return BookChapter(
      title: epubChapter.Title ?? '',
      identifier: epubChapter.ContentFileName ?? '',
      subChapterList: (epubChapter.SubChapters ?? <epub.EpubChapter>[])
          .map((epub.EpubChapter e) => _createBookChapter(e))
          .toList(),
    );
  }
}
