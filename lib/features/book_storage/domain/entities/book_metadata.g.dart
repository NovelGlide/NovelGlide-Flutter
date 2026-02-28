// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'book_metadata.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BookMetadata _$BookMetadataFromJson(Map<String, dynamic> json) =>
    _BookMetadata(
      originalFilename: json['originalFilename'] as String,
      title: json['title'] as String,
      dateAdded: DateTime.parse(json['dateAdded'] as String),
      readingState:
          ReadingState.fromJson(json['readingState'] as Map<String, dynamic>),
      bookmarks: (json['bookmarks'] as List<dynamic>)
          .map((e) => BookmarkEntry.fromJson(e as Map<String, dynamic>))
          .toList(),
    );

Map<String, dynamic> _$BookMetadataToJson(_BookMetadata instance) =>
    <String, dynamic>{
      'originalFilename': instance.originalFilename,
      'title': instance.title,
      'dateAdded': instance.dateAdded.toIso8601String(),
      'readingState': instance.readingState,
      'bookmarks': instance.bookmarks,
    };
