// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'favorite.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

Favorite _$FavoriteFromJson(Map<String, dynamic> json) {
  return _Favorite.fromJson(json);
}

/// @nodoc
mixin _$Favorite {
  String get id => throw _privateConstructorUsedError;
  String get userId => throw _privateConstructorUsedError;
  String get songId => throw _privateConstructorUsedError;
  DateTime get createdAt => throw _privateConstructorUsedError;

  /// Serializes this Favorite to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of Favorite
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $FavoriteCopyWith<Favorite> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $FavoriteCopyWith<$Res> {
  factory $FavoriteCopyWith(Favorite value, $Res Function(Favorite) then) =
      _$FavoriteCopyWithImpl<$Res, Favorite>;
  @useResult
  $Res call({String id, String userId, String songId, DateTime createdAt});
}

/// @nodoc
class _$FavoriteCopyWithImpl<$Res, $Val extends Favorite>
    implements $FavoriteCopyWith<$Res> {
  _$FavoriteCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of Favorite
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? songId = null,
    Object? createdAt = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      songId: null == songId
          ? _value.songId
          : songId // ignore: cast_nullable_to_non_nullable
              as String,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$FavoriteImplCopyWith<$Res>
    implements $FavoriteCopyWith<$Res> {
  factory _$$FavoriteImplCopyWith(
          _$FavoriteImpl value, $Res Function(_$FavoriteImpl) then) =
      __$$FavoriteImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String id, String userId, String songId, DateTime createdAt});
}

/// @nodoc
class __$$FavoriteImplCopyWithImpl<$Res>
    extends _$FavoriteCopyWithImpl<$Res, _$FavoriteImpl>
    implements _$$FavoriteImplCopyWith<$Res> {
  __$$FavoriteImplCopyWithImpl(
      _$FavoriteImpl _value, $Res Function(_$FavoriteImpl) _then)
      : super(_value, _then);

  /// Create a copy of Favorite
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? songId = null,
    Object? createdAt = null,
  }) {
    return _then(_$FavoriteImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      songId: null == songId
          ? _value.songId
          : songId // ignore: cast_nullable_to_non_nullable
              as String,
      createdAt: null == createdAt
          ? _value.createdAt
          : createdAt // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$FavoriteImpl implements _Favorite {
  const _$FavoriteImpl(
      {required this.id,
      required this.userId,
      required this.songId,
      required this.createdAt});

  factory _$FavoriteImpl.fromJson(Map<String, dynamic> json) =>
      _$$FavoriteImplFromJson(json);

  @override
  final String id;
  @override
  final String userId;
  @override
  final String songId;
  @override
  final DateTime createdAt;

  @override
  String toString() {
    return 'Favorite(id: $id, userId: $userId, songId: $songId, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$FavoriteImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.songId, songId) || other.songId == songId) &&
            (identical(other.createdAt, createdAt) ||
                other.createdAt == createdAt));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, userId, songId, createdAt);

  /// Create a copy of Favorite
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$FavoriteImplCopyWith<_$FavoriteImpl> get copyWith =>
      __$$FavoriteImplCopyWithImpl<_$FavoriteImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$FavoriteImplToJson(
      this,
    );
  }
}

abstract class _Favorite implements Favorite {
  const factory _Favorite(
      {required final String id,
      required final String userId,
      required final String songId,
      required final DateTime createdAt}) = _$FavoriteImpl;

  factory _Favorite.fromJson(Map<String, dynamic> json) =
      _$FavoriteImpl.fromJson;

  @override
  String get id;
  @override
  String get userId;
  @override
  String get songId;
  @override
  DateTime get createdAt;

  /// Create a copy of Favorite
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$FavoriteImplCopyWith<_$FavoriteImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
