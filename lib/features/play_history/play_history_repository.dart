import 'package:pocketbase/pocketbase.dart';
import '../../models/play_history.dart';

class PlayHistoryRepository {
  final PocketBase pb;

  PlayHistoryRepository(this.pb);

  Future<List<PlayHistory>> getRecentlyPlayed(String userId, {int limit = 5}) async {
    try {
      print('Fetching recently played for user: $userId');
      
      if (userId.isEmpty) {
        print('Error: userId is empty');
        return [];
      }
      
      final result = await pb.collection('user_history').getList(
        page: 1,
        perPage: limit,
        filter: 'user_id = "$userId"',
        sort: '-played_at',
        expand: 'song_id,song_id.artist_id,song_id.album_id',
      );

      print('Fetched ${result.items.length} play history records');
      
      final List<PlayHistory> histories = [];
      
      for (final record in result.items) {
        try {
          final songRecord = record.expand['song_id'] as RecordModel?;
          RecordModel? artistRecord;
          RecordModel? albumRecord;

          if (songRecord != null) {
            try {
              artistRecord = songRecord.expand['artist_id'] as RecordModel?;
            } catch (e) {
              print('Error expanding artist: $e');
            }
            
            try {
              albumRecord = songRecord.expand['album_id'] as RecordModel?;
            } catch (e) {
              print('Error expanding album: $e');
            }
          }

          final history = PlayHistory.fromRecord(
            record,
            songRecord: songRecord,
            artistRecord: artistRecord,
            albumRecord: albumRecord,
            baseUrl: pb.baseUrl,
          );
          
          histories.add(history);
        } catch (e) {
          print('Error processing record ${record.id}: $e');
        }
      }

      return histories;
    } catch (e) {
      print('Error fetching play history: $e');
      return [];
    }
  }

  Future<void> addPlayHistory({
    required String userId, 
    required String songId,
    int? durationSeconds,
    bool completed = false,
  }) async {
    try {
      await pb.collection('user_history').create(body: {
        'user_id': userId,
        'song_id': songId,
        'play_duration_seconds': durationSeconds,
        'completed': completed,
        'played_at': DateTime.now().toIso8601String(),
      });
      print('Play history added successfully');
    } catch (e) {
      print('Error adding play history: $e');
      rethrow;
    }
  }
} 