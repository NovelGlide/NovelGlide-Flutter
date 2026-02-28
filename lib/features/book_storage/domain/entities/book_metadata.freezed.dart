// GENERATED CODE - DO NOT MODIFY BY HAND
// coverage:ignore-file
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'book_metadata.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BookMetadata {
  /// Original filename as it was when the book was added to the library.
  /// Used for display purposes only — has no structural role.
  String get originalFilename;

  /// The title of the book.
  String get title;

  /// Date and time when the book was added to the library.
  DateTime get dateAdded;

  /// Current reading state (position, progress, last read time, etc).
  /// Updated silently when the reader closes the book.
  ReadingState get readingState;

  /// List of user-created bookmarks in this book.
  List<BookmarkEntry> get bookmarks;

  /// Create a copy of BookMetadata
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $BookMetadataCopyWith<BookMetadata> get copyWith =>
      _$BookMetadataCopyWithImpl<BookMetadata>(
          this as BookMetadata, _$identity);

  /// Serializes this BookMetadata to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is BookMetadata &&
            (identical(other.originalFilename, originalFilename) ||
                other.originalFilename == originalFilename) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.dateAdded, dateAdded) ||
                other.dateAdded == dateAdded) &&
            (identical(other.readingState, readingState) ||
                other.readingState == readingState) &&
            const DeepCollectionEquality().equals(other.bookmarks, bookmarks));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, originalFilename, title,
      dateAdded, readingState, const DeepCollectionEquality().hash(bookmarks));

  @override
  String toString() {
    return 'BookMetadata(originalFilename: $originalFilename, title: $title, dateAdded: $dateAdded, readingState: $readingState, bookmarks: $bookmarks)';
  }
}

/// @nodoc
abstract mixin class $BookMetadataCopyWith<$Res> {
  factory $BookMetadataCopyWith(
          BookMetadata value, $Res Function(BookMetadata) _then) =
      _$BookMetadataCopyWithImpl;
  @useResult
  $Res call(
      {String originalFilename,
      String title,
      DateTime dateAdded,
      ReadingState readingState,
      List<BookmarkEntry> bookmarks});

  $ReadingStateCopyWith<$Res> get readingState;
}

/// @nodoc
class _$BookMetadataCopyWithImpl<$Res> implements $BookMetadataCopyWith<$Res> {
  _$BookMetadataCopyWithImpl(this._self, this._then);

  final BookMetadata _self;
  final $Res Function(BookMetadata) _then;

  /// Create a copy of BookMetadata
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? originalFilename = null,
    Object? title = null,
    Object? dateAdded = null,
    Object? readingState = null,
    Object? bookmarks = null,
  }) {
    return _then(_self.copyWith(
      originalFilename: null == originalFilename
          ? _self.originalFilename
          : originalFilename // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _self.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      dateAdded: null == dateAdded
          ? _self.dateAdded
          : dateAdded // ignore: cast_nullable_to_non_nullable
              as DateTime,
      readingState: null == readingState
          ? _self.readingState
          : readingState // ignore: cast_nullable_to_non_nullable
              as ReadingState,
      bookmarks: null == bookmarks
          ? _self.bookmarks
          : bookmarks // ignore: cast_nullable_to_non_nullable
              as List<BookmarkEntry>,
    ));
  }

  /// Create a copy of BookMetadata
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $ReadingStateCopyWith<$Res> get readingState {
    return $ReadingStateCopyWith<$Res>(_self.readingState, (value) {
      return _then(_self.copyWith(readingState: value));
    });
  }
}

/// Adds pattern-matching-related methods to [BookMetadata].
extension BookMetadataPatterns on BookMetadata {
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
    TResult Function(_BookMetadata value)? $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _BookMetadata() when $default != null:
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
    TResult Function(_BookMetadata value) $default,
  ) {
    final _that = this;
    switch (_that) {
      case _BookMetadata():
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
    TResult? Function(_BookMetadata value)? $default,
  ) {
    final _that = this;
    switch (_that) {
      case _BookMetadata() when $default != null:
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
    TResult Function(String originalFilename, String title, DateTime dateAdded,
            ReadingState readingState, List<BookmarkEntry> bookmarks)?
        $default, {
    required TResult orElse(),
  }) {
    final _that = this;
    switch (_that) {
      case _BookMetadata() when $default != null:
        return $default(_that.originalFilename, _that.title, _that.dateAdded,
            _that.readingState, _that.bookmarks);
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
    TResult Function(String originalFilename, String title, DateTime dateAdded,
            ReadingState readingState, List<BookmarkEntry> bookmarks)
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _BookMetadata():
        return $default(_that.originalFilename, _that.title, _that.dateAdded,
            _that.readingState, _that.bookmarks);
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
    TResult? Function(String originalFilename, String title, DateTime dateAdded,
            ReadingState readingState, List<BookmarkEntry> bookmarks)?
        $default,
  ) {
    final _that = this;
    switch (_that) {
      case _BookMetadata() when $default != null:
        return $default(_that.originalFilename, _that.title, _that.dateAdded,
            _that.readingState, _that.bookmarks);
      case _:
        return null;
    }
  }
}

/// @nodoc
@JsonSerializable()
class _BookMetadata extends BookMetadata {
  const _BookMetadata(
      {required this.originalFilename,
      required this.title,
      required this.dateAdded,
      required this.readingState,
      required final List<BookmarkEntry> bookmarks})
      : _bookmarks = bookmarks,
        super._();
  factory _BookMetadata.fromJson(Map<String, dynamic> json) =>
      _$BookMetadataFromJson(json);

  /// Original filename as it was when the book was added to the library.
  /// Used for display purposes only — has no structural role.
  @override
  final String originalFilename;

  /// The title of the book.
  @override
  final String title;

  /// Date and time when the book was added to the library.
  @override
  final DateTime dateAdded;

  /// Current reading state (position, progress, last read time, etc).
  /// Updated silently when the reader closes the book.
  @override
  final ReadingState readingState;

  /// List of user-created bookmarks in this book.
  final List<BookmarkEntry> _bookmarks;

  /// List of user-created bookmarks in this book.
  @override
  List<BookmarkEntry> get bookmarks {
    if (_bookmarks is EqualUnmodifiableListView) return _bookmarks;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_bookmarks);
  }

  /// Create a copy of BookMetadata
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$BookMetadataCopyWith<_BookMetadata> get copyWith =>
      __$BookMetadataCopyWithImpl<_BookMetadata>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$BookMetadataToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _BookMetadata &&
            (identical(other.originalFilename, originalFilename) ||
                other.originalFilename == originalFilename) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.dateAdded, dateAdded) ||
                other.dateAdded == dateAdded) &&
            (identical(other.readingState, readingState) ||
                other.readingState == readingState) &&
            const DeepCollectionEquality()
                .equals(other._bookmarks, _bookmarks));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, originalFilename, title,
      dateAdded, readingState, const DeepCollectionEquality().hash(_bookmarks));

  @override
  String toString() {
    return 'BookMetadata(originalFilename: $originalFilename, title: $title, dateAdded: $dateAdded, readingState: $readingState, bookmarks: $bookmarks)';
  }
}

/// @nodoc
abstract mixin class _$BookMetadataCopyWith<$Res>
    implements $BookMetadataCopyWith<$Res> {
  factory _$BookMetadataCopyWith(
          _BookMetadata value, $Res Function(_BookMetadata) _then) =
      __$BookMetadataCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String originalFilename,
      String title,
      DateTime dateAdded,
      ReadingState readingState,
      List<BookmarkEntry> bookmarks});

  @override
  $ReadingStateCopyWith<$Res> get readingState;
}

/// @nodoc
class __$BookMetadataCopyWithImpl<$Res>
    implements _$BookMetadataCopyWith<$Res> {
  __$BookMetadataCopyWithImpl(this._self, this._then);

  final _BookMetadata _self;
  final $Res Function(_BookMetadata) _then;

  /// Create a copy of BookMetadata
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? originalFilename = null,
    Object? title = null,
    Object? dateAdded = null,
    Object? readingState = null,
    Object? bookmarks = null,
  }) {
    return _then(_BookMetadata(
      originalFilename: null == originalFilename
          ? _self.originalFilename
          : originalFilename // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _self.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      dateAdded: null == dateAdded
          ? _self.dateAdded
          : dateAdded // ignore: cast_nullable_to_non_nullable
              as DateTime,
      readingState: null == readingState
          ? _self.readingState
          : readingState // ignore: cast_nullable_to_non_nullable
              as ReadingState,
      bookmarks: null == bookmarks
          ? _self._bookmarks
          : bookmarks // ignore: cast_nullable_to_non_nullable
              as List<BookmarkEntry>,
    ));
  }

  /// Create a copy of BookMetadata
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $ReadingStateCopyWith<$Res> get readingState {
    return $ReadingStateCopyWith<$Res>(_self.readingState, (value) {
      return _then(_self.copyWith(readingState: value));
    });
  }
}

// dart format on
