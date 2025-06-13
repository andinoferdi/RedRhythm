import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:pocketbase/pocketbase.dart';
import 'song.dart';
import 'package:flutter/foundation.dart';

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
    debugPrint('🎵 PLAYLIST_MODEL: Parsing record: ${record.id}');
    debugPrint('🎵 PLAYLIST_MODEL: Record data: ${record.data}');
    debugPrint('🎵 PLAYLIST_MODEL: Available fields: ${record.data.keys.toList()}');
    
    // Try different possible field names for songs
    List<String> songs = [];
    if (record.data.containsKey('songs')) {
      songs = List<String>.from(record.data['songs'] ?? []);
      debugPrint('🎵 PLAYLIST_MODEL: Found songs field: $songs');
    } else if (record.data.containsKey('song_ids')) {
      songs = List<String>.from(record.data['song_ids'] ?? []);
      debugPrint('🎵 PLAYLIST_MODEL: Found song_ids field: $songs');
    } else if (record.data.containsKey('tracks')) {
      songs = List<String>.from(record.data['tracks'] ?? []);
      debugPrint('🎵 PLAYLIST_MODEL: Found tracks field: $songs');
    } else {
      debugPrint('🎵 PLAYLIST_MODEL: No songs field found! Available fields: ${record.data.keys.toList()}');
    }
    
    return Playlist(
      id: record.id,
      name: record.data['name'] as String? ?? 'Untitled Playlist',
      userId: record.data['user'] as String? ?? record.data['user_id'] as String? ?? '',
      songs: songs,
      imageUrl: record.data['image_url'] as String? ?? record.data['cover_image'] as String?,
      createdAt: DateTime.parse(record.created),
      updatedAt: DateTime.parse(record.updated),
    );
  }
}
