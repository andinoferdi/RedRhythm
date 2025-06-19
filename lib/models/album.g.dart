// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'album.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$AlbumImpl _$$AlbumImplFromJson(Map<String, dynamic> json) => _$AlbumImpl(
      id: json['id'] as String,
      title: json['title'] as String,
      artistName: json['artistName'] as String,
      artistId: json['artistId'] as String,
      coverImageUrl: json['coverImageUrl'] as String?,
      coverImageFilename: json['coverImageFilename'] as String?,
      releaseYear: (json['releaseYear'] as num?)?.toInt() ?? 0,
      description: json['description'] as String?,
      trackCount: (json['trackCount'] as num?)?.toInt() ?? 0,
      created: DateTime.parse(json['created'] as String),
      updated: DateTime.parse(json['updated'] as String),
    );

Map<String, dynamic> _$$AlbumImplToJson(_$AlbumImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'artistName': instance.artistName,
      'artistId': instance.artistId,
      'coverImageUrl': instance.coverImageUrl,
      'coverImageFilename': instance.coverImageFilename,
      'releaseYear': instance.releaseYear,
      'description': instance.description,
      'trackCount': instance.trackCount,
      'created': instance.created.toIso8601String(),
      'updated': instance.updated.toIso8601String(),
    };
