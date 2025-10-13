import 'package:flutter/material.dart';
import 'package:flutter_html/flutter_html.dart';

import '../../../../locale_system/locale_utils.dart';
import '../../../domain/entities/publication_author.dart';
import '../../../domain/entities/publication_entry.dart';
import '../../../domain/entities/publication_link.dart';
import 'explore_author_widget.dart';
import 'explore_link_widget.dart';
import 'explore_thumbnail_widget.dart';

class ExploreEntryWidget extends StatelessWidget {
  const ExploreEntryWidget({
    super.key,
    required this.entry,
    this.onVisit,
    this.onDownload,
  });

  final PublicationEntry entry;
  final Future<void> Function(Uri uri)? onVisit;
  final Future<void> Function(Uri uri, String? entryTitle)? onDownload;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(
        vertical: 8.0,
        horizontal: 16.0,
      ),
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(24.0),
      ),
      child: Column(
        children: <Widget?>[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget?>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget?>[
                    _buildTitle(context),
                    _buildAuthors(context),
                    const Padding(
                      padding: EdgeInsets.only(bottom: 16.0),
                      child: Divider(),
                    ),
                    _buildSummary(context),
                    _buildPublishedDate(context),
                    _buildPublisher(context),
                    _buildLinkWidget(context),
                  ].whereType<Widget>().toList(),
                ),
              ),
              ExploreThumbnailWidget(
                entryLinks: entry.links,
              ),
            ].whereType<Widget>().toList(),
          ),
        ].whereType<Widget>().toList(),
      ),
    );
  }

  Widget? _buildTitle(BuildContext context) {
    if (entry.title == null && entry.updated == null) {
      return null;
    } else {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
        child: ListTile(
          contentPadding: EdgeInsets.zero,
          title: entry.title == null
              ? null
              : Text(
                  entry.title!,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                ),
          subtitle: entry.updated == null
              ? null
              : Text(
                  LocaleUtils.dateTimeOf(context, entry.updated) ?? '',
                ),
        ),
      );
    }
  }

  Widget? _buildAuthors(BuildContext context) {
    final List<PublicationAuthor> authorName = entry.authors
        .where((PublicationAuthor author) =>
            author.name?.trim().isNotEmpty == true)
        .toList();
    if (authorName.isEmpty) {
      return null;
    } else {
      return OverflowBar(
        children: authorName
            .map((PublicationAuthor author) => ExploreAuthorWidget(
                  author: author,
                  onVisit: onVisit,
                ))
            .toList(),
      );
    }
  }

  Widget? _buildSummary(BuildContext context) {
    if (entry.content == null || entry.content!.isEmpty) {
      return null;
    } else {
      return Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
        child: Html(
          data: entry.content,
        ),
      );
    }
  }

  Widget? _buildPublishedDate(BuildContext context) {
    if (entry.publishedDate == null) {
      return null;
    } else {
      return ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const Icon(Icons.calendar_today_rounded),
        title: Text(LocaleUtils.dateTimeOf(context, entry.publishedDate) ?? ''),
        titleTextStyle: Theme.of(context).textTheme.bodyMedium,
        textColor: Theme.of(context).colorScheme.secondary,
        iconColor: Theme.of(context).colorScheme.secondary,
        visualDensity: VisualDensity.compact,
      );
    }
  }

  Widget? _buildPublisher(BuildContext context) {
    if (entry.publisher == null) {
      return null;
    } else {
      return ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const Icon(Icons.business_rounded),
        title: Text(LocaleUtils.dateTimeOf(context, entry.publishedDate) ?? ''),
        titleTextStyle: Theme.of(context).textTheme.bodyMedium,
        textColor: Theme.of(context).colorScheme.secondary,
        iconColor: Theme.of(context).colorScheme.secondary,
        visualDensity: VisualDensity.compact,
      );
    }
  }

  Widget? _buildLinkWidget(BuildContext context) {
    final Iterable<PublicationLink> supportedLinks =
        entry.links.where((PublicationLink link) => link.type != null);
    if (supportedLinks.isEmpty) {
      return null;
    } else {
      return OverflowBar(
        alignment: MainAxisAlignment.center,
        spacing: 8.0,
        children: supportedLinks
            .map(
              (PublicationLink link) => ExploreLinkWidget(
                link: link,
                onVisit: onVisit,
                onDownload: (Uri uri) async =>
                    onDownload?.call(uri, entry.title),
              ),
            )
            .toList(),
      );
    }
  }
}
