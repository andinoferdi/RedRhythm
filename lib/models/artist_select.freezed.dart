// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'artist_select.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

ArtistSelect _$ArtistSelectFromJson(Map<String, dynamic> json) {
  return _ArtistSelect.fromJson(json);
}

/// @nodoc
mixin _$ArtistSelect {
  String get id => throw _privateConstructorUsedError;
  String get userId => throw _privateConstructorUsedError;
  String get artistId => throw _privateConstructorUsedError;
  DateTime get created => throw _privateConstructorUsedError;
  DateTime get updated =>
      throw _privateConstructorUsedError; // Expanded artist data when fetched with expand
  String? get artistName => throw _privateConstructorUsedError;
  String? get artistBio => throw _privateConstructorUsedError;
  String? get artistImageUrl => throw _privateConstructorUsedError;

  /// Serializes this ArtistSelect to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of ArtistSelect
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $ArtistSelectCopyWith<ArtistSelect> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ArtistSelectCopyWith<$Res> {
  factory $ArtistSelectCopyWith(
          ArtistSelect value, $Res Function(ArtistSelect) then) =
      _$ArtistSelectCopyWithImpl<$Res, ArtistSelect>;
  @useResult
  $Res call(
      {String id,
      String userId,
      String artistId,
      DateTime created,
      DateTime updated,
      String? artistName,
      String? artistBio,
      String? artistImageUrl});
}

/// @nodoc
class _$ArtistSelectCopyWithImpl<$Res, $Val extends ArtistSelect>
    implements $ArtistSelectCopyWith<$Res> {
  _$ArtistSelectCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of ArtistSelect
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? artistId = null,
    Object? created = null,
    Object? updated = null,
    Object? artistName = freezed,
    Object? artistBio = freezed,
    Object? artistImageUrl = freezed,
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
      artistId: null == artistId
          ? _value.artistId
          : artistId // ignore: cast_nullable_to_non_nullable
              as String,
      created: null == created
          ? _value.created
          : created // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updated: null == updated
          ? _value.updated
          : updated // ignore: cast_nullable_to_non_nullable
              as DateTime,
      artistName: freezed == artistName
          ? _value.artistName
          : artistName // ignore: cast_nullable_to_non_nullable
              as String?,
      artistBio: freezed == artistBio
          ? _value.artistBio
          : artistBio // ignore: cast_nullable_to_non_nullable
              as String?,
      artistImageUrl: freezed == artistImageUrl
          ? _value.artistImageUrl
          : artistImageUrl // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ArtistSelectImplCopyWith<$Res>
    implements $ArtistSelectCopyWith<$Res> {
  factory _$$ArtistSelectImplCopyWith(
          _$ArtistSelectImpl value, $Res Function(_$ArtistSelectImpl) then) =
      __$$ArtistSelectImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String userId,
      String artistId,
      DateTime created,
      DateTime updated,
      String? artistName,
      String? artistBio,
      String? artistImageUrl});
}

/// @nodoc
class __$$ArtistSelectImplCopyWithImpl<$Res>
    extends _$ArtistSelectCopyWithImpl<$Res, _$ArtistSelectImpl>
    implements _$$ArtistSelectImplCopyWith<$Res> {
  __$$ArtistSelectImplCopyWithImpl(
      _$ArtistSelectImpl _value, $Res Function(_$ArtistSelectImpl) _then)
      : super(_value, _then);

  /// Create a copy of ArtistSelect
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? artistId = null,
    Object? created = null,
    Object? updated = null,
    Object? artistName = freezed,
    Object? artistBio = freezed,
    Object? artistImageUrl = freezed,
  }) {
    return _then(_$ArtistSelectImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      artistId: null == artistId
          ? _value.artistId
          : artistId // ignore: cast_nullable_to_non_nullable
              as String,
      created: null == created
          ? _value.created
          : created // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updated: null == updated
          ? _value.updated
          : updated // ignore: cast_nullable_to_non_nullable
              as DateTime,
      artistName: freezed == artistName
          ? _value.artistName
          : artistName // ignore: cast_nullable_to_non_nullable
              as String?,
      artistBio: freezed == artistBio
          ? _value.artistBio
          : artistBio // ignore: cast_nullable_to_non_nullable
              as String?,
      artistImageUrl: freezed == artistImageUrl
          ? _value.artistImageUrl
          : artistImageUrl // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ArtistSelectImpl implements _ArtistSelect {
  const _$ArtistSelectImpl(
      {required this.id,
      required this.userId,
      required this.artistId,
      required this.created,
      required this.updated,
      this.artistName,
      this.artistBio,
      this.artistImageUrl});

  factory _$ArtistSelectImpl.fromJson(Map<String, dynamic> json) =>
      _$$ArtistSelectImplFromJson(json);

  @override
  final String id;
  @override
  final String userId;
  @override
  final String artistId;
  @override
  final DateTime created;
  @override
  final DateTime updated;
// Expanded artist data when fetched with expand
  @override
  final String? artistName;
  @override
  final String? artistBio;
  @override
  final String? artistImageUrl;

  @override
  String toString() {
    return 'ArtistSelect(id: $id, userId: $userId, artistId: $artistId, created: $created, updated: $updated, artistName: $artistName, artistBio: $artistBio, artistImageUrl: $artistImageUrl)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ArtistSelectImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.artistId, artistId) ||
                other.artistId == artistId) &&
            (identical(other.created, created) || other.created == created) &&
            (identical(other.updated, updated) || other.updated == updated) &&
            (identical(other.artistName, artistName) ||
                other.artistName == artistName) &&
            (identical(other.artistBio, artistBio) ||
                other.artistBio == artistBio) &&
            (identical(other.artistImageUrl, artistImageUrl) ||
                other.artistImageUrl == artistImageUrl));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, userId, artistId, created,
      updated, artistName, artistBio, artistImageUrl);

  /// Create a copy of ArtistSelect
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$ArtistSelectImplCopyWith<_$ArtistSelectImpl> get copyWith =>
      __$$ArtistSelectImplCopyWithImpl<_$ArtistSelectImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ArtistSelectImplToJson(
      this,
    );
  }
}

abstract class _ArtistSelect implements ArtistSelect {
  const factory _ArtistSelect(
      {required final String id,
      required final String userId,
      required final String artistId,
      required final DateTime created,
      required final DateTime updated,
      final String? artistName,
      final String? artistBio,
      final String? artistImageUrl}) = _$ArtistSelectImpl;

  factory _ArtistSelect.fromJson(Map<String, dynamic> json) =
      _$ArtistSelectImpl.fromJson;

  @override
  String get id;
  @override
  String get userId;
  @override
  String get artistId;
  @override
  DateTime get created;
  @override
  DateTime get updated; // Expanded artist data when fetched with expand
  @override
  String? get artistName;
  @override
  String? get artistBio;
  @override
  String? get artistImageUrl;

  /// Create a copy of ArtistSelect
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$ArtistSelectImplCopyWith<_$ArtistSelectImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
