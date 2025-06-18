import 'package:pocketbase/pocketbase.dart';
import 'package:flutter/foundation.dart';
import '../../models/play_history.dart';

class PlayHistoryRepository {
  final PocketBase pb;

  PlayHistoryRepository(this.pb);

  Future<List<PlayHistory>> getRecentlyPlayed(String userId, {int limit = 5}) async {
    try {
      if (userId.isEmpty) {
        return [];
      }
      
      final result = await pb.collection('recent_plays').getList(
        page: 1,
        perPage: limit,
        filter: 'user_id = "$userId"',
        sort: '-played_at',
      );
      
      if (result.items.isEmpty) {
        return [];
      }
      
      final List<PlayHistory> histories = [];
      
      // Process each history record
      for (final record in result.items) {
        try {
          final songId = record.data['song_id'] as String? ?? '';
          
          // Get song data directly without using expand
          RecordModel? songRecord;
          RecordModel? artistRecord;
          RecordModel? albumRecord;
          
          if (songId.isNotEmpty) {
            try {
              songRecord = await pb.collection('songs').getOne(songId);
              
              // Get artist if available
              final artistId = songRecord.data['artist_id'] as String?;
              if (artistId != null && artistId.isNotEmpty) {
                try {
                  artistRecord = await pb.collection('artists').getOne(artistId);
                } catch (e) {
                  // Silently handle artist fetch error
                }
              }
              
              // Get album if available
              final albumId = songRecord.data['album_id'] as String?;
              if (albumId != null && albumId.isNotEmpty) {
                try {
                  albumRecord = await pb.collection('albums').getOne(albumId);
                } catch (e) {
                  // Silently handle album fetch error
                }
              }
            } catch (e) {
              // Silently handle song fetch error
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
          
          histories.add(history);
        } catch (e) {
          // Skip this record on error
        }
      }

      return histories;
    } catch (e) {
      // Return empty list on error
      return [];
    }
  }

  Future<void> addPlayHistory({
    required String userId, 
    required String songId,
    int? durationSeconds,
  }) async {
    try {
      debugPrint('🔄 Repository: Adding play history for $songId ($durationSeconds seconds)');
      
      // First, delete any existing history for this song to avoid duplicates
      final existingHistory = await pb.collection('recent_plays').getList(
        page: 1,
        perPage: 50, // Get more records to ensure we find all duplicates
        filter: 'user_id = "$userId" && song_id = "$songId"',
      );
      
      debugPrint('🔍 Found ${existingHistory.items.length} existing records for song $songId');
      
      // Delete all existing records for this song
      for (final record in existingHistory.items) {
        try {
          await pb.collection('recent_plays').delete(record.id);
          debugPrint('🗑️ Deleted existing record: ${record.id}');
        } catch (e) {
          debugPrint('⚠️ Failed to delete record ${record.id}: $e');
          // Continue if delete fails
        }
      }
      
      // Now create a new record
      final newRecord = await pb.collection('recent_plays').create(body: {
        'user_id': userId,
        'song_id': songId,
        'play_duration_seconds': durationSeconds,
        'played_at': DateTime.now().toIso8601String(),
      });
      
      debugPrint('✅ Repository: Created new play history record: ${newRecord.id}');
    } catch (e) {
      debugPrint('❌ Repository error: $e');
      rethrow;
    }
  }
}



