import 'package:pocketbase/pocketbase.dart';
import '../../models/play_history.dart';

class PlayHistoryRepository {
  final PocketBase pb;

  PlayHistoryRepository(this.pb);

  Future<List<PlayHistory>> getRecentlyPlayed(String userId, {int limit = 5}) async {
    try {
      print('DEBUG-REPO: Fetching recently played for user: $userId');
      print('DEBUG-REPO: PocketBase URL: ${pb.baseUrl}');
      
      if (userId.isEmpty) {
        print('ERROR: userId is empty');
        return [];
      }
      
      // Debug logs for user info
      try {
        print('DEBUG-REPO: Verifying current auth status...');
        final authData = pb.authStore.model;
        print('DEBUG-REPO: Current auth user: ${authData?.id}');
        print('DEBUG-REPO: Expected user: $userId');
        print('DEBUG-REPO: Auth status valid: ${pb.authStore.isValid}');
      } catch (e) {
        print('DEBUG-REPO: Error checking auth: $e');
      }
      
      // Get all history records to see what's available
      try {
        print('DEBUG-REPO: Getting ALL history records without filter...');
        final allHistories = await pb.collection('user_history').getFullList();
        print('DEBUG-REPO: Total history records: ${allHistories.length}');
        
        for (final record in allHistories) {
          final recordUserId = record.data['user_id'];
          print('DEBUG-REPO: Record ${record.id} - user_id: $recordUserId');
          print('DEBUG-REPO: Match with current user ($userId): ${recordUserId == userId}');
        }
      } catch (e) {
        print('DEBUG-REPO: Error fetching all records: $e');
      }
      
      // Test if songs collection is accessible
      try {
        print('DEBUG-REPO: Testing songs collection access...');
        final songs = await pb.collection('songs').getList(page: 1, perPage: 1);
        print('DEBUG-REPO: Songs collection accessible, fetched ${songs.items.length} songs');
      } catch (e) {
        print('DEBUG-REPO: Error accessing songs: $e');
      }

      // Use direct user ID match for history records
      print('DEBUG-REPO: Trying filter: user_id = "$userId"');
      final result = await pb.collection('user_history').getList(
        page: 1,
        perPage: limit,
        filter: 'user_id = "$userId"',
        sort: '-played_at',
      );
      
      print('DEBUG-REPO: Filter "user_id = "$userId"" returned ${result.items.length} items');
      
      if (result.items.isEmpty) {
        return [];
      }
      
      final List<PlayHistory> histories = [];
      
      // Process each history record
      for (final record in result.items) {
        try {
          final songId = record.data['song_id'] as String? ?? '';
          print('DEBUG-REPO: Processing record ${record.id} with song_id: $songId');
          
          // Get song data directly without using expand
          RecordModel? songRecord;
          RecordModel? artistRecord;
          RecordModel? albumRecord;
          
          if (songId.isNotEmpty) {
            try {
              songRecord = await pb.collection('songs').getOne(songId);
              print('DEBUG-REPO: Found song: ${songRecord.data['title']}');
              
              // Get artist if available
              final artistId = songRecord.data['artist_id'] as String?;
              if (artistId != null && artistId.isNotEmpty) {
                try {
                  artistRecord = await pb.collection('artists').getOne(artistId);
                  print('DEBUG-REPO: Found artist: ${artistRecord.data['name']}');
                } catch (e) {
                  print('DEBUG-REPO: Error getting artist: $e');
                }
              }
              
              // Get album if available
              final albumId = songRecord.data['album_id'] as String?;
              if (albumId != null && albumId.isNotEmpty) {
                try {
                  albumRecord = await pb.collection('albums').getOne(albumId);
                  print('DEBUG-REPO: Found album: ${albumRecord.data['title']}');
                } catch (e) {
                  print('DEBUG-REPO: Error getting album: $e');
                }
              }
            } catch (e) {
              print('DEBUG-REPO: Error getting song: $e');
            }
          }
          
          // Create PlayHistory object
          final history = PlayHistory.fromRecord(
            record,
            songRecord: songRecord,
            artistRecord: artistRecord,
            albumRecord: albumRecord,
            baseUrl: pb.baseUrl,
          );
          
          print('DEBUG-REPO: Created PlayHistory:');
          print('DEBUG-REPO:   Title: ${history.songTitle}');
          print('DEBUG-REPO:   Artist: ${history.artistName}');
          print('DEBUG-REPO:   Cover: ${history.albumCoverUrl != null ? "Has cover" : "No cover"}');
          
          histories.add(history);
        } catch (e) {
          print('DEBUG-REPO: Error processing record ${record.id}: $e');
        }
      }

      print('DEBUG-REPO: Returning ${histories.length} history items');
      return histories;
    } catch (e) {
      print('ERROR: fetching play history: $e');
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