// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'shorts.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$ShortsImpl _$$ShortsImplFromJson(Map<String, dynamic> json) => _$ShortsImpl(
      id: json['id'] as String,
      genresId: json['genresId'] as String,
      videoUrl: json['videoUrl'] as String,
      artistId: json['artistId'] as String,
      songId: json['songId'] as String,
      title: json['title'] as String?,
      hashtags: json['hashtags'] as String?,
      artistName: json['artistName'] as String?,
      songTitle: json['songTitle'] as String?,
      thumbnailUrl: json['thumbnailUrl'] as String?,
      views: (json['views'] as num?)?.toInt() ?? 0,
      likes: (json['likes'] as num?)?.toInt() ?? 0,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
      updatedAt: json['updatedAt'] == null
          ? null
          : DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$$ShortsImplToJson(_$ShortsImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'genresId': instance.genresId,
      'videoUrl': instance.videoUrl,
      'artistId': instance.artistId,
      'songId': instance.songId,
      'title': instance.title,
      'hashtags': instance.hashtags,
      'artistName': instance.artistName,
      'songTitle': instance.songTitle,
      'thumbnailUrl': instance.thumbnailUrl,
      'views': instance.views,
      'likes': instance.likes,
      'createdAt': instance.createdAt?.toIso8601String(),
      'updatedAt': instance.updatedAt?.toIso8601String(),
    };
