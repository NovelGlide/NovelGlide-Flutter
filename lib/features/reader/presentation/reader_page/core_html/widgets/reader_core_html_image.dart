import 'dart:collection';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:path/path.dart';

import '../../../../../../core/domain/entities/image_bytes_data.dart';
import '../../../../../../core/services/cache_memory_image_provider.dart';
import '../../../../../books/domain/entities/book_html_content.dart';
import '../../../../../photo_viewer/presentation/photo_viewer.dart';
import '../../../../../shared_components/animated_placeholders/ease_flash_placeholder.dart';
import '../../../../../shared_components/animated_switchers/simple_fade_switcher.dart';
import '../../cubit/reader_cubit.dart';

class ReaderCoreHtmlImage extends StatelessWidget {
  const ReaderCoreHtmlImage({
    super.key,
    required this.bookHtmlContent,
    required this.alt,
    required this.src,
  });

  final BookHtmlContent bookHtmlContent;
  final String? alt;
  final String src;

  @override
  Widget build(BuildContext context) {
    final ReaderCubit cubit = BlocProvider.of<ReaderCubit>(context);

    if (isRelative(src)) {
      // Relative path. It's an image stored in the book.
      // Construct the "in-book" absolute path.
      final String path =
          cubit.getInBookPath(bookHtmlContent.pageIdentifier, src);
      final ImageBytesData? data = bookHtmlContent.imgFiles[path];
      if (data != null) {
        return Semantics(
          // TODO(kai): Localization.
          onTapHint: 'Click it to open it in the photo viewer.',
          child: InkWell(
            onTap: () => Navigator.of(context).push(MaterialPageRoute<void>(
              builder: (BuildContext context) => PhotoViewer(
                imageBytes: data.bytes,
              ),
            )),
            child: AspectRatio(
              aspectRatio: data.width / data.height,
              child: Image(
                image: CacheMemoryImageProvider(
                  '${bookHtmlContent.bookIdentifier}_$src',
                  data.bytes,
                ),
                fit: BoxFit.contain,
                semanticLabel: alt ?? src,
                frameBuilder: (
                  BuildContext context,
                  Widget child,
                  int? frame,
                  bool wasSynchronouslyLoaded,
                ) {
                  if (wasSynchronouslyLoaded) {
                    return child; // Image loaded instantly, show it directly
                  }

                  final bool isLoading = frame == null;
                  return SimpleFadeSwitcher(
                    child: isLoading ? const EaseFlashPlaceholder() : child,
                  );
                },
              ),
            ),
          ),
        );
      }
    } else if (isAbsolute(src)) {
      // Maybe an image from online or local storage?
    }

    return const SizedBox.shrink();
  }

  /// Create the tag extension.
  static TagExtension tagExtension(BookHtmlContent htmlContent) {
    return TagExtension(
      tagsToExtend: <String>{'img'},
      builder: (ExtensionContext extensionContext) {
        final LinkedHashMap<String, String> attributes =
            extensionContext.attributes;
        if (attributes['src'] == null) {
          return const SizedBox.shrink();
        } else {
          return ReaderCoreHtmlImage(
            bookHtmlContent: htmlContent,
            alt: attributes['alt'],
            src: attributes['src']!,
          );
        }
      },
    );
  }
}
