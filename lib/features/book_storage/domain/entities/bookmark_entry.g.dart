// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bookmark_entry.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BookmarkEntry _$BookmarkEntryFromJson(Map<String, dynamic> json) =>
    _BookmarkEntry(
      id: json['id'] as String,
      cfiPosition: json['cfiPosition'] as String,
      timestamp: DateTime.parse(json['timestamp'] as String),
      label: json['label'] as String?,
    );

Map<String, dynamic> _$BookmarkEntryToJson(_BookmarkEntry instance) =>
    <String, dynamic>{
      'id': instance.id,
      'cfiPosition': instance.cfiPosition,
      'timestamp': instance.timestamp.toIso8601String(),
      'label': instance.label,
    };
