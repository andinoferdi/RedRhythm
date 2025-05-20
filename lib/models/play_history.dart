import 'package:pocketbase/pocketbase.dart';

class PlayHistory {
  final String id;
  final String userId;
  final String songId;
  final DateTime playedAt;
  final int? playDurationSeconds;
  final bool completed;

  // Tambahan field yang diambil dari relasi
  final String? songTitle;
  final String? artistName;
  final String? albumCoverUrl;

  PlayHistory({
    required this.id,
    required this.userId,
    required this.songId,
    required this.playedAt,
    this.playDurationSeconds,
    required this.completed,
    this.songTitle,
    this.artistName,
    this.albumCoverUrl,
  });

  factory PlayHistory.fromRecord(RecordModel record, {
    RecordModel? songRecord,
    RecordModel? artistRecord,
    RecordModel? albumRecord,
    required String baseUrl,
  }) {
    // Ekstrak data dasar dari record history
    final id = record.id;
    final userId = record.data['user_id'] as String? ?? '';
    final songId = record.data['song_id'] as String? ?? '';
    final playedAtStr = record.data['played_at'] as String? ?? DateTime.now().toIso8601String();
    final playedAt = DateTime.parse(playedAtStr);
    final playDurationSeconds = record.data['play_duration_seconds'] as int?;
    final completed = record.data['completed'] as bool? ?? false;

    // Ekstrak data dari relasi song jika tersedia
    String? songTitle;
    String? artistName;
    String? albumCoverUrl;

    if (songRecord != null) {
      songTitle = songRecord.data['title'] as String?;
      
      if (artistRecord != null) {
        artistName = artistRecord.data['name'] as String?;
      }
      
      if (albumRecord != null && albumRecord.data['cover_image'] != null) {
        final coverImage = albumRecord.data['cover_image'];
        albumCoverUrl = '$baseUrl/api/files/${albumRecord.collectionId}/${albumRecord.id}/$coverImage';
      }
    }

    return PlayHistory(
      id: id,
      userId: userId,
      songId: songId,
      playedAt: playedAt,
      playDurationSeconds: playDurationSeconds,
      completed: completed,
      songTitle: songTitle,
      artistName: artistName,
      albumCoverUrl: albumCoverUrl,
    );
  }
} 