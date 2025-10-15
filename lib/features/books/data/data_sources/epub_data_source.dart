import 'dart:async';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:collection/collection.dart';
import 'package:epubx/epubx.dart' as epub;
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart';

import '../../../../core/domain/entities/image_bytes_data.dart';
import '../../../../core/html_parser/domain/entities/html_document.dart';
import '../../../../core/html_parser/html_parser.dart';
import '../../../../core/image_processor/image_processor.dart';
import '../../../../core/mime_resolver/domain/entities/mime_type.dart';
import '../../domain/entities/book.dart';
import '../../domain/entities/book_chapter.dart';
import '../../domain/entities/book_cover.dart';
import '../../domain/entities/book_html_content.dart';
import '../../domain/entities/book_page.dart';
import 'epub_book_loader.dart';

class EpubDataSource {
  EpubDataSource(
    this._htmlParser,
    this._bookLoader,
    this._imageProcessor,
  );

  final HtmlParser _htmlParser;
  final EpubBookLoader _bookLoader;
  final ImageProcessor _imageProcessor;

  /// Caches
  final Map<String, epub.EpubBook> _bookCache = <String, epub.EpubBook>{};
  bool _enableBookCache = false;

  List<String> get allowedExtensions {
    final List<String> extensions = <String>[];

    for (MimeType type in allowedMimeTypes) {
      extensions.addAll(type.extensionList);
    }

    return extensions;
  }

  List<MimeType> get allowedMimeTypes => <MimeType>[MimeType.epub];

  Future<Book> _parseEpubBook(
    String absolutePath,
    epub.EpubBook epubBook,
  ) async {
    final String bookIdentifier = basename(absolutePath);
    return Book(
      identifier: bookIdentifier,
      title: epubBook.Title ?? '',
      modifiedDate: (await File(absolutePath).stat()).modified,
      coverIdentifier: bookIdentifier,
      ltr: epubBook.Schema?.Package?.Spine?.ltr ?? true,
    );
  }

  Future<Book> getBook(String absolutePath) async {
    final epub.EpubBook epubBook = await _loadEpubBook(absolutePath);
    return _parseEpubBook(absolutePath, epubBook);
  }

  Stream<Book> getBooks(Set<String> absolutePathSet) async* {
    final Set<String> loadingSet = absolutePathSet;

    await for (EpubBookLoaderResult result
        in _bookLoader.loadByPathSet(absolutePathSet)) {
      if (loadingSet.contains(result.absolutePath)) {
        loadingSet.remove(result.absolutePath);
        yield await _parseEpubBook(result.absolutePath, result.epubBook);
      }

      if (loadingSet.isEmpty) {
        break;
      }
    }
  }

  Future<BookCover> getCover(String absolutePath) async {
    final epub.EpubBook epubBook = await _loadEpubBook(absolutePath);

    // Cache cover image
    final epub.Image? coverImage = _findCoverImage(epubBook);
    final Uint8List? bytes = coverImage == null
        ? null
        : await _imageProcessor.img2PngBytes(coverImage);
    return BookCover(
      identifier: absolutePath,
      width: coverImage?.width.toDouble(),
      height: coverImage?.height.toDouble(),
      bytes: bytes,
    );
  }

  Future<List<BookChapter>> getChapterList(String absolutePath) async {
    final epub.EpubBook epubBook = await _loadEpubBook(absolutePath);

    return (epubBook.Chapters ?? <epub.EpubChapter>[])
        .map((epub.EpubChapter e) => _createBookChapter(e))
        .toList();
  }

  Future<BookHtmlContent> getContent(
    String absolutePath, {
    String? contentHref,
  }) async {
    // Load the book file.
    final epub.EpubBook epubBook = await _loadEpubBook(absolutePath);
    final epub.EpubContent? content = epubBook.Content;
    final Map<String, epub.EpubTextContentFile> htmlFiles =
        content?.Html ?? <String, epub.EpubTextContentFile>{};
    final Map<String, epub.EpubTextContentFile> cssFiles =
        content?.Css ?? <String, epub.EpubTextContentFile>{};

    // The information of this book.
    final epub.EpubPackage? package = epubBook.Schema?.Package;
    final epub.EpubManifest? manifest = package?.Manifest;
    final epub.EpubSpine? spine = package?.Spine;

    // Get the first idRef in the spine list.
    final String? idRef = spine?.Items?.firstOrNull?.IdRef;

    // Get the page list
    final List<BookPage> pageList = (spine?.Items ?? <epub.EpubSpineItemRef>[])
        .map<BookPage>(
          (epub.EpubSpineItemRef spineItem) {
            return BookPage(
              identifier: manifest?.Items
                      ?.firstWhereOrNull((epub.EpubManifestItem item) =>
                          item.Id == spineItem.IdRef)
                      ?.Href ??
                  '',
            );
          },
        )
        .where((BookPage page) => page.identifier.isNotEmpty)
        .toList();

    // Use the requested href first, and check if it's in the page list.
    final String? href = pageList
            .firstWhereOrNull((BookPage page) => page.identifier == contentHref)
            ?.identifier ??
        // Find the href of the first spine.
        manifest?.Items
            ?.firstWhereOrNull((epub.EpubManifestItem item) => item.Id == idRef)
            ?.Href;

    // Parse the html document.
    final String htmlContent = htmlFiles[href]?.Content ?? '';
    final HtmlDocument htmlDocument =
        _htmlParser.parseDocument(htmlContent, sourceUrl: href);

    // Load the style contents
    String stylesheet = htmlDocument.inlineStyles.join('');
    for (String stylePath in htmlDocument.stylePathList) {
      final String styleContent = cssFiles[stylePath]?.Content ?? '';

      stylesheet += styleContent;
    }

    // Load the image contents
    final Map<String, ImageBytesData> imgFiles = <String, ImageBytesData>{};

    await Future.wait(htmlDocument.imgSrcList.map((String imgSrc) async {
      final Uint8List bytes =
          Uint8List.fromList(content?.Images?[imgSrc]?.Content ?? <int>[]);
      if (bytes.isNotEmpty) {
        final Completer<ImageBytesData> completer = Completer<ImageBytesData>();
        ui.decodeImageFromList(bytes, (ui.Image image) {
          // Preload the dimension of the image.
          completer.complete(ImageBytesData(
            bytes: bytes,
            width: image.width.toDouble(),
            height: image.height.toDouble(),
          ));
        });
        imgFiles[imgSrc] = await completer.future;
      }
    }));

    return BookHtmlContent(
      bookIdentifier: basename(absolutePath),
      pageIdentifier: href ?? '',
      domTree: htmlDocument.domTree,
      textContent: htmlDocument.textContent,
      stylesheet: stylesheet,
      pageList: pageList,
      imgFiles: imgFiles,
    );
  }

  void enableBookCache() {
    _enableBookCache = true;
  }

  void disableBookCache() {
    _enableBookCache = false;
    _bookCache.clear();
  }

  /// Loads an EpubBook asynchronously, potentially a heavy operation.
  Future<epub.EpubBook> _loadEpubBook(String filePath) async {
    if (_enableBookCache && _bookCache.containsKey(filePath)) {
      return _bookCache[filePath]!;
    }

    final EpubBookLoaderResult result = await _bookLoader
        .loadByPathSet(<String>{filePath}).firstWhere(
            (EpubBookLoaderResult result) => result.absolutePath == filePath);

    if (_enableBookCache) {
      _bookCache[filePath] = result.epubBook;
    }

    return result.epubBook;
  }

  /// Find the possible cover image of the book.
  img.Image? _findCoverImage(epub.EpubBook epubBook) {
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
  img.Image? _readImage(epub.EpubBook epubBook, String href) {
    if (epubBook.Content?.Images?.containsKey(href) == true) {
      final epub.EpubByteContentFile ref = epubBook.Content!.Images![href]!;
      final List<int>? content = ref.Content;
      return content == null ? null : img.decodeImage(content);
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
