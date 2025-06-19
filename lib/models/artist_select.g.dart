// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'artist_select.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ArtistSelectImpl _$$ArtistSelectImplFromJson(Map<String, dynamic> json) =>
    _$ArtistSelectImpl(
      id: json['id'] as String,
      userId: json['userId'] as String,
      artistId: json['artistId'] as String,
      created: DateTime.parse(json['created'] as String),
      updated: DateTime.parse(json['updated'] as String),
      artistName: json['artistName'] as String?,
      artistBio: json['artistBio'] as String?,
      artistImageUrl: json['artistImageUrl'] as String?,
    );

Map<String, dynamic> _$$ArtistSelectImplToJson(_$ArtistSelectImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'userId': instance.userId,
      'artistId': instance.artistId,
      'created': instance.created.toIso8601String(),
      'updated': instance.updated.toIso8601String(),
      'artistName': instance.artistName,
      'artistBio': instance.artistBio,
      'artistImageUrl': instance.artistImageUrl,
    };
