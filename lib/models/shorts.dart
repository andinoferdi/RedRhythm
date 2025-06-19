import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:pocketbase/pocketbase.dart';

part 'shorts.freezed.dart';
part 'shorts.g.dart';

@freezed
class Shorts with _$Shorts {
  const factory Shorts({
    required String id,
    required String genresId,
    required String videoUrl,
    required String artistId,
    required String songId,
    String? title,
    String? hashtags,
    String? artistName,
    String? songTitle,
    String? thumbnailUrl,
    @Default(0) int views,
    @Default(0) int likes,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) = _Shorts;

  factory Shorts.fromJson(Map<String, dynamic> json) => _$ShortsFromJson(json);
  
  /// Create a Shorts from a PocketBase record
  static Shorts fromRecord(RecordModel record) {
    // Get expanded artist and song if available
    final artistRecord = record.expand['artist_id']?[0];
    final songRecord = record.expand['song_id']?[0];
    final genreRecord = record.expand['genres_id']?[0];
    
    // Extract artist name - try expand first, then fallback to direct field
    String artistName = 'Unknown Artist';
    if (artistRecord != null) {
      artistName = artistRecord.data['name'] as String? ?? 'Unknown Artist';
    }
    
    // Extract song title - try expand first, then fallback to direct field
    String songTitle = 'Unknown Song';
    if (songRecord != null) {
      songTitle = songRecord.data['title'] as String? ?? 'Unknown Song';
    }
    
    // Extract video URL
    String videoUrl = '';
    if (record.data.containsKey('video') && record.data['video'] != null) {
      final videoField = record.data['video'];
      if (videoField is String && videoField.trim().isNotEmpty) {
        // Generate proper PocketBase file URL
        final baseUrl = ''; // Will be set by service
        final collectionId = record.collectionId;
        final recordId = record.id;
        
        videoUrl = '$baseUrl/api/files/$collectionId/$recordId/$videoField';
      }
    }
    
    // Extract hashtags from genre or create based on content
    String hashtags = '';
    if (genreRecord != null) {
      final genreName = genreRecord.data['name'] as String? ?? '';
      hashtags = '#${genreName.toLowerCase().replaceAll(' ', '')}';
    }
    
    return Shorts(
      id: record.id,
      genresId: record.data['genres_id'] as String? ?? '',
      videoUrl: videoUrl,
      artistId: record.data['artist_id'] as String? ?? '',
      songId: record.data['song_id'] as String? ?? '',
      title: record.data['title'] as String?,
      hashtags: hashtags,
      artistName: artistName,
      songTitle: songTitle,
      thumbnailUrl: record.data['thumbnail_url'] as String?,
      views: record.data['views'] as int? ?? 0,
      likes: record.data['likes'] as int? ?? 0,
      createdAt: record.created != null ? DateTime.parse(record.created!) : null,
      updatedAt: record.updated != null ? DateTime.parse(record.updated!) : null,
    );
  }
}

/// Extension for formatted display values
extension ShortsExt on Shorts {
  /// Get formatted view count for display
  String get formattedViews {
    if (views < 1000) {
      return views.toString();
    } else if (views < 1000000) {
      return '${(views / 1000).toStringAsFixed(1)}K';
    } else {
      return '${(views / 1000000).toStringAsFixed(1)}M';
    }
  }
  
  /// Get formatted like count for display
  String get formattedLikes {
    if (likes < 1000) {
      return likes.toString();
    } else if (likes < 1000000) {
      return '${(likes / 1000).toStringAsFixed(1)}K';
    } else {
      return '${(likes / 1000000).toStringAsFixed(1)}M';
    }
  }
  
  /// Get display title (fallback to song title or artist name)
  String get displayTitle {
    if (title?.isNotEmpty == true) return title!;
    if (songTitle?.isNotEmpty == true) return songTitle!;
    if (artistName?.isNotEmpty == true) return artistName!;
    return 'Untitled';
  }
} 