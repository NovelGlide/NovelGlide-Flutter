import 'dart:async';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:epubx/epubx.dart' as epub;
import 'package:flutter/foundation.dart';
import 'package:image/image.dart' as img;
import 'package:novel_glide/core/domain/entities/font_file.dart';
import 'package:path/path.dart';

import '../../../../core/css_parser/domain/entities/css_document.dart';
import '../../../../core/domain/entities/image_file.dart';
import '../../../../core/html_parser/domain/entities/html_document.dart';
import '../../../../core/image_processor/image_processor.dart';
import '../../../../core/mime_resolver/domain/entities/mime_type.dart';
import '../../domain/entities/book.dart';
import '../../domain/entities/book_chapter.dart';
import '../../domain/entities/book_cover.dart';
import '../../domain/entities/book_html_content.dart';
import '../../domain/entities/book_page.dart';
import 'epub_book_loader.dart';
import 'epub_content_parser.dart';

class EpubDataSource {
  EpubDataSource(
    this._bookLoader,
    this._contentParser,
    this._imageProcessor,
  );

  final EpubBookLoader _bookLoader;
  final EpubContentParser _contentParser;
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

    // Get the page list
    final List<BookPage> pageList = _contentParser.parsePageList(epubBook);

    // Use the requested href first, and check if it's in the page list.
    final String href = _contentParser.getValidPageIdentifier(
      epubBook,
      contentHref,
      pageList: pageList,
    );

    // Parse the html document.
    final HtmlDocument htmlDocument =
        _contentParser.parseHtmlDocument(epubBook, href);

    // Load the style contents
    final Map<String, CssDocument> styleList = _contentParser.loadStylesheets(
      epubBook,
      href,
      htmlDocument.stylePathList,
    );

    // Load the fonts
    final Set<FontFile> fonts = _contentParser.loadFonts(epubBook, styleList);

    // Load the image contents
    final Map<String, ImageFile> imgFiles = await _contentParser.loadImages(
      epubBook,
      htmlDocument.imgSrcList,
    );

    return BookHtmlContent(
      bookIdentifier: basename(absolutePath),
      pageIdentifier: href,
      domTree: htmlDocument.domTree,
      stylesheet: styleList.values.map((CssDocument d) => d.content).join('') +
          htmlDocument.inlineStyles.join(''),
      fonts: fonts,
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
