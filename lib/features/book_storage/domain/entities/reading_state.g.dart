// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reading_state.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ReadingState _$ReadingStateFromJson(Map<String, dynamic> json) =>
    _ReadingState(
      cfiPosition: json['cfiPosition'] as String,
      progress: (json['progress'] as num).toDouble(),
      lastReadTime: DateTime.parse(json['lastReadTime'] as String),
      totalSeconds: (json['totalSeconds'] as num).toInt(),
    );

Map<String, dynamic> _$ReadingStateToJson(_ReadingState instance) =>
    <String, dynamic>{
      'cfiPosition': instance.cfiPosition,
      'progress': instance.progress,
      'lastReadTime': instance.lastReadTime.toIso8601String(),
      'totalSeconds': instance.totalSeconds,
    };
