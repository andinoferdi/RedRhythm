import 'package:get_it/get_it.dart';
import '../services/pocketbase_service.dart';
import '../models/user_stats.dart';

class UserStatsRepository {
  final PocketBaseService _pocketBaseService = GetIt.I<PocketBaseService>();

  /// Get PocketBase instance
  get _pb => _pocketBaseService.pb;

  /// Get user statistics
  Future<UserStats> getUserStats(String userId) async {
    try {
      // Get playlists count for this user
      final playlistsResult = await _pb.collection('playlists').getList(
        filter: 'user_id = "$userId"',
        page: 1,
        perPage: 1,
      );
      final playlistsCount = playlistsResult.totalItems;

      // Get play history count (songs played) for this user
      final playHistoryResult = await _pb.collection('recent_plays').getList(
        filter: 'user_id = "$userId"',
        page: 1,
        perPage: 1,
      );
      final songsPlayed = playHistoryResult.totalItems;

      // Get album_selects count (saved albums) for this user
      final albumSelectsResult = await _pb.collection('album_selects').getList(
        filter: 'user_id = "$userId"',
        page: 1,
        perPage: 1,
      );
      final savedAlbums = albumSelectsResult.totalItems;

      // Get artist_selects count (saved artists) for this user
      final artistSelectsResult = await _pb.collection('artist_selects').getList(
        filter: 'user_id = "$userId"',
        page: 1,
        perPage: 1,
      );
      final savedArtists = artistSelectsResult.totalItems;

      return UserStats(
        songsPlayed: songsPlayed,
        playlistsCount: playlistsCount,
        likedSongs: savedAlbums, // Using album_selects as "saved albums"
        following: savedArtists, // Using artist_selects as "saved artists"
      );
    } catch (e) {
      throw Exception('Failed to get user stats: $e');
    }
  }
} 