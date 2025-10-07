import 'dart:async';
import 'dart:io';

import 'package:collection/collection.dart';
import 'package:csslib/parser.dart' as css;
import 'package:csslib/visitor.dart' as css;
import 'package:epubx/epubx.dart' as epub;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:html/dom.dart';
import 'package:html/parser.dart' as html;
import 'package:image/image.dart' as img;
import 'package:path/path.dart';

import '../../../../core/log_system/log_system.dart';
import '../../../../core/mime_resolver/domain/entities/mime_type.dart';
import '../../domain/entities/book.dart';
import '../../domain/entities/book_chapter.dart';
import '../../domain/entities/book_content.dart';
import '../../domain/entities/book_cover.dart';
import '../../domain/entities/book_page.dart';

class EpubDataSource {
  EpubDataSource();

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

  Future<BookContent> getContent(
    String absolutePath, {
    String? contentHref,
  }) async {
    // Load the book file.
    final epub.EpubBook epubBook = await _loadEpubBook(absolutePath);
    final Map<String, epub.EpubTextContentFile> htmlFiles =
        epubBook.Content?.Html ?? <String, epub.EpubTextContentFile>{};
    final Map<String, epub.EpubTextContentFile> cssFiles =
        epubBook.Content?.Css ?? <String, epub.EpubTextContentFile>{};

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

    final String htmlContent = htmlFiles[href]?.Content ?? '';

    final Document parsedContent = html.parse(htmlContent);

    // Get the required stylesheets.
    final String dirName = dirname(href ?? '');
    final List<String> stylesheets = parsedContent.head
            ?.getElementsByTagName('link')
            .where((Element e) => e.attributes['rel'] == 'stylesheet')
            .map((Element e) => normalize(join(dirName, e.attributes['href'])))
            .toList() ??
        <String>[];

    // Load the style contents
    final Map<String, String> styleFiles = <String, String>{};
    for (String styleId in stylesheets) {
      styleFiles[styleId] = cssFiles[styleId]?.Content ?? '';

      final css.StyleSheet style = css.parse(styleFiles[styleId]!);

      for (css.TreeNode node in style.topLevels) {
        if (node is css.RuleSet) {
          LogSystem.info((node.selectorGroup?.selectors.map((css.Selector s) {
            return s.span?.text ?? '';
          }).join(','))
              .toString());
        }
      }
    }

    return BookContent(
      bookIdentifier: basename(absolutePath),
      chapterIdentifier: href ?? '',
      styleFiles: styleFiles,
      content: htmlContent,
      pageList: (spine?.Items ?? <epub.EpubSpineItemRef>[])
          .map<BookPage>((epub.EpubSpineItemRef spineItem) => BookPage(
                identifier: manifest?.Items
                        ?.firstWhereOrNull((epub.EpubManifestItem item) =>
                            item.Id == spineItem.IdRef)
                        ?.Href ??
                    '',
              ))
          .where((BookPage page) => page.identifier.isNotEmpty)
          .toList(),
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
