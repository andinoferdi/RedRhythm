// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'shorts_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

/// @nodoc
mixin _$ShortsState {
  List<Shorts> get shorts => throw _privateConstructorUsedError;
  int get currentIndex => throw _privateConstructorUsedError;
  bool get isLoading => throw _privateConstructorUsedError;
  bool get isLoadingMore => throw _privateConstructorUsedError;
  bool get hasReachedMax => throw _privateConstructorUsedError;
  bool get isPlaying => throw _privateConstructorUsedError;
  bool get isMuted => throw _privateConstructorUsedError;
  double get volume => throw _privateConstructorUsedError;
  String? get error => throw _privateConstructorUsedError;
  Shorts? get currentShort => throw _privateConstructorUsedError;
  String? get currentGenreFilter => throw _privateConstructorUsedError;

  /// Create a copy of ShortsState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ShortsStateCopyWith<ShortsState> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ShortsStateCopyWith<$Res> {
  factory $ShortsStateCopyWith(
          ShortsState value, $Res Function(ShortsState) then) =
      _$ShortsStateCopyWithImpl<$Res, ShortsState>;
  @useResult
  $Res call(
      {List<Shorts> shorts,
      int currentIndex,
      bool isLoading,
      bool isLoadingMore,
      bool hasReachedMax,
      bool isPlaying,
      bool isMuted,
      double volume,
      String? error,
      Shorts? currentShort,
      String? currentGenreFilter});

  $ShortsCopyWith<$Res>? get currentShort;
}

/// @nodoc
class _$ShortsStateCopyWithImpl<$Res, $Val extends ShortsState>
    implements $ShortsStateCopyWith<$Res> {
  _$ShortsStateCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ShortsState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? shorts = null,
    Object? currentIndex = null,
    Object? isLoading = null,
    Object? isLoadingMore = null,
    Object? hasReachedMax = null,
    Object? isPlaying = null,
    Object? isMuted = null,
    Object? volume = null,
    Object? error = freezed,
    Object? currentShort = freezed,
    Object? currentGenreFilter = freezed,
  }) {
    return _then(_value.copyWith(
      shorts: null == shorts
          ? _value.shorts
          : shorts // ignore: cast_nullable_to_non_nullable
              as List<Shorts>,
      currentIndex: null == currentIndex
          ? _value.currentIndex
          : currentIndex // ignore: cast_nullable_to_non_nullable
              as int,
      isLoading: null == isLoading
          ? _value.isLoading
          : isLoading // ignore: cast_nullable_to_non_nullable
              as bool,
      isLoadingMore: null == isLoadingMore
          ? _value.isLoadingMore
          : isLoadingMore // ignore: cast_nullable_to_non_nullable
              as bool,
      hasReachedMax: null == hasReachedMax
          ? _value.hasReachedMax
          : hasReachedMax // ignore: cast_nullable_to_non_nullable
              as bool,
      isPlaying: null == isPlaying
          ? _value.isPlaying
          : isPlaying // ignore: cast_nullable_to_non_nullable
              as bool,
      isMuted: null == isMuted
          ? _value.isMuted
          : isMuted // ignore: cast_nullable_to_non_nullable
              as bool,
      volume: null == volume
          ? _value.volume
          : volume // ignore: cast_nullable_to_non_nullable
              as double,
      error: freezed == error
          ? _value.error
          : error // ignore: cast_nullable_to_non_nullable
              as String?,
      currentShort: freezed == currentShort
          ? _value.currentShort
          : currentShort // ignore: cast_nullable_to_non_nullable
              as Shorts?,
      currentGenreFilter: freezed == currentGenreFilter
          ? _value.currentGenreFilter
          : currentGenreFilter // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }

  /// Create a copy of ShortsState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $ShortsCopyWith<$Res>? get currentShort {
    if (_value.currentShort == null) {
      return null;
    }

    return $ShortsCopyWith<$Res>(_value.currentShort!, (value) {
      return _then(_value.copyWith(currentShort: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$ShortsStateImplCopyWith<$Res>
    implements $ShortsStateCopyWith<$Res> {
  factory _$$ShortsStateImplCopyWith(
          _$ShortsStateImpl value, $Res Function(_$ShortsStateImpl) then) =
      __$$ShortsStateImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {List<Shorts> shorts,
      int currentIndex,
      bool isLoading,
      bool isLoadingMore,
      bool hasReachedMax,
      bool isPlaying,
      bool isMuted,
      double volume,
      String? error,
      Shorts? currentShort,
      String? currentGenreFilter});

  @override
  $ShortsCopyWith<$Res>? get currentShort;
}

/// @nodoc
class __$$ShortsStateImplCopyWithImpl<$Res>
    extends _$ShortsStateCopyWithImpl<$Res, _$ShortsStateImpl>
    implements _$$ShortsStateImplCopyWith<$Res> {
  __$$ShortsStateImplCopyWithImpl(
      _$ShortsStateImpl _value, $Res Function(_$ShortsStateImpl) _then)
      : super(_value, _then);

  /// Create a copy of ShortsState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? shorts = null,
    Object? currentIndex = null,
    Object? isLoading = null,
    Object? isLoadingMore = null,
    Object? hasReachedMax = null,
    Object? isPlaying = null,
    Object? isMuted = null,
    Object? volume = null,
    Object? error = freezed,
    Object? currentShort = freezed,
    Object? currentGenreFilter = freezed,
  }) {
    return _then(_$ShortsStateImpl(
      shorts: null == shorts
          ? _value._shorts
          : shorts // ignore: cast_nullable_to_non_nullable
              as List<Shorts>,
      currentIndex: null == currentIndex
          ? _value.currentIndex
          : currentIndex // ignore: cast_nullable_to_non_nullable
              as int,
      isLoading: null == isLoading
          ? _value.isLoading
          : isLoading // ignore: cast_nullable_to_non_nullable
              as bool,
      isLoadingMore: null == isLoadingMore
          ? _value.isLoadingMore
          : isLoadingMore // ignore: cast_nullable_to_non_nullable
              as bool,
      hasReachedMax: null == hasReachedMax
          ? _value.hasReachedMax
          : hasReachedMax // ignore: cast_nullable_to_non_nullable
              as bool,
      isPlaying: null == isPlaying
          ? _value.isPlaying
          : isPlaying // ignore: cast_nullable_to_non_nullable
              as bool,
      isMuted: null == isMuted
          ? _value.isMuted
          : isMuted // ignore: cast_nullable_to_non_nullable
              as bool,
      volume: null == volume
          ? _value.volume
          : volume // ignore: cast_nullable_to_non_nullable
              as double,
      error: freezed == error
          ? _value.error
          : error // ignore: cast_nullable_to_non_nullable
              as String?,
      currentShort: freezed == currentShort
          ? _value.currentShort
          : currentShort // ignore: cast_nullable_to_non_nullable
              as Shorts?,
      currentGenreFilter: freezed == currentGenreFilter
          ? _value.currentGenreFilter
          : currentGenreFilter // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc

class _$ShortsStateImpl implements _ShortsState {
  const _$ShortsStateImpl(
      {final List<Shorts> shorts = const [],
      this.currentIndex = 0,
      this.isLoading = false,
      this.isLoadingMore = false,
      this.hasReachedMax = false,
      this.isPlaying = false,
      this.isMuted = false,
      this.volume = 1.0,
      this.error,
      this.currentShort,
      this.currentGenreFilter})
      : _shorts = shorts;

  final List<Shorts> _shorts;
  @override
  @JsonKey()
  List<Shorts> get shorts {
    if (_shorts is EqualUnmodifiableListView) return _shorts;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_shorts);
  }

  @override
  @JsonKey()
  final int currentIndex;
  @override
  @JsonKey()
  final bool isLoading;
  @override
  @JsonKey()
  final bool isLoadingMore;
  @override
  @JsonKey()
  final bool hasReachedMax;
  @override
  @JsonKey()
  final bool isPlaying;
  @override
  @JsonKey()
  final bool isMuted;
  @override
  @JsonKey()
  final double volume;
  @override
  final String? error;
  @override
  final Shorts? currentShort;
  @override
  final String? currentGenreFilter;

  @override
  String toString() {
    return 'ShortsState(shorts: $shorts, currentIndex: $currentIndex, isLoading: $isLoading, isLoadingMore: $isLoadingMore, hasReachedMax: $hasReachedMax, isPlaying: $isPlaying, isMuted: $isMuted, volume: $volume, error: $error, currentShort: $currentShort, currentGenreFilter: $currentGenreFilter)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ShortsStateImpl &&
            const DeepCollectionEquality().equals(other._shorts, _shorts) &&
            (identical(other.currentIndex, currentIndex) ||
                other.currentIndex == currentIndex) &&
            (identical(other.isLoading, isLoading) ||
                other.isLoading == isLoading) &&
            (identical(other.isLoadingMore, isLoadingMore) ||
                other.isLoadingMore == isLoadingMore) &&
            (identical(other.hasReachedMax, hasReachedMax) ||
                other.hasReachedMax == hasReachedMax) &&
            (identical(other.isPlaying, isPlaying) ||
                other.isPlaying == isPlaying) &&
            (identical(other.isMuted, isMuted) || other.isMuted == isMuted) &&
            (identical(other.volume, volume) || other.volume == volume) &&
            (identical(other.error, error) || other.error == error) &&
            (identical(other.currentShort, currentShort) ||
                other.currentShort == currentShort) &&
            (identical(other.currentGenreFilter, currentGenreFilter) ||
                other.currentGenreFilter == currentGenreFilter));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(_shorts),
      currentIndex,
      isLoading,
      isLoadingMore,
      hasReachedMax,
      isPlaying,
      isMuted,
      volume,
      error,
      currentShort,
      currentGenreFilter);

  /// Create a copy of ShortsState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ShortsStateImplCopyWith<_$ShortsStateImpl> get copyWith =>
      __$$ShortsStateImplCopyWithImpl<_$ShortsStateImpl>(this, _$identity);
}

abstract class _ShortsState implements ShortsState {
  const factory _ShortsState(
      {final List<Shorts> shorts,
      final int currentIndex,
      final bool isLoading,
      final bool isLoadingMore,
      final bool hasReachedMax,
      final bool isPlaying,
      final bool isMuted,
      final double volume,
      final String? error,
      final Shorts? currentShort,
      final String? currentGenreFilter}) = _$ShortsStateImpl;

  @override
  List<Shorts> get shorts;
  @override
  int get currentIndex;
  @override
  bool get isLoading;
  @override
  bool get isLoadingMore;
  @override
  bool get hasReachedMax;
  @override
  bool get isPlaying;
  @override
  bool get isMuted;
  @override
  double get volume;
  @override
  String? get error;
  @override
  Shorts? get currentShort;
  @override
  String? get currentGenreFilter;

  /// Create a copy of ShortsState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ShortsStateImplCopyWith<_$ShortsStateImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
