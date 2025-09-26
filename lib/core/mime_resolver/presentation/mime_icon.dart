import 'package:flutter/material.dart';

import '../domain/entities/mime_type.dart';

class MimeIcon extends StatelessWidget {
  const MimeIcon({super.key, required this.mimeType});

  final MimeType mimeType;

  @override
  Widget build(BuildContext context) {
    return Icon(getIconData(mimeType));
  }

  static IconData getIconData(MimeType mimeType) {
    if (mimeType.isImage) {
      return Icons.image_rounded;
    }

    return switch (mimeType) {
      MimeType.atomFeed => Icons.link_rounded,
      MimeType.epub => Icons.download_rounded,
      MimeType.zip => Icons.folder_zip_rounded,
      MimeType.pdf => Icons.picture_as_pdf_rounded,
      _ => Icons.question_mark_rounded,
    };
  }
}
