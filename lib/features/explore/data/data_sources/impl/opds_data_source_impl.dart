import 'dart:async';

import 'package:rss_dart/dart_rss.dart';

import '../../../../../core/http_client/domain/repositories/http_client_repository.dart';
import '../../../../../core/mime_resolver/domain/entities/mime_type.dart';
import '../../../../../core/parser_system/datetime_parser.dart';
import '../../../../../core/parser_system/uri_parser.dart';
import '../../../domain/entities/catalog_feed.dart';
import '../../../domain/entities/publication_author.dart';
import '../../../domain/entities/publication_entry.dart';
import '../../../domain/entities/publication_link.dart';
import '../explore_data_source.dart';

/// A concrete implementation of DiscoverDataSource for OPDS feeds.
class OpdsDataSourceImpl implements ExploreDataSource {
  OpdsDataSourceImpl(
    this._httpClientRepository,
  );

  final HttpClientRepository _httpClientRepository;

  /// Fetches an OPDS catalog feed from a given URL and parses it.
  @override
  Future<CatalogFeed?> getCatalogFeed(Uri uri) async {
    try {
      final String? data = await _httpClientRepository.get<String>(uri);

      if (data?.isEmpty == true) {
        return null;
      }

      final AtomFeed feed = AtomFeed.parse(data!);

      return CatalogFeed(
        id: feed.id?.trim(),
        title: feed.title?.trim(),
        updated: DateTimeParser.tryParse(feed.updated),
        links: feed.links.map(_parseLink).toList(),
        entries: feed.items.map(_parseEntry).toList(),
      );
    } catch (_) {
      return null;
    }
  }

  /// ========== Parsers ==========

  PublicationLink _parseLink(AtomLink link) {
    final Uri? href = link.href == null ? null : Uri.tryParse(link.href!);
    final String? rel = link.rel?.trim();
    final List<String>? typeList = link.type?.split(';');
    final String? mimeString = typeList?.first.trim();
    final MimeType? mimeType = MimeType.tryParse(mimeString);
    return PublicationLink(
      href: href,
      rel: switch (rel) {
        // Catalog rel
        'next' => PublicationLinkRelationship.nextCatalog,
        // Entry rel
        'http://opds-spec.org/thumbnail' =>
          PublicationLinkRelationship.thumbnail,
        'http://opds-spec.org/image/thumbnail' =>
          PublicationLinkRelationship.thumbnail,
        'http://opds-spec.org/cover' => PublicationLinkRelationship.cover,
        'http://opds-spec.org/image' => PublicationLinkRelationship.cover,
        'http://opds-spec.org/acquisition/open-access' =>
          PublicationLinkRelationship.acquisition,
        'http://opds-spec.org/acquisition/buy' =>
          PublicationLinkRelationship.buy,
        'http://opds-spec.org/acquisition/borrow' =>
          PublicationLinkRelationship.borrow,
        'http://opds-spec.org/acquisition/subscribe' =>
          PublicationLinkRelationship.subscribe,
        'http://opds-spec.org/acquisition/sample' =>
          PublicationLinkRelationship.sample,
        'http://opds-spec.org/acquisition' =>
          PublicationLinkRelationship.acquisition,
        _ => null,
      },
      type: mimeType,
      title: link.title,
    );
  }

  PublicationEntry _parseEntry(AtomItem item) {
    return PublicationEntry(
      id: item.id?.trim(),
      title: item.title?.trim(),
      updated: DateTimeParser.tryParse(item.updated),
      summary: item.summary,
      content: item.content?.trim(),
      authors: item.authors.map(_parseAuthor).toList(),
      links: item.links.map(_parseLink).toList(),
    );
  }

  PublicationAuthor _parseAuthor(AtomPerson person) {
    return PublicationAuthor(
      name: person.name?.trim().isNotEmpty == true ? person.name?.trim() : null,
      uri: person.uri?.trim().isNotEmpty == true
          ? UriParser.parseHttps(person.uri!)
          : null,
    );
  }
}
