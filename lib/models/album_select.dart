import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:pocketbase/pocketbase.dart';

part 'album_select.freezed.dart';
part 'album_select.g.dart';

@freezed
class AlbumSelect with _$AlbumSelect {
  const factory AlbumSelect({
    required String id,
    required String userId,
    required String albumId,
    required DateTime created,
    required DateTime updated,
    // Expanded album data when fetched with expand
    String? albumTitle,
    String? albumArtistName,
    String? albumCoverImageUrl,
    String? albumArtistId,
    int? albumReleaseYear,
  }) = _AlbumSelect;

  factory AlbumSelect.fromJson(Map<String, dynamic> json) =>
      _$AlbumSelectFromJson(json);

  factory AlbumSelect.fromRecord(RecordModel record, [PocketBase? pb]) {
    // Handle expanded album data
    String? albumTitle;
    String? albumArtistName;
    String? albumCoverImageUrl;
    String? albumArtistId;
    int? albumReleaseYear;
    
    if (record.expand.containsKey('album_id')) {
      final albumData = record.expand['album_id'];
      if (albumData is List && albumData?.isNotEmpty == true) {
        final album = albumData?.first;
        if (album is RecordModel) {
          albumTitle = album.data['title']?.toString();
          albumArtistId = album.data['artist_id']?.toString();
          
          // First try to get artist name from album's artist_name field
          albumArtistName = album.data['artist_name']?.toString();
          
          // If artist_name is not available, try to get it from expanded artist data
          if ((albumArtistName == null || albumArtistName.isEmpty) && album.expand.containsKey('artist_id')) {
            final artistData = album.expand['artist_id'];
            if (artistData is List && artistData?.isNotEmpty == true) {
              final artist = artistData?.first;
              if (artist is RecordModel) {
                albumArtistName = artist.data['name']?.toString();
              }
            }
          }
          
          // Handle release year
          final releaseYearData = album.data['release_year'];
          if (releaseYearData != null) {
            albumReleaseYear = int.tryParse(releaseYearData.toString());
          }
          
          // Generate cover image URL properly like in Album model
          if (album.data['cover_image'] != null && album.data['cover_image'].toString().isNotEmpty && pb != null) {
            try {
              albumCoverImageUrl = pb.files.getUrl(album, album.data['cover_image']).toString();
            } catch (e) {
              albumCoverImageUrl = null;
            }
          }
        }
      }
    }
    
    return AlbumSelect(
      id: record.id,
      userId: record.data['user_id']?.toString() ?? '',
      albumId: record.data['album_id']?.toString() ?? '',
      created: DateTime.parse(record.created),
      updated: DateTime.parse(record.updated),
      albumTitle: albumTitle,
      albumArtistName: albumArtistName,
      albumCoverImageUrl: albumCoverImageUrl,
      albumArtistId: albumArtistId,
      albumReleaseYear: albumReleaseYear,
    );
  }
} 