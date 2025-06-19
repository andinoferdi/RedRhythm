// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'album_select.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$AlbumSelectImpl _$$AlbumSelectImplFromJson(Map<String, dynamic> json) =>
    _$AlbumSelectImpl(
      id: json['id'] as String,
      userId: json['userId'] as String,
      albumId: json['albumId'] as String,
      created: DateTime.parse(json['created'] as String),
      updated: DateTime.parse(json['updated'] as String),
      albumTitle: json['albumTitle'] as String?,
      albumArtistName: json['albumArtistName'] as String?,
      albumCoverImageUrl: json['albumCoverImageUrl'] as String?,
      albumArtistId: json['albumArtistId'] as String?,
      albumReleaseYear: (json['albumReleaseYear'] as num?)?.toInt(),
    );

Map<String, dynamic> _$$AlbumSelectImplToJson(_$AlbumSelectImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'albumId': instance.albumId,
      'created': instance.created.toIso8601String(),
      'updated': instance.updated.toIso8601String(),
      'albumTitle': instance.albumTitle,
      'albumArtistName': instance.albumArtistName,
      'albumCoverImageUrl': instance.albumCoverImageUrl,
      'albumArtistId': instance.albumArtistId,
      'albumReleaseYear': instance.albumReleaseYear,
    };
