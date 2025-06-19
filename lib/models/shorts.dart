import 'package:freezed_annotation/freezed_annotation.dart';

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
}

/// Extension methods for Shorts model
extension ShortsExtension on Shorts {
  /// Get formatted hashtags as a list
  List<String> get hashtagsList {
    if (hashtags == null || hashtags!.isEmpty) return [];
    return hashtags!
        .split(' ')
        .where((tag) => tag.isNotEmpty && tag.startsWith('#'))
        .map((tag) => tag.substring(1)) // Remove # symbol
        .toList();
  }

  /// Get display title (fallback to song title or artist name)
  String get displayTitle {
    if (title != null && title!.isNotEmpty) return title!;
    if (songTitle != null && songTitle!.isNotEmpty) return songTitle!;
    if (artistName != null && artistName!.isNotEmpty) return '$artistName - Short';
    return 'Untitled Short';
  }

  /// Get display artist name with fallback
  String get displayArtist {
    if (artistName != null && artistName!.isNotEmpty) return artistName!;
    return 'Unknown Artist';
  }

  /// Format view count for display (1.2K, 1.5M, etc.)
  String get formattedViews {
    if (views < 1000) return views.toString();
    if (views < 1000000) return '${(views / 1000).toStringAsFixed(1)}K';
    return '${(views / 1000000).toStringAsFixed(1)}M';
  }

  /// Format like count for display
  String get formattedLikes {
    if (likes < 1000) return likes.toString();
    if (likes < 1000000) return '${(likes / 1000).toStringAsFixed(1)}K';
    return '${(likes / 1000000).toStringAsFixed(1)}M';
  }

  /// Check if this short has a valid video URL
  bool get hasValidVideo {
    return videoUrl.isNotEmpty && 
           (videoUrl.startsWith('http://') || videoUrl.startsWith('https://'));
  }

  /// Get duration since creation (for display)
  String get timeAgo {
    if (createdAt == null) return '';
    
    final now = DateTime.now();
    final difference = now.difference(createdAt!);
    
    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }

  /// Check if short is recent (within last 24 hours)
  bool get isRecent {
    if (createdAt == null) return false;
    final now = DateTime.now();
    return now.difference(createdAt!).inHours < 24;
  }
}
