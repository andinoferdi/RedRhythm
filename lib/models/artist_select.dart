import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:pocketbase/pocketbase.dart';

part 'artist_select.freezed.dart';
part 'artist_select.g.dart';

@freezed
class ArtistSelect with _$ArtistSelect {
  const factory ArtistSelect({
    required String id,
    required String userId,
    required String artistId,
    required DateTime created,
    required DateTime updated,
    // Expanded artist data when fetched with expand
    String? artistName,
    String? artistBio,
    String? artistImageUrl,
  }) = _ArtistSelect;

  factory ArtistSelect.fromJson(Map<String, dynamic> json) =>
      _$ArtistSelectFromJson(json);

  factory ArtistSelect.fromRecord(RecordModel record, [PocketBase? pb]) {
    // Handle expanded artist data
    String? artistName;
    String? artistBio;
    String? artistImageUrl;
    
    if (record.expand.containsKey('artist_id')) {
      final artistData = record.expand['artist_id'];
      if (artistData is List && artistData?.isNotEmpty == true) {
        final artist = artistData?.first;
        if (artist is RecordModel) {
          artistName = artist.data['name']?.toString();
          artistBio = artist.data['bio']?.toString();
          
          // Generate image URL properly like in Artist model
          if (artist.data['image'] != null && artist.data['image'].toString().isNotEmpty && pb != null) {
            try {
              artistImageUrl = pb.files.getUrl(artist, artist.data['image']).toString();
            } catch (e) {
              artistImageUrl = null;
            }
          }
        }
      }
    }
    
    return ArtistSelect(
      id: record.id,
      userId: record.data['user_id']?.toString() ?? '',
      artistId: record.data['artist_id']?.toString() ?? '',
      created: DateTime.parse(record.created),
      updated: DateTime.parse(record.updated),
      artistName: artistName,
      artistBio: artistBio,
      artistImageUrl: artistImageUrl,
    );
  }
} 

