// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'reading_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ReadingState {
  /// EPUB Canonical Fragment Identifier position string.
  /// Identifies the exact location in the book (chapter/paragraph/etc).
  String get cfiPosition;

  /// Reading progress as a percentage (0.0 to 100.0).
  double get progress;

  /// Date and time of the last reading session.
  DateTime get lastReadTime;

  /// Total seconds spent reading this book.
  int get totalSeconds;

  /// Create a copy of ReadingState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $ReadingStateCopyWith<ReadingState> get copyWith =>
      _$ReadingStateCopyWithImpl<ReadingState>(
          this as ReadingState, _$identity);

  /// Serializes this ReadingState to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is ReadingState &&
            (identical(other.cfiPosition, cfiPosition) ||
                other.cfiPosition == cfiPosition) &&
            (identical(other.progress, progress) ||
                other.progress == progress) &&
            (identical(other.lastReadTime, lastReadTime) ||
                other.lastReadTime == lastReadTime) &&
            (identical(other.totalSeconds, totalSeconds) ||
                other.totalSeconds == totalSeconds));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, cfiPosition, progress, lastReadTime, totalSeconds);

  @override
  String toString() {
    return 'ReadingState(cfiPosition: $cfiPosition, progress: $progress, lastReadTime: $lastReadTime, totalSeconds: $totalSeconds)';
  }
}

/// @nodoc
abstract mixin class $ReadingStateCopyWith<$Res> {
  factory $ReadingStateCopyWith(
          ReadingState value, $Res Function(ReadingState) _then) =
      _$ReadingStateCopyWithImpl;
  @useResult
  $Res call(
      {String cfiPosition,
      double progress,
      DateTime lastReadTime,
      int totalSeconds});
}

/// @nodoc
class _$ReadingStateCopyWithImpl<$Res> implements $ReadingStateCopyWith<$Res> {
  _$ReadingStateCopyWithImpl(this._self, this._then);

  final ReadingState _self;
  final $Res Function(ReadingState) _then;

  /// Create a copy of ReadingState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? cfiPosition = null,
    Object? progress = null,
    Object? lastReadTime = null,
    Object? totalSeconds = null,
  }) {
    return _then(_self.copyWith(
      cfiPosition: null == cfiPosition
          ? _self.cfiPosition
          : cfiPosition // ignore: cast_nullable_to_non_nullable
              as String,
      progress: null == progress
          ? _self.progress
          : progress // ignore: cast_nullable_to_non_nullable
              as double,
      lastReadTime: null == lastReadTime
          ? _self.lastReadTime
          : lastReadTime // ignore: cast_nullable_to_non_nullable
              as DateTime,
      totalSeconds: null == totalSeconds
          ? _self.totalSeconds
          : totalSeconds // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// Adds pattern-matching-related methods to [ReadingState].
extension ReadingStatePatterns on ReadingState {
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
    TResult Function(_ReadingState value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _ReadingState() when $default != null:
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
    TResult Function(_ReadingState value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ReadingState():
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
    TResult? Function(_ReadingState value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ReadingState() when $default != null:
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
    TResult Function(String cfiPosition, double progress, DateTime lastReadTime,
            int totalSeconds)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _ReadingState() when $default != null:
        return $default(_that.cfiPosition, _that.progress, _that.lastReadTime,
            _that.totalSeconds);
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
    TResult Function(String cfiPosition, double progress, DateTime lastReadTime,
            int totalSeconds)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ReadingState():
        return $default(_that.cfiPosition, _that.progress, _that.lastReadTime,
            _that.totalSeconds);
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
    TResult? Function(String cfiPosition, double progress,
            DateTime lastReadTime, int totalSeconds)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _ReadingState() when $default != null:
        return $default(_that.cfiPosition, _that.progress, _that.lastReadTime,
            _that.totalSeconds);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _ReadingState extends ReadingState {
  const _ReadingState(
      {required this.cfiPosition,
      required this.progress,
      required this.lastReadTime,
      required this.totalSeconds})
      : super._();
  factory _ReadingState.fromJson(Map<String, dynamic> json) =>
      _$ReadingStateFromJson(json);

  /// EPUB Canonical Fragment Identifier position string.
  /// Identifies the exact location in the book (chapter/paragraph/etc).
  @override
  final String cfiPosition;

  /// Reading progress as a percentage (0.0 to 100.0).
  @override
  final double progress;

  /// Date and time of the last reading session.
  @override
  final DateTime lastReadTime;

  /// Total seconds spent reading this book.
  @override
  final int totalSeconds;

  /// Create a copy of ReadingState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$ReadingStateCopyWith<_ReadingState> get copyWith =>
      __$ReadingStateCopyWithImpl<_ReadingState>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$ReadingStateToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _ReadingState &&
            (identical(other.cfiPosition, cfiPosition) ||
                other.cfiPosition == cfiPosition) &&
            (identical(other.progress, progress) ||
                other.progress == progress) &&
            (identical(other.lastReadTime, lastReadTime) ||
                other.lastReadTime == lastReadTime) &&
            (identical(other.totalSeconds, totalSeconds) ||
                other.totalSeconds == totalSeconds));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, cfiPosition, progress, lastReadTime, totalSeconds);

  @override
  String toString() {
    return 'ReadingState(cfiPosition: $cfiPosition, progress: $progress, lastReadTime: $lastReadTime, totalSeconds: $totalSeconds)';
  }
}

/// @nodoc
abstract mixin class _$ReadingStateCopyWith<$Res>
    implements $ReadingStateCopyWith<$Res> {
  factory _$ReadingStateCopyWith(
          _ReadingState value, $Res Function(_ReadingState) _then) =
      __$ReadingStateCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String cfiPosition,
      double progress,
      DateTime lastReadTime,
      int totalSeconds});
}

/// @nodoc
class __$ReadingStateCopyWithImpl<$Res>
    implements _$ReadingStateCopyWith<$Res> {
  __$ReadingStateCopyWithImpl(this._self, this._then);

  final _ReadingState _self;
  final $Res Function(_ReadingState) _then;

  /// Create a copy of ReadingState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? cfiPosition = null,
    Object? progress = null,
    Object? lastReadTime = null,
    Object? totalSeconds = null,
  }) {
    return _then(_ReadingState(
      cfiPosition: null == cfiPosition
          ? _self.cfiPosition
          : cfiPosition // ignore: cast_nullable_to_non_nullable
              as String,
      progress: null == progress
          ? _self.progress
          : progress // ignore: cast_nullable_to_non_nullable
              as double,
      lastReadTime: null == lastReadTime
          ? _self.lastReadTime
          : lastReadTime // ignore: cast_nullable_to_non_nullable
              as DateTime,
      totalSeconds: null == totalSeconds
          ? _self.totalSeconds
          : totalSeconds // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

// dart format on
