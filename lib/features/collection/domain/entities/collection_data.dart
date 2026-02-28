import 'package:freezed_annotation/freezed_annotation.dart';

import 'package:novel_glide/features/book_storage/domain/repositories/book_storage.dart';

part 'collection_data.freezed.dart';
part 'collection_data.g.dart';

/// Represents a user-created collection of books.
///
/// A collection is an ordered list of books identified by their stable
/// [BookId]s. Collections are immutable and can be copied with
/// modifications via [copyWith].
///
/// The [bookIds] list is the primary content of a collection. All other
/// fields are metadata about the collection itself (name, description,
/// color, timestamps).
@freezed
abstract class CollectionData with _$CollectionData {
  const factory CollectionData({
    /// Unique identifier for this collection.
    required String id,

    /// Display name of the collection.
    required String name,

    /// Ordered list of book IDs in this collection.
    ///
    /// Books are identified by their stable [BookId] (UUID) rather than
    /// filenames. This makes collections resilient to book renames or
    /// moves within the library.
    ///
    /// The order of this list is significant — it determines the display
    /// order of books in the collection view.
    required List<BookId> bookIds,

    /// User-provided description or notes about the collection.
    @Default('') String description,

    /// The date and time when this collection was created.
    required DateTime createdAt,

    /// The date and time when this collection was last modified.
    required DateTime updatedAt,

    /// Color identifier for the collection (hex format or color name).
    @Default('#808080') String color,
  }) = _CollectionData;

  const CollectionData._();

  factory CollectionData.fromJson(Map<String, dynamic> json) =>
      _$CollectionDataFromJson(json);
}
