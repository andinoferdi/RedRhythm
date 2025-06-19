// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'album_select.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

AlbumSelect _$AlbumSelectFromJson(Map<String, dynamic> json) {
  return _AlbumSelect.fromJson(json);
}

/// @nodoc
mixin _$AlbumSelect {
  String get id => throw _privateConstructorUsedError;
  String get userId => throw _privateConstructorUsedError;
  String get albumId => throw _privateConstructorUsedError;
  DateTime get created => throw _privateConstructorUsedError;
  DateTime get updated =>
      throw _privateConstructorUsedError; // Expanded album data when fetched with expand
  String? get albumTitle => throw _privateConstructorUsedError;
  String? get albumArtistName => throw _privateConstructorUsedError;
  String? get albumCoverImageUrl => throw _privateConstructorUsedError;
  String? get albumArtistId => throw _privateConstructorUsedError;
  int? get albumReleaseYear => throw _privateConstructorUsedError;

  /// Serializes this AlbumSelect to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of AlbumSelect
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $AlbumSelectCopyWith<AlbumSelect> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $AlbumSelectCopyWith<$Res> {
  factory $AlbumSelectCopyWith(
          AlbumSelect value, $Res Function(AlbumSelect) then) =
      _$AlbumSelectCopyWithImpl<$Res, AlbumSelect>;
  @useResult
  $Res call(
      {String id,
      String userId,
      String albumId,
      DateTime created,
      DateTime updated,
      String? albumTitle,
      String? albumArtistName,
      String? albumCoverImageUrl,
      String? albumArtistId,
      int? albumReleaseYear});
}

/// @nodoc
class _$AlbumSelectCopyWithImpl<$Res, $Val extends AlbumSelect>
    implements $AlbumSelectCopyWith<$Res> {
  _$AlbumSelectCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of AlbumSelect
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? albumId = null,
    Object? created = null,
    Object? updated = null,
    Object? albumTitle = freezed,
    Object? albumArtistName = freezed,
    Object? albumCoverImageUrl = freezed,
    Object? albumArtistId = freezed,
    Object? albumReleaseYear = freezed,
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
      albumId: null == albumId
          ? _value.albumId
          : albumId // ignore: cast_nullable_to_non_nullable
              as String,
      created: null == created
          ? _value.created
          : created // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updated: null == updated
          ? _value.updated
          : updated // ignore: cast_nullable_to_non_nullable
              as DateTime,
      albumTitle: freezed == albumTitle
          ? _value.albumTitle
          : albumTitle // ignore: cast_nullable_to_non_nullable
              as String?,
      albumArtistName: freezed == albumArtistName
          ? _value.albumArtistName
          : albumArtistName // ignore: cast_nullable_to_non_nullable
              as String?,
      albumCoverImageUrl: freezed == albumCoverImageUrl
          ? _value.albumCoverImageUrl
          : albumCoverImageUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      albumArtistId: freezed == albumArtistId
          ? _value.albumArtistId
          : albumArtistId // ignore: cast_nullable_to_non_nullable
              as String?,
      albumReleaseYear: freezed == albumReleaseYear
          ? _value.albumReleaseYear
          : albumReleaseYear // ignore: cast_nullable_to_non_nullable
              as int?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$AlbumSelectImplCopyWith<$Res>
    implements $AlbumSelectCopyWith<$Res> {
  factory _$$AlbumSelectImplCopyWith(
          _$AlbumSelectImpl value, $Res Function(_$AlbumSelectImpl) then) =
      __$$AlbumSelectImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String userId,
      String albumId,
      DateTime created,
      DateTime updated,
      String? albumTitle,
      String? albumArtistName,
      String? albumCoverImageUrl,
      String? albumArtistId,
      int? albumReleaseYear});
}

/// @nodoc
class __$$AlbumSelectImplCopyWithImpl<$Res>
    extends _$AlbumSelectCopyWithImpl<$Res, _$AlbumSelectImpl>
    implements _$$AlbumSelectImplCopyWith<$Res> {
  __$$AlbumSelectImplCopyWithImpl(
      _$AlbumSelectImpl _value, $Res Function(_$AlbumSelectImpl) _then)
      : super(_value, _then);

  /// Create a copy of AlbumSelect
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? userId = null,
    Object? albumId = null,
    Object? created = null,
    Object? updated = null,
    Object? albumTitle = freezed,
    Object? albumArtistName = freezed,
    Object? albumCoverImageUrl = freezed,
    Object? albumArtistId = freezed,
    Object? albumReleaseYear = freezed,
  }) {
    return _then(_$AlbumSelectImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      userId: null == userId
          ? _value.userId
          : userId // ignore: cast_nullable_to_non_nullable
              as String,
      albumId: null == albumId
          ? _value.albumId
          : albumId // ignore: cast_nullable_to_non_nullable
              as String,
      created: null == created
          ? _value.created
          : created // ignore: cast_nullable_to_non_nullable
              as DateTime,
      updated: null == updated
          ? _value.updated
          : updated // ignore: cast_nullable_to_non_nullable
              as DateTime,
      albumTitle: freezed == albumTitle
          ? _value.albumTitle
          : albumTitle // ignore: cast_nullable_to_non_nullable
              as String?,
      albumArtistName: freezed == albumArtistName
          ? _value.albumArtistName
          : albumArtistName // ignore: cast_nullable_to_non_nullable
              as String?,
      albumCoverImageUrl: freezed == albumCoverImageUrl
          ? _value.albumCoverImageUrl
          : albumCoverImageUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      albumArtistId: freezed == albumArtistId
          ? _value.albumArtistId
          : albumArtistId // ignore: cast_nullable_to_non_nullable
              as String?,
      albumReleaseYear: freezed == albumReleaseYear
          ? _value.albumReleaseYear
          : albumReleaseYear // ignore: cast_nullable_to_non_nullable
              as int?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$AlbumSelectImpl implements _AlbumSelect {
  const _$AlbumSelectImpl(
      {required this.id,
      required this.userId,
      required this.albumId,
      required this.created,
      required this.updated,
      this.albumTitle,
      this.albumArtistName,
      this.albumCoverImageUrl,
      this.albumArtistId,
      this.albumReleaseYear});

  factory _$AlbumSelectImpl.fromJson(Map<String, dynamic> json) =>
      _$$AlbumSelectImplFromJson(json);

  @override
  final String id;
  @override
  final String userId;
  @override
  final String albumId;
  @override
  final DateTime created;
  @override
  final DateTime updated;
// Expanded album data when fetched with expand
  @override
  final String? albumTitle;
  @override
  final String? albumArtistName;
  @override
  final String? albumCoverImageUrl;
  @override
  final String? albumArtistId;
  @override
  final int? albumReleaseYear;

  @override
  String toString() {
    return 'AlbumSelect(id: $id, userId: $userId, albumId: $albumId, created: $created, updated: $updated, albumTitle: $albumTitle, albumArtistName: $albumArtistName, albumCoverImageUrl: $albumCoverImageUrl, albumArtistId: $albumArtistId, albumReleaseYear: $albumReleaseYear)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$AlbumSelectImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.userId, userId) || other.userId == userId) &&
            (identical(other.albumId, albumId) || other.albumId == albumId) &&
            (identical(other.created, created) || other.created == created) &&
            (identical(other.updated, updated) || other.updated == updated) &&
            (identical(other.albumTitle, albumTitle) ||
                other.albumTitle == albumTitle) &&
            (identical(other.albumArtistName, albumArtistName) ||
                other.albumArtistName == albumArtistName) &&
            (identical(other.albumCoverImageUrl, albumCoverImageUrl) ||
                other.albumCoverImageUrl == albumCoverImageUrl) &&
            (identical(other.albumArtistId, albumArtistId) ||
                other.albumArtistId == albumArtistId) &&
            (identical(other.albumReleaseYear, albumReleaseYear) ||
                other.albumReleaseYear == albumReleaseYear));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      userId,
      albumId,
      created,
      updated,
      albumTitle,
      albumArtistName,
      albumCoverImageUrl,
      albumArtistId,
      albumReleaseYear);

  /// Create a copy of AlbumSelect
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$AlbumSelectImplCopyWith<_$AlbumSelectImpl> get copyWith =>
      __$$AlbumSelectImplCopyWithImpl<_$AlbumSelectImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$AlbumSelectImplToJson(
      this,
    );
  }
}

abstract class _AlbumSelect implements AlbumSelect {
  const factory _AlbumSelect(
      {required final String id,
      required final String userId,
      required final String albumId,
      required final DateTime created,
      required final DateTime updated,
      final String? albumTitle,
      final String? albumArtistName,
      final String? albumCoverImageUrl,
      final String? albumArtistId,
      final int? albumReleaseYear}) = _$AlbumSelectImpl;

  factory _AlbumSelect.fromJson(Map<String, dynamic> json) =
      _$AlbumSelectImpl.fromJson;

  @override
  String get id;
  @override
  String get userId;
  @override
  String get albumId;
  @override
  DateTime get created;
  @override
  DateTime get updated; // Expanded album data when fetched with expand
  @override
  String? get albumTitle;
  @override
  String? get albumArtistName;
  @override
  String? get albumCoverImageUrl;
  @override
  String? get albumArtistId;
  @override
  int? get albumReleaseYear;

  /// Create a copy of AlbumSelect
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$AlbumSelectImplCopyWith<_$AlbumSelectImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
