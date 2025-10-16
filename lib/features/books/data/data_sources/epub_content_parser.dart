import 'dart:async';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:collection/collection.dart';
import 'package:epubx/epubx.dart' as epub;
import 'package:path/path.dart';

import '../../../../core/css_parser/css_parser.dart';
import '../../../../core/css_parser/domain/entities/css_document.dart';
import '../../../../core/css_parser/domain/entities/rule_sets/css_font_face.dart';
import '../../../../core/domain/entities/font_file.dart';
import '../../../../core/domain/entities/image_bytes_data.dart';
import '../../../../core/html_parser/domain/entities/html_document.dart';
import '../../../../core/html_parser/html_parser.dart';
import '../../../../core/mime_resolver/domain/entities/mime_type.dart';
import '../../domain/entities/book_page.dart';

class EpubContentParser {
  EpubContentParser(this._htmlParser, this._cssParser);

  final HtmlParser _htmlParser;
  final CssParser _cssParser;

  List<BookPage> parsePageList(epub.EpubBook epubBook) {
    final epub.EpubPackage? package = epubBook.Schema?.Package;
    final epub.EpubManifest? manifest = package?.Manifest;
    final epub.EpubSpine? spine = package?.Spine;

    return (spine?.Items ?? <epub.EpubSpineItemRef>[])
        .map<BookPage>(
          (epub.EpubSpineItemRef spineItem) => BookPage(
            identifier: manifest?.Items
                    ?.firstWhereOrNull((epub.EpubManifestItem item) =>
                        item.Id == spineItem.IdRef)
                    ?.Href ??
                '',
          ),
        )
        .where((BookPage page) => page.identifier.isNotEmpty)
        .toList();
  }

  String getValidPageIdentifier(
    epub.EpubBook epubBook,
    String? targetHref, {
    List<BookPage>? pageList,
  }) {
    return (pageList ?? parsePageList(epubBook))
            .firstWhereOrNull((BookPage page) => page.identifier == targetHref)
            ?.identifier ??
        getFirstPageIdentifier(epubBook) ??
        '';
  }

  String? getFirstPageIdentifier(epub.EpubBook epubBook) {
    final epub.EpubPackage? package = epubBook.Schema?.Package;
    final epub.EpubManifest? manifest = package?.Manifest;
    final epub.EpubSpine? spine = package?.Spine;

    // Get the first idRef in the spine list.
    final String? idRef = spine?.Items?.firstOrNull?.IdRef;
    return manifest?.Items
        ?.firstWhereOrNull((epub.EpubManifestItem item) => item.Id == idRef)
        ?.Href;
  }

  HtmlDocument parseHtmlDocument(epub.EpubBook epubBook, String href) {
    final epub.EpubContent? content = epubBook.Content;
    final Map<String, epub.EpubTextContentFile> htmlFiles =
        content?.Html ?? <String, epub.EpubTextContentFile>{};

    // Parse the html document.
    final String htmlContent = htmlFiles[href]?.Content ?? '';
    return _htmlParser.parseDocument(htmlContent, sourceUrl: href);
  }

  Map<String, CssDocument> loadStylesheets(
    epub.EpubBook epubBook,
    String href,
    List<String> stylePathList,
    String inlineStyle,
  ) {
    final epub.EpubContent? content = epubBook.Content;
    final Map<String, epub.EpubTextContentFile> cssFiles =
        content?.Css ?? <String, epub.EpubTextContentFile>{};
    final Map<String, CssDocument> styleMap = <String, CssDocument>{};

    // Parse the inline style
    if (inlineStyle.isNotEmpty) {
      styleMap[href] = _cssParser.parseDocument(inlineStyle);
    }

    for (String stylePath in stylePathList) {
      final String styleContent = cssFiles[stylePath]?.Content ?? '';

      if (styleContent.isNotEmpty) {
        styleMap[stylePath] = _cssParser.parseDocument(styleContent);
      }
    }

    return styleMap;
  }

  Future<Map<String, ImageBytesData>> loadImages(
    epub.EpubBook epubBook,
    List<String> pathList,
  ) async {
    final epub.EpubContent? content = epubBook.Content;
    final Map<String, ImageBytesData> imgFiles = <String, ImageBytesData>{};

    await Future.wait(pathList.map((String path) async {
      final Uint8List bytes =
          Uint8List.fromList(content?.Images?[path]?.Content ?? <int>[]);
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
        imgFiles[path] = await completer.future;
      }
    }));

    return imgFiles;
  }

  Set<FontFile> loadFonts(
    epub.EpubBook epubBook,
    Map<String, CssDocument> styleMap,
  ) {
    final epub.EpubContent? content = epubBook.Content;

    // Absolute path in book -> CssFontFace map.
    final Map<String, CssFontFace> fontFaceMap = <String, CssFontFace>{};

    for (MapEntry<String, CssDocument> entry in styleMap.entries) {
      final String href = entry.key;
      final CssDocument document = entry.value;

      for (CssFontFace fontFace in document.fontFaces) {
        final String absolutePath =
            normalize(join(dirname(href), fontFace.url));
        fontFaceMap[absolutePath] = fontFace;
      }
    }

    final Set<FontFile> fontFiles = <FontFile>{};

    content?.AllFiles?.forEach((String key, epub.EpubContentFile value) {
      final MimeType? mimeType = MimeType.tryParse(value.ContentMimeType);
      if (mimeType?.isFont == true && value is epub.EpubByteContentFile) {
        // It's a font file.
        final CssFontFace? fontFace = fontFaceMap[key];

        if (fontFace != null && value.Content?.isNotEmpty == true) {
          // This font-face will be used.
          fontFiles.add(FontFile(
            fontFace: fontFace,
            bytes: Uint8List.fromList(value.Content!),
          ));
        }
      }
    });

    return fontFiles;
  }
}
