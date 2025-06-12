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
      final records = await _pb.collection('playlists').getList(
        filter: 'songs ~ "$songId"',
      );

      return records.items.map((record) => Playlist.fromRecord(record)).toList();
    } catch (e) {
      throw Exception('Failed to get playlists containing song: $e');
    }
  }

  Future<List<Playlist>> getAllPlaylists() async {
    try {
      final records = await _pb.collection('playlists').getList();
      return records.items.map((record) => Playlist.fromRecord(record)).toList();
    } catch (e) {
      throw Exception('Failed to get all playlists: $e');
    }
  }

  /// Add song to playlist
  Future<void> addSongToPlaylist(String playlistId, String songId) async {
    try {
      final playlist = await _pb.collection('playlists').getOne(playlistId);
      final songs = List<String>.from(playlist.data['songs'] ?? []);
      
      if (!songs.contains(songId)) {
        songs.add(songId);
        await _pb.collection('playlists').update(
          playlistId,
          body: {'songs': songs},
        );
      }
    } catch (e) {
      throw Exception('Failed to add song to playlist: $e');
    }
  }
  
  /// Remove song from playlist
  Future<void> removeSongFromPlaylist(String playlistId, String songId) async {
    try {
      final playlist = await _pb.collection('playlists').getOne(playlistId);
      final songs = List<String>.from(playlist.data['songs'] ?? []);
      
      songs.remove(songId);
      await _pb.collection('playlists').update(
        playlistId,
        body: {'songs': songs},
      );
    } catch (e) {
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
