import 'dart:async';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:epubx/epubx.dart' as epub;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import 'package:path/path.dart';

import '../../../../core/html_parser/domain/entities/html_document.dart';
import '../../../../core/html_parser/html_parser.dart';
import '../../../../core/mime_resolver/domain/entities/mime_type.dart';
import '../../domain/entities/book.dart';
import '../../domain/entities/book_chapter.dart';
import '../../domain/entities/book_cover.dart';
import '../../domain/entities/book_html_content.dart';
import '../../domain/entities/book_page.dart';

class EpubDataSource {
  EpubDataSource(
    this._htmlParser,
  );

  final HtmlParser _htmlParser;

  final Map<String, BookCover> _coverBytesCache = <String, BookCover>{};

  List<String> get allowedExtensions {
    final List<String> extensions = <String>[];

    for (MimeType type in allowedMimeTypes) {
      extensions.addAll(type.extensionList);
    }

    return extensions;
  }

  List<MimeType> get allowedMimeTypes => <MimeType>[MimeType.epub];

  Future<Book> getBook(String absolutePath) async {
    final epub.EpubBook epubBook = await _loadEpubBook(absolutePath);
    final epub.Image? coverImage = _findCoverImage(epubBook);

    // Cache cover image
    final String bookIdentifier = basename(absolutePath);
    _coverBytesCache[absolutePath] = BookCover(
      identifier: absolutePath,
      width: coverImage?.width.toDouble(),
      height: coverImage?.height.toDouble(),
      bytes: coverImage == null
          ? null
          : Uint8List.fromList(img.encodePng(coverImage)),
    );

    return Book(
      identifier: bookIdentifier,
      title: epubBook.Title ?? '',
      modifiedDate: (await File(absolutePath).stat()).modified,
      coverIdentifier: bookIdentifier,
      ltr: epubBook.Schema?.Package?.Spine?.ltr ?? true,
    );
  }

  Future<BookCover> getCover(String absolutePath) async {
    if (!_coverBytesCache.containsKey(absolutePath)) {
      // Cover was not loaded. Load the book data first.
      await getBook(absolutePath);
    }
    return _coverBytesCache[absolutePath]!;
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

    // Use the requested href first.
    final String? href = contentHref ??
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
    final Map<String, Uint8List> imgFiles = <String, Uint8List>{};
    for (String imgSrc in htmlDocument.imgSrcList) {
      final Uint8List bytes =
          Uint8List.fromList(content?.Images?[imgSrc]?.Content ?? <int>[]);
      if (bytes.isNotEmpty) {
        imgFiles[imgSrc] = bytes;
      }
    }

    return BookHtmlContent(
      bookIdentifier: basename(absolutePath),
      pageIdentifier: href ?? '',
      content: htmlContent,
      stylesheet: stylesheet,
      pageList: pageList,
      imgFiles: imgFiles,
    );
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
