import 'package:flutter/material.dart';

import '../../../../core/services/cache_memory_image_provider.dart';
import '../../../../generated/i18n/app_localizations.dart';
import '../../domain/entities/book_cover.dart';

class BookCoverWidget extends StatelessWidget {
  const BookCoverWidget({
    super.key,
    required this.coverData,
    required this.fit,
  });

  final BookCover coverData;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations appLocalizations = AppLocalizations.of(context)!;
    ImageProvider? imageProvider;

    // Bytes are not null
    if (coverData.bytes != null && coverData.hasSize) {
      // Use bitmap to display the cover
      imageProvider = CacheMemoryImageProvider(
        coverData.identifier,
        coverData.bytes!,
      );
    } else if (coverData.url != null) {
      // Url are not empty
      // Load the network image
      imageProvider ??= NetworkImage(coverData.url!.toString());
    } else {
      // There is not an image. Use the image in the asset.
      final Brightness brightness = Theme.of(context).brightness;
      final String fileName =
          'book_cover_${brightness == Brightness.dark ? 'dark' : 'light'}.jpg';

      imageProvider ??= AssetImage('assets/images/$fileName');
    }

    return Image(
      image: imageProvider,
      fit: BoxFit.cover,
      gaplessPlayback: true,
      semanticLabel: appLocalizations.generalBookCover,
    );
  }
}
