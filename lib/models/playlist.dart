import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:pocketbase/pocketbase.dart';
import 'song.dart';

part 'playlist.freezed.dart';
part 'playlist.g.dart';

@freezed
class Playlist with _$Playlist {
  const factory Playlist({
    required String id,
    required String name,
    required String userId,
    required List<String> songs,
    String? imageUrl,
    required DateTime createdAt,
    required DateTime updatedAt,
  }) = _Playlist;

  factory Playlist.fromJson(Map<String, dynamic> json) => _$PlaylistFromJson(json);

  factory Playlist.fromRecord(RecordModel record) {
    return Playlist(
      id: record.id,
      name: record.data['name'] as String,
      userId: record.data['user'] as String,
      songs: List<String>.from(record.data['songs'] ?? []),
      imageUrl: record.data['image_url'] as String?,
      createdAt: DateTime.parse(record.created),
      updatedAt: DateTime.parse(record.updated),
    );
  }
}
