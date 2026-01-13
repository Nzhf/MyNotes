// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'quote_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
  'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models',
);

Quote _$QuoteFromJson(Map<String, dynamic> json) {
  return _Quote.fromJson(json);
}

/// @nodoc
mixin _$Quote {
  /// Unique identifier from API
  String get id => throw _privateConstructorUsedError;

  /// The actual quote text
  String get content => throw _privateConstructorUsedError;

  /// Author of the quote
  String get author => throw _privateConstructorUsedError;

  /// Array of tags (e.g., "inspirational", "wisdom")
  List<String> get tags => throw _privateConstructorUsedError;

  /// Length of the quote in characters
  int get length => throw _privateConstructorUsedError;

  /// Serializes this Quote to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Quote
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $QuoteCopyWith<Quote> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $QuoteCopyWith<$Res> {
  factory $QuoteCopyWith(Quote value, $Res Function(Quote) then) =
      _$QuoteCopyWithImpl<$Res, Quote>;
  @useResult
  $Res call({
    String id,
    String content,
    String author,
    List<String> tags,
    int length,
  });
}

/// @nodoc
class _$QuoteCopyWithImpl<$Res, $Val extends Quote>
    implements $QuoteCopyWith<$Res> {
  _$QuoteCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Quote
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? content = null,
    Object? author = null,
    Object? tags = null,
    Object? length = null,
  }) {
    return _then(
      _value.copyWith(
            id: null == id
                ? _value.id
                : id // ignore: cast_nullable_to_non_nullable
                      as String,
            content: null == content
                ? _value.content
                : content // ignore: cast_nullable_to_non_nullable
                      as String,
            author: null == author
                ? _value.author
                : author // ignore: cast_nullable_to_non_nullable
                      as String,
            tags: null == tags
                ? _value.tags
                : tags // ignore: cast_nullable_to_non_nullable
                      as List<String>,
            length: null == length
                ? _value.length
                : length // ignore: cast_nullable_to_non_nullable
                      as int,
          )
          as $Val,
    );
  }
}

/// @nodoc
abstract class _$$QuoteImplCopyWith<$Res> implements $QuoteCopyWith<$Res> {
  factory _$$QuoteImplCopyWith(
    _$QuoteImpl value,
    $Res Function(_$QuoteImpl) then,
  ) = __$$QuoteImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({
    String id,
    String content,
    String author,
    List<String> tags,
    int length,
  });
}

/// @nodoc
class __$$QuoteImplCopyWithImpl<$Res>
    extends _$QuoteCopyWithImpl<$Res, _$QuoteImpl>
    implements _$$QuoteImplCopyWith<$Res> {
  __$$QuoteImplCopyWithImpl(
    _$QuoteImpl _value,
    $Res Function(_$QuoteImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of Quote
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? content = null,
    Object? author = null,
    Object? tags = null,
    Object? length = null,
  }) {
    return _then(
      _$QuoteImpl(
        id: null == id
            ? _value.id
            : id // ignore: cast_nullable_to_non_nullable
                  as String,
        content: null == content
            ? _value.content
            : content // ignore: cast_nullable_to_non_nullable
                  as String,
        author: null == author
            ? _value.author
            : author // ignore: cast_nullable_to_non_nullable
                  as String,
        tags: null == tags
            ? _value._tags
            : tags // ignore: cast_nullable_to_non_nullable
                  as List<String>,
        length: null == length
            ? _value.length
            : length // ignore: cast_nullable_to_non_nullable
                  as int,
      ),
    );
  }
}

/// @nodoc
@JsonSerializable()
class _$QuoteImpl implements _Quote {
  const _$QuoteImpl({
    required this.id,
    required this.content,
    required this.author,
    final List<String> tags = const [],
    required this.length,
  }) : _tags = tags;

  factory _$QuoteImpl.fromJson(Map<String, dynamic> json) =>
      _$$QuoteImplFromJson(json);

  /// Unique identifier from API
  @override
  final String id;

  /// The actual quote text
  @override
  final String content;

  /// Author of the quote
  @override
  final String author;

  /// Array of tags (e.g., "inspirational", "wisdom")
  final List<String> _tags;

  /// Array of tags (e.g., "inspirational", "wisdom")
  @override
  @JsonKey()
  List<String> get tags {
    if (_tags is EqualUnmodifiableListView) return _tags;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_tags);
  }

  /// Length of the quote in characters
  @override
  final int length;

  @override
  String toString() {
    return 'Quote(id: $id, content: $content, author: $author, tags: $tags, length: $length)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$QuoteImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.content, content) || other.content == content) &&
            (identical(other.author, author) || other.author == author) &&
            const DeepCollectionEquality().equals(other._tags, _tags) &&
            (identical(other.length, length) || other.length == length));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
    runtimeType,
    id,
    content,
    author,
    const DeepCollectionEquality().hash(_tags),
    length,
  );

  /// Create a copy of Quote
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$QuoteImplCopyWith<_$QuoteImpl> get copyWith =>
      __$$QuoteImplCopyWithImpl<_$QuoteImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$QuoteImplToJson(this);
  }
}

abstract class _Quote implements Quote {
  const factory _Quote({
    required final String id,
    required final String content,
    required final String author,
    final List<String> tags,
    required final int length,
  }) = _$QuoteImpl;

  factory _Quote.fromJson(Map<String, dynamic> json) = _$QuoteImpl.fromJson;

  /// Unique identifier from API
  @override
  String get id;

  /// The actual quote text
  @override
  String get content;

  /// Author of the quote
  @override
  String get author;

  /// Array of tags (e.g., "inspirational", "wisdom")
  @override
  List<String> get tags;

  /// Length of the quote in characters
  @override
  int get length;

  /// Create a copy of Quote
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$QuoteImplCopyWith<_$QuoteImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
mixin _$QuoteState {
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function() loading,
    required TResult Function(Quote quote) success,
    required TResult Function(String message) error,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function()? loading,
    TResult? Function(Quote quote)? success,
    TResult? Function(String message)? error,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? loading,
    TResult Function(Quote quote)? success,
    TResult Function(String message)? error,
    required TResult orElse(),
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(QuoteStateInitial value) initial,
    required TResult Function(QuoteStateLoading value) loading,
    required TResult Function(QuoteStateSuccess value) success,
    required TResult Function(QuoteStateError value) error,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(QuoteStateInitial value)? initial,
    TResult? Function(QuoteStateLoading value)? loading,
    TResult? Function(QuoteStateSuccess value)? success,
    TResult? Function(QuoteStateError value)? error,
  }) => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(QuoteStateInitial value)? initial,
    TResult Function(QuoteStateLoading value)? loading,
    TResult Function(QuoteStateSuccess value)? success,
    TResult Function(QuoteStateError value)? error,
    required TResult orElse(),
  }) => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $QuoteStateCopyWith<$Res> {
  factory $QuoteStateCopyWith(
    QuoteState value,
    $Res Function(QuoteState) then,
  ) = _$QuoteStateCopyWithImpl<$Res, QuoteState>;
}

/// @nodoc
class _$QuoteStateCopyWithImpl<$Res, $Val extends QuoteState>
    implements $QuoteStateCopyWith<$Res> {
  _$QuoteStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of QuoteState
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc
abstract class _$$QuoteStateInitialImplCopyWith<$Res> {
  factory _$$QuoteStateInitialImplCopyWith(
    _$QuoteStateInitialImpl value,
    $Res Function(_$QuoteStateInitialImpl) then,
  ) = __$$QuoteStateInitialImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$QuoteStateInitialImplCopyWithImpl<$Res>
    extends _$QuoteStateCopyWithImpl<$Res, _$QuoteStateInitialImpl>
    implements _$$QuoteStateInitialImplCopyWith<$Res> {
  __$$QuoteStateInitialImplCopyWithImpl(
    _$QuoteStateInitialImpl _value,
    $Res Function(_$QuoteStateInitialImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of QuoteState
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$QuoteStateInitialImpl implements QuoteStateInitial {
  const _$QuoteStateInitialImpl();

  @override
  String toString() {
    return 'QuoteState.initial()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _$QuoteStateInitialImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function() loading,
    required TResult Function(Quote quote) success,
    required TResult Function(String message) error,
  }) {
    return initial();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function()? loading,
    TResult? Function(Quote quote)? success,
    TResult? Function(String message)? error,
  }) {
    return initial?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? loading,
    TResult Function(Quote quote)? success,
    TResult Function(String message)? error,
    required TResult orElse(),
  }) {
    if (initial != null) {
      return initial();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(QuoteStateInitial value) initial,
    required TResult Function(QuoteStateLoading value) loading,
    required TResult Function(QuoteStateSuccess value) success,
    required TResult Function(QuoteStateError value) error,
  }) {
    return initial(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(QuoteStateInitial value)? initial,
    TResult? Function(QuoteStateLoading value)? loading,
    TResult? Function(QuoteStateSuccess value)? success,
    TResult? Function(QuoteStateError value)? error,
  }) {
    return initial?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(QuoteStateInitial value)? initial,
    TResult Function(QuoteStateLoading value)? loading,
    TResult Function(QuoteStateSuccess value)? success,
    TResult Function(QuoteStateError value)? error,
    required TResult orElse(),
  }) {
    if (initial != null) {
      return initial(this);
    }
    return orElse();
  }
}

abstract class QuoteStateInitial implements QuoteState {
  const factory QuoteStateInitial() = _$QuoteStateInitialImpl;
}

/// @nodoc
abstract class _$$QuoteStateLoadingImplCopyWith<$Res> {
  factory _$$QuoteStateLoadingImplCopyWith(
    _$QuoteStateLoadingImpl value,
    $Res Function(_$QuoteStateLoadingImpl) then,
  ) = __$$QuoteStateLoadingImplCopyWithImpl<$Res>;
}

/// @nodoc
class __$$QuoteStateLoadingImplCopyWithImpl<$Res>
    extends _$QuoteStateCopyWithImpl<$Res, _$QuoteStateLoadingImpl>
    implements _$$QuoteStateLoadingImplCopyWith<$Res> {
  __$$QuoteStateLoadingImplCopyWithImpl(
    _$QuoteStateLoadingImpl _value,
    $Res Function(_$QuoteStateLoadingImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of QuoteState
  /// with the given fields replaced by the non-null parameter values.
}

/// @nodoc

class _$QuoteStateLoadingImpl implements QuoteStateLoading {
  const _$QuoteStateLoadingImpl();

  @override
  String toString() {
    return 'QuoteState.loading()';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType && other is _$QuoteStateLoadingImpl);
  }

  @override
  int get hashCode => runtimeType.hashCode;

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function() loading,
    required TResult Function(Quote quote) success,
    required TResult Function(String message) error,
  }) {
    return loading();
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function()? loading,
    TResult? Function(Quote quote)? success,
    TResult? Function(String message)? error,
  }) {
    return loading?.call();
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? loading,
    TResult Function(Quote quote)? success,
    TResult Function(String message)? error,
    required TResult orElse(),
  }) {
    if (loading != null) {
      return loading();
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(QuoteStateInitial value) initial,
    required TResult Function(QuoteStateLoading value) loading,
    required TResult Function(QuoteStateSuccess value) success,
    required TResult Function(QuoteStateError value) error,
  }) {
    return loading(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(QuoteStateInitial value)? initial,
    TResult? Function(QuoteStateLoading value)? loading,
    TResult? Function(QuoteStateSuccess value)? success,
    TResult? Function(QuoteStateError value)? error,
  }) {
    return loading?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(QuoteStateInitial value)? initial,
    TResult Function(QuoteStateLoading value)? loading,
    TResult Function(QuoteStateSuccess value)? success,
    TResult Function(QuoteStateError value)? error,
    required TResult orElse(),
  }) {
    if (loading != null) {
      return loading(this);
    }
    return orElse();
  }
}

abstract class QuoteStateLoading implements QuoteState {
  const factory QuoteStateLoading() = _$QuoteStateLoadingImpl;
}

/// @nodoc
abstract class _$$QuoteStateSuccessImplCopyWith<$Res> {
  factory _$$QuoteStateSuccessImplCopyWith(
    _$QuoteStateSuccessImpl value,
    $Res Function(_$QuoteStateSuccessImpl) then,
  ) = __$$QuoteStateSuccessImplCopyWithImpl<$Res>;
  @useResult
  $Res call({Quote quote});

  $QuoteCopyWith<$Res> get quote;
}

/// @nodoc
class __$$QuoteStateSuccessImplCopyWithImpl<$Res>
    extends _$QuoteStateCopyWithImpl<$Res, _$QuoteStateSuccessImpl>
    implements _$$QuoteStateSuccessImplCopyWith<$Res> {
  __$$QuoteStateSuccessImplCopyWithImpl(
    _$QuoteStateSuccessImpl _value,
    $Res Function(_$QuoteStateSuccessImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of QuoteState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? quote = null}) {
    return _then(
      _$QuoteStateSuccessImpl(
        null == quote
            ? _value.quote
            : quote // ignore: cast_nullable_to_non_nullable
                  as Quote,
      ),
    );
  }

  /// Create a copy of QuoteState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $QuoteCopyWith<$Res> get quote {
    return $QuoteCopyWith<$Res>(_value.quote, (value) {
      return _then(_value.copyWith(quote: value));
    });
  }
}

/// @nodoc

class _$QuoteStateSuccessImpl implements QuoteStateSuccess {
  const _$QuoteStateSuccessImpl(this.quote);

  @override
  final Quote quote;

  @override
  String toString() {
    return 'QuoteState.success(quote: $quote)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$QuoteStateSuccessImpl &&
            (identical(other.quote, quote) || other.quote == quote));
  }

  @override
  int get hashCode => Object.hash(runtimeType, quote);

  /// Create a copy of QuoteState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$QuoteStateSuccessImplCopyWith<_$QuoteStateSuccessImpl> get copyWith =>
      __$$QuoteStateSuccessImplCopyWithImpl<_$QuoteStateSuccessImpl>(
        this,
        _$identity,
      );

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function() loading,
    required TResult Function(Quote quote) success,
    required TResult Function(String message) error,
  }) {
    return success(quote);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function()? loading,
    TResult? Function(Quote quote)? success,
    TResult? Function(String message)? error,
  }) {
    return success?.call(quote);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? loading,
    TResult Function(Quote quote)? success,
    TResult Function(String message)? error,
    required TResult orElse(),
  }) {
    if (success != null) {
      return success(quote);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(QuoteStateInitial value) initial,
    required TResult Function(QuoteStateLoading value) loading,
    required TResult Function(QuoteStateSuccess value) success,
    required TResult Function(QuoteStateError value) error,
  }) {
    return success(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(QuoteStateInitial value)? initial,
    TResult? Function(QuoteStateLoading value)? loading,
    TResult? Function(QuoteStateSuccess value)? success,
    TResult? Function(QuoteStateError value)? error,
  }) {
    return success?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(QuoteStateInitial value)? initial,
    TResult Function(QuoteStateLoading value)? loading,
    TResult Function(QuoteStateSuccess value)? success,
    TResult Function(QuoteStateError value)? error,
    required TResult orElse(),
  }) {
    if (success != null) {
      return success(this);
    }
    return orElse();
  }
}

abstract class QuoteStateSuccess implements QuoteState {
  const factory QuoteStateSuccess(final Quote quote) = _$QuoteStateSuccessImpl;

  Quote get quote;

  /// Create a copy of QuoteState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$QuoteStateSuccessImplCopyWith<_$QuoteStateSuccessImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$QuoteStateErrorImplCopyWith<$Res> {
  factory _$$QuoteStateErrorImplCopyWith(
    _$QuoteStateErrorImpl value,
    $Res Function(_$QuoteStateErrorImpl) then,
  ) = __$$QuoteStateErrorImplCopyWithImpl<$Res>;
  @useResult
  $Res call({String message});
}

/// @nodoc
class __$$QuoteStateErrorImplCopyWithImpl<$Res>
    extends _$QuoteStateCopyWithImpl<$Res, _$QuoteStateErrorImpl>
    implements _$$QuoteStateErrorImplCopyWith<$Res> {
  __$$QuoteStateErrorImplCopyWithImpl(
    _$QuoteStateErrorImpl _value,
    $Res Function(_$QuoteStateErrorImpl) _then,
  ) : super(_value, _then);

  /// Create a copy of QuoteState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({Object? message = null}) {
    return _then(
      _$QuoteStateErrorImpl(
        null == message
            ? _value.message
            : message // ignore: cast_nullable_to_non_nullable
                  as String,
      ),
    );
  }
}

/// @nodoc

class _$QuoteStateErrorImpl implements QuoteStateError {
  const _$QuoteStateErrorImpl(this.message);

  @override
  final String message;

  @override
  String toString() {
    return 'QuoteState.error(message: $message)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$QuoteStateErrorImpl &&
            (identical(other.message, message) || other.message == message));
  }

  @override
  int get hashCode => Object.hash(runtimeType, message);

  /// Create a copy of QuoteState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$QuoteStateErrorImplCopyWith<_$QuoteStateErrorImpl> get copyWith =>
      __$$QuoteStateErrorImplCopyWithImpl<_$QuoteStateErrorImpl>(
        this,
        _$identity,
      );

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function() initial,
    required TResult Function() loading,
    required TResult Function(Quote quote) success,
    required TResult Function(String message) error,
  }) {
    return error(message);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function()? initial,
    TResult? Function()? loading,
    TResult? Function(Quote quote)? success,
    TResult? Function(String message)? error,
  }) {
    return error?.call(message);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function()? initial,
    TResult Function()? loading,
    TResult Function(Quote quote)? success,
    TResult Function(String message)? error,
    required TResult orElse(),
  }) {
    if (error != null) {
      return error(message);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(QuoteStateInitial value) initial,
    required TResult Function(QuoteStateLoading value) loading,
    required TResult Function(QuoteStateSuccess value) success,
    required TResult Function(QuoteStateError value) error,
  }) {
    return error(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(QuoteStateInitial value)? initial,
    TResult? Function(QuoteStateLoading value)? loading,
    TResult? Function(QuoteStateSuccess value)? success,
    TResult? Function(QuoteStateError value)? error,
  }) {
    return error?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(QuoteStateInitial value)? initial,
    TResult Function(QuoteStateLoading value)? loading,
    TResult Function(QuoteStateSuccess value)? success,
    TResult Function(QuoteStateError value)? error,
    required TResult orElse(),
  }) {
    if (error != null) {
      return error(this);
    }
    return orElse();
  }
}

abstract class QuoteStateError implements QuoteState {
  const factory QuoteStateError(final String message) = _$QuoteStateErrorImpl;

  String get message;

  /// Create a copy of QuoteState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$QuoteStateErrorImplCopyWith<_$QuoteStateErrorImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
