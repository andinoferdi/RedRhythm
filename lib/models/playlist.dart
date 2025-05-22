import 'package:pocketbase/pocketbase.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'song.dart';

part 'playlist.freezed.dart';
part 'playlist.g.dart';

@freezed
class Playlist with _$Playlist {
  const factory Playlist({
    required String id,
    required String name,
    required String coverImageUrl,
    required List<Song> songs,
    String? description,
    @Default(false) bool isPublic,
  }) = _Playlist;

  factory Playlist.fromJson(Map<String, dynamic> json) => _$PlaylistFromJson(json);
  
  /// Create a Playlist from a PocketBase record
  static Playlist fromRecord(RecordModel record, {List<Song> songs = const []}) {
    return Playlist(
      id: record.id,
      name: record.data['name'] as String? ?? 'Unknown Playlist',
      coverImageUrl: record.data['cover_image'] as String? ?? '',
      description: record.data['description'] as String?,
      isPublic: record.data['is_public'] as bool? ?? false,
      songs: songs,
    );
  }
} 