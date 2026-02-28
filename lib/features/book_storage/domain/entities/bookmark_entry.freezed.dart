// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'bookmark_entry.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BookmarkEntry {
  /// Unique identifier for this bookmark.
  String get id;

  /// EPUB Canonical Fragment Identifier position string.
  /// Identifies the exact location in the book where this bookmark was created.
  String get cfiPosition;

  /// Date and time when this bookmark was created.
  DateTime get timestamp;

  /// Optional user-defined label or note for this bookmark.
  String? get label;

  /// Create a copy of BookmarkEntry
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $BookmarkEntryCopyWith<BookmarkEntry> get copyWith =>
      _$BookmarkEntryCopyWithImpl<BookmarkEntry>(
          this as BookmarkEntry, _$identity);

  /// Serializes this BookmarkEntry to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is BookmarkEntry &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.cfiPosition, cfiPosition) ||
                other.cfiPosition == cfiPosition) &&
            (identical(other.timestamp, timestamp) ||
                other.timestamp == timestamp) &&
            (identical(other.label, label) || other.label == label));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, id, cfiPosition, timestamp, label);

  @override
  String toString() {
    return 'BookmarkEntry(id: $id, cfiPosition: $cfiPosition, timestamp: $timestamp, label: $label)';
  }
}

/// @nodoc
abstract mixin class $BookmarkEntryCopyWith<$Res> {
  factory $BookmarkEntryCopyWith(
          BookmarkEntry value, $Res Function(BookmarkEntry) _then) =
      _$BookmarkEntryCopyWithImpl;
  @useResult
  $Res call({String id, String cfiPosition, DateTime timestamp, String? label});
}

/// @nodoc
class _$BookmarkEntryCopyWithImpl<$Res>
    implements $BookmarkEntryCopyWith<$Res> {
  _$BookmarkEntryCopyWithImpl(this._self, this._then);

  final BookmarkEntry _self;
  final $Res Function(BookmarkEntry) _then;

  /// Create a copy of BookmarkEntry
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? cfiPosition = null,
    Object? timestamp = null,
    Object? label = freezed,
  }) {
    return _then(_self.copyWith(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      cfiPosition: null == cfiPosition
          ? _self.cfiPosition
          : cfiPosition // ignore: cast_nullable_to_non_nullable
              as String,
      timestamp: null == timestamp
          ? _self.timestamp
          : timestamp // ignore: cast_nullable_to_non_nullable
              as DateTime,
      label: freezed == label
          ? _self.label
          : label // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// Adds pattern-matching-related methods to [BookmarkEntry].
extension BookmarkEntryPatterns on BookmarkEntry {
  /// A variant of `map` that fallback to returning `orElse`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>(
    TResult Function(_BookmarkEntry value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _BookmarkEntry() when $default != null:
        return $default(_that);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// Callbacks receives the raw object, upcasted.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case final Subclass2 value:
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult map<TResult extends Object?>(
    TResult Function(_BookmarkEntry value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _BookmarkEntry():
        return $default(_that);
      case _:
        throw StateError('Unexpected subclass');
    }
  }

  /// A variant of `map` that fallback to returning `null`.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case final Subclass value:
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>(
    TResult? Function(_BookmarkEntry value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _BookmarkEntry() when $default != null:
        return $default(_that);
      case _:
        return null;
    }
  }

  /// A variant of `when` that fallback to an `orElse` callback.
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return orElse();
  /// }
  /// ```

  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>(
    TResult Function(
            String id, String cfiPosition, DateTime timestamp, String? label)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _BookmarkEntry() when $default != null:
        return $default(
            _that.id, _that.cfiPosition, _that.timestamp, _that.label);
      case _:
        return orElse();
    }
  }

  /// A `switch`-like method, using callbacks.
  ///
  /// As opposed to `map`, this offers destructuring.
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case Subclass2(:final field2):
  ///     return ...;
  /// }
  /// ```

  @optionalTypeArgs
  TResult when<TResult extends Object?>(
    TResult Function(
            String id, String cfiPosition, DateTime timestamp, String? label)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _BookmarkEntry():
        return $default(
            _that.id, _that.cfiPosition, _that.timestamp, _that.label);
      case _:
        throw StateError('Unexpected subclass');
    }
  }

  /// A variant of `when` that fallback to returning `null`
  ///
  /// It is equivalent to doing:
  /// ```dart
  /// switch (sealedClass) {
  ///   case Subclass(:final field):
  ///     return ...;
  ///   case _:
  ///     return null;
  /// }
  /// ```

  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>(
    TResult? Function(
            String id, String cfiPosition, DateTime timestamp, String? label)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _BookmarkEntry() when $default != null:
        return $default(
            _that.id, _that.cfiPosition, _that.timestamp, _that.label);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _BookmarkEntry extends BookmarkEntry {
  const _BookmarkEntry(
      {required this.id,
      required this.cfiPosition,
      required this.timestamp,
      this.label})
      : super._();
  factory _BookmarkEntry.fromJson(Map<String, dynamic> json) =>
      _$BookmarkEntryFromJson(json);

  /// Unique identifier for this bookmark.
  @override
  final String id;

  /// EPUB Canonical Fragment Identifier position string.
  /// Identifies the exact location in the book where this bookmark was created.
  @override
  final String cfiPosition;

  /// Date and time when this bookmark was created.
  @override
  final DateTime timestamp;

  /// Optional user-defined label or note for this bookmark.
  @override
  final String? label;

  /// Create a copy of BookmarkEntry
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$BookmarkEntryCopyWith<_BookmarkEntry> get copyWith =>
      __$BookmarkEntryCopyWithImpl<_BookmarkEntry>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$BookmarkEntryToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _BookmarkEntry &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.cfiPosition, cfiPosition) ||
                other.cfiPosition == cfiPosition) &&
            (identical(other.timestamp, timestamp) ||
                other.timestamp == timestamp) &&
            (identical(other.label, label) || other.label == label));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, id, cfiPosition, timestamp, label);

  @override
  String toString() {
    return 'BookmarkEntry(id: $id, cfiPosition: $cfiPosition, timestamp: $timestamp, label: $label)';
  }
}

/// @nodoc
abstract mixin class _$BookmarkEntryCopyWith<$Res>
    implements $BookmarkEntryCopyWith<$Res> {
  factory _$BookmarkEntryCopyWith(
          _BookmarkEntry value, $Res Function(_BookmarkEntry) _then) =
      __$BookmarkEntryCopyWithImpl;
  @override
  @useResult
  $Res call({String id, String cfiPosition, DateTime timestamp, String? label});
}

/// @nodoc
class __$BookmarkEntryCopyWithImpl<$Res>
    implements _$BookmarkEntryCopyWith<$Res> {
  __$BookmarkEntryCopyWithImpl(this._self, this._then);

  final _BookmarkEntry _self;
  final $Res Function(_BookmarkEntry) _then;

  /// Create a copy of BookmarkEntry
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? id = null,
    Object? cfiPosition = null,
    Object? timestamp = null,
    Object? label = freezed,
  }) {
    return _then(_BookmarkEntry(
      id: null == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      cfiPosition: null == cfiPosition
          ? _self.cfiPosition
          : cfiPosition // ignore: cast_nullable_to_non_nullable
              as String,
      timestamp: null == timestamp
          ? _self.timestamp
          : timestamp // ignore: cast_nullable_to_non_nullable
              as DateTime,
      label: freezed == label
          ? _self.label
          : label // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

// dart format on
