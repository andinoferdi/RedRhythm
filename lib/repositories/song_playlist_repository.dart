import 'package:flutter/foundation.dart';
import 'package:pocketbase/pocketbase.dart';
import '../services/pocketbase_service.dart';
import '../models/song.dart';
import '../models/playlist.dart';

/// Repository for handling song-playlist relationships
class SongPlaylistRepository {
  final PocketBaseService _pbService;
  
  SongPlaylistRepository(this._pbService);
  
  /// Get PocketBase instance
  PocketBase get _pb => _pbService.pb;
  
  /// Get songs in a playlist
  Future<List<Song>> getPlaylistSongs(String playlistId) async {
    try {
      // Get song_playlist relationships with full song, artist, and album data
      final songPlaylistResult = await _pb.collection('song_playlists').getList(
        filter: 'playlist_id = "$playlistId"',
        expand: 'song_id,song_id.artist_id,song_id.album_id',
        sort: 'created', // Get all records first
        perPage: 500, // Make sure we get all songs
      );
      
      final List<MapEntry<Song, int>> songsWithOrder = [];
      
      for (final record in songPlaylistResult.items) {
        final songData = record.expand['song_id'];
        if (songData != null && songData.isNotEmpty) {
          final songRecord = songData.first;
          final song = Song.fromRecord(songRecord);
          final order = record.data['order'] as int?;
          
          // Use order if available, otherwise use a high number + index to maintain original order
          final finalOrder = order ?? (1000 + songsWithOrder.length);
          songsWithOrder.add(MapEntry(song, finalOrder));
        }
      }
      
      // Sort by order (ascending)
      songsWithOrder.sort((a, b) => a.value.compareTo(b.value));
      
      // Extract songs from sorted list
      final List<Song> songs = songsWithOrder.map((entry) => entry.key).toList();
      
      return songs;
    } catch (e) {
      debugPrint('Get playlist songs error: $e');
      throw Exception('Failed to fetch playlist songs: $e');
    }
  }
  
  /// Get playlists containing a specific song
  Future<List<Playlist>> getPlaylistsContainingSong(String songId) async {
    try {
      debugPrint('🎵 REPOSITORY: Searching playlists containing song ID: $songId');
      
      // Use song_playlists collection to find playlists containing the song
      final songPlaylistRecords = await _pb.collection('song_playlists').getList(
        filter: 'song_id = "$songId"',
        expand: 'playlist_id',
      );
      
      debugPrint('🎵 REPOSITORY: Found ${songPlaylistRecords.items.length} song_playlist records');
      
      final List<Playlist> playlists = [];
      final Set<String> playlistIds = {};
      
      for (final record in songPlaylistRecords.items) {
        final playlistId = record.data['playlist_id'] as String?;
        if (playlistId != null && !playlistIds.contains(playlistId)) {
          playlistIds.add(playlistId);
          
          try {
            // Get the full playlist record
            final playlistRecord = await _pb.collection('playlists').getOne(playlistId);
            final playlist = Playlist.fromRecord(playlistRecord);
            
            // Get all songs for this playlist using song_playlists
            final playlistSongs = await getPlaylistSongs(playlistId);
            final songIds = playlistSongs.map((song) => song.id).toList();
            
            // Create playlist with correct songs list
            final playlistWithSongs = Playlist(
              id: playlist.id,
              name: playlist.name,
              userId: playlist.userId,
              songs: songIds,
              imageUrl: playlist.imageUrl,
              createdAt: playlist.createdAt,
              updatedAt: playlist.updatedAt,
            );
            
            playlists.add(playlistWithSongs);
            debugPrint('🎵 REPOSITORY: Playlist "${playlist.name}" contains song (via song_playlists)');
            debugPrint('🎵 REPOSITORY: Playlist songs: $songIds');
          } catch (e) {
            debugPrint('🎵 REPOSITORY: Error getting playlist $playlistId: $e');
            continue;
          }
        }
      }
      
      debugPrint('🎵 REPOSITORY: Successfully found ${playlists.length} playlists containing song');
      
      return playlists;
    } catch (e) {
      debugPrint('🎵 REPOSITORY: Error getting playlists containing song: $e');
      throw Exception('Failed to get playlists containing song: $e');
    }
  }

  Future<List<Playlist>> getAllPlaylists() async {
    try {
      debugPrint('🎵 REPOSITORY: Fetching all playlists...');
      
      final records = await _pb.collection('playlists').getList();
      
      debugPrint('🎵 REPOSITORY: Found ${records.items.length} total playlists');
      
      final List<Playlist> playlists = [];
      
      for (final record in records.items) {
        try {
          debugPrint('🎵 REPOSITORY: Processing playlist ${record.id}');
          
          final playlist = Playlist.fromRecord(record);
          
          // Get songs for this playlist using song_playlists collection
          final playlistSongs = await getPlaylistSongs(playlist.id);
          final songIds = playlistSongs.map((song) => song.id).toList();
          
          // Create playlist with correct songs list
          final playlistWithSongs = Playlist(
            id: playlist.id,
            name: playlist.name,
            userId: playlist.userId,
            songs: songIds,
            imageUrl: playlist.imageUrl,
            createdAt: playlist.createdAt,
            updatedAt: playlist.updatedAt,
          );
          
          playlists.add(playlistWithSongs);
          debugPrint('🎵 REPOSITORY: Successfully parsed playlist: "${playlist.name}" with ${songIds.length} songs');
        } catch (e) {
          debugPrint('🎵 REPOSITORY: Error parsing playlist record ${record.id}: $e');
          continue;
        }
      }
      
      debugPrint('🎵 REPOSITORY: Successfully parsed ${playlists.length} playlists');
      
      return playlists;
    } catch (e) {
      debugPrint('🎵 REPOSITORY: Error getting all playlists: $e');
      throw Exception('Failed to get all playlists: $e');
    }
  }

  /// Add song to playlist
  Future<void> addSongToPlaylist(String playlistId, String songId) async {
    try {
      debugPrint('🎵 REPOSITORY: Adding song $songId to playlist $playlistId');
      
      // Check if relationship already exists
      final existingRecords = await _pb.collection('song_playlists').getList(
        filter: 'playlist_id = "$playlistId" && song_id = "$songId"',
      );
      
      if (existingRecords.items.isEmpty) {
        // Create new song_playlist relationship
        await _pb.collection('song_playlists').create(body: {
          'playlist_id': playlistId,
          'song_id': songId,
          'order': DateTime.now().millisecondsSinceEpoch, // Use timestamp as order
        });
        debugPrint('🎵 REPOSITORY: Successfully added song to playlist via song_playlists');
      } else {
        debugPrint('🎵 REPOSITORY: Song already exists in playlist');
      }
    } catch (e) {
      debugPrint('🎵 REPOSITORY: Error adding song to playlist: $e');
      throw Exception('Failed to add song to playlist: $e');
    }
  }
  
  /// Remove song from playlist
  Future<void> removeSongFromPlaylist(String playlistId, String songId) async {
    try {
      debugPrint('🎵 REPOSITORY: Removing song $songId from playlist $playlistId');
      
      // Find and delete the song_playlist relationship
      final records = await _pb.collection('song_playlists').getList(
        filter: 'playlist_id = "$playlistId" && song_id = "$songId"',
      );
      
      for (final record in records.items) {
        await _pb.collection('song_playlists').delete(record.id);
        debugPrint('🎵 REPOSITORY: Deleted song_playlist relationship ${record.id}');
      }
      
      debugPrint('🎵 REPOSITORY: Successfully removed song from playlist');
    } catch (e) {
      debugPrint('🎵 REPOSITORY: Error removing song from playlist: $e');
      throw Exception('Failed to remove song from playlist: $e');
    }
  }

  /// Update song order in playlist
  Future<void> updateSongOrder(String playlistId, String songId, int order) async {
    try {
      final result = await _pb.collection('song_playlists').getList(
        filter: 'playlist_id = "$playlistId" && song_id = "$songId"',
      );
      
      if (result.items.isNotEmpty) {
        await _pb.collection('song_playlists').update(result.items.first.id, body: {
          'order': order,
        });
      }
    } catch (e) {
      debugPrint('Update song order error: $e');
      throw Exception('Failed to update song order: $e');
    }
  }
  
  Future<Playlist> createPlaylist(String name, String userId) async {
    try {
      final record = await _pb.collection('playlists').create(
        body: {
          'name': name,
          'user': userId,
          'songs': [],
        },
      );
      return Playlist.fromRecord(record);
    } catch (e) {
      throw Exception('Failed to create playlist: $e');
    }
  }
}
