import 'package:flutter/material.dart';

import '../../../../../core/mime_resolver/domain/entities/mime_type.dart';
import '../../../../../core/mime_resolver/presentation/mime_icon.dart';
import '../../../../../generated/i18n/app_localizations.dart';
import '../../../../photo_viewer/presentation/photo_viewer.dart';
import '../../../domain/entities/publication_link.dart';

class ExploreLinkWidget extends StatelessWidget {
  const ExploreLinkWidget({
    super.key,
    required this.link,
    this.onVisit,
    this.onDownload,
  });

  final PublicationLink link;
  final Future<void> Function(Uri uri)? onVisit;
  final Future<void> Function(Uri uri)? onDownload;

  @override
  Widget build(BuildContext context) {
    final AppLocalizations appLocalizations = AppLocalizations.of(context)!;
    return TextButton.icon(
      onPressed: _buildOnPressed(context),
      icon: _buildIcon(),
      label: Text(_getTitle(appLocalizations)),
    );
  }

  void Function()? _buildOnPressed(BuildContext context) {
    if (link.href == null) {
      return null;
    }

    if (link.type == MimeType.atomFeed) {
      // It's an atom feed link.
      return () => onVisit?.call(link.href!);
    }

    if (link.type?.isImage == true) {
      // It's an image link.
      return () => Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (BuildContext context) => PhotoViewer(
                imageUrl: link.href!.toString(),
              ),
            ),
          );
    }

    if (link.rel == PublicationLinkRelationship.acquisition &&
        link.type == MimeType.epub) {
      // It's a supported book link.
      return () => onDownload?.call(link.href!);
    }

    return null;
  }

  Widget _buildIcon() {
    if (link.type != null) {
      return MimeIcon(mimeType: link.type!);
    }

    return const Icon(Icons.question_mark_rounded);
  }

  String _getTitle(AppLocalizations appLocalizations) {
    if (link.title?.isNotEmpty == true) {
      return link.title!;
    }

    if (link.type == MimeType.atomFeed) {
      // It's an atom feed link.
      return appLocalizations.exploreBrowserViewIt;
    }

    if (link.type?.isImage == true) {
      // It's an image link.
      switch (link.rel) {
        case PublicationLinkRelationship.thumbnail:
          return appLocalizations.generalThumbnail;
        case PublicationLinkRelationship.cover:
          return appLocalizations.generalBookCover;
        default:
      }
    }

    if (link.rel == PublicationLinkRelationship.acquisition &&
        link.type == MimeType.epub) {
      // It's a supported book link.
      return appLocalizations.exploreBrowserDownloadIt;
    }

    return appLocalizations.exploreBrowserUnknownLink;
  }
}
