import 'package:flutter/foundation.dart';
import 'package:pocketbase/pocketbase.dart';
import '../services/pocketbase_service.dart';
import '../models/song.dart';

/// Repository for handling song-playlist relationships
class SongPlaylistRepository {
  final PocketBaseService _pocketBaseService;
  
  SongPlaylistRepository(this._pocketBaseService);
  
  /// Get PocketBase instance
  PocketBase get _pb => _pocketBaseService.pb;
  
  /// Get songs in a playlist
  Future<List<Song>> getPlaylistSongs(String playlistId) async {
    try {
      // Get song_playlist relationships with full song, artist, and album data
      final songPlaylistResult = await _pb.collection('song_playlists').getList(
        filter: 'playlist_id = "$playlistId"',
        expand: 'song_id,song_id.artist_id,song_id.album_id',
        sort: 'created',
      );
      
      final List<Song> songs = [];
      
      for (final record in songPlaylistResult.items) {
        final songData = record.expand['song_id'];
        if (songData != null && songData.isNotEmpty) {
          final songRecord = songData.first;
          songs.add(Song.fromRecord(songRecord));
        }
      }
      
      return songs;
    } catch (e) {
      debugPrint('Get playlist songs error: $e');
      throw Exception('Failed to fetch playlist songs: $e');
    }
  }
  
  /// Add song to playlist
  Future<RecordModel> addSongToPlaylist({
    required String playlistId,
    required String songId,
  }) async {
    try {
      // Check if song is already in playlist
      final existing = await _pb.collection('song_playlists').getList(
        filter: 'playlist_id = "$playlistId" && song_id = "$songId"',
      );
      
      if (existing.items.isNotEmpty) {
        throw Exception('Song is already in playlist');
      }
      
      return await _pb.collection('song_playlists').create(body: {
        'playlist_id': playlistId,
        'song_id': songId,
      });
    } catch (e) {
      debugPrint('Add song to playlist error: $e');
      throw Exception('Failed to add song to playlist: $e');
    }
  }
  
  /// Remove song from playlist
  Future<void> removeSongFromPlaylist({
    required String playlistId,
    required String songId,
  }) async {
    try {
      final result = await _pb.collection('song_playlists').getList(
        filter: 'playlist_id = "$playlistId" && song_id = "$songId"',
      );
      
      if (result.items.isNotEmpty) {
        await _pb.collection('song_playlists').delete(result.items.first.id);
      }
    } catch (e) {
      debugPrint('Remove song from playlist error: $e');
      throw Exception('Failed to remove song from playlist: $e');
    }
  }
  
  /// Get playlists containing a specific song
  Future<List<RecordModel>> getPlaylistsContainingSong(String songId) async {
    try {
      final result = await _pb.collection('song_playlists').getList(
        filter: 'song_id = "$songId"',
        expand: 'playlist_id',
      );
      
      final List<RecordModel> playlists = [];
      
      for (final record in result.items) {
        final playlistData = record.expand['playlist_id'];
        if (playlistData != null && playlistData.isNotEmpty) {
          playlists.add(playlistData.first);
        }
      }
      
      return playlists;
    } catch (e) {
      debugPrint('Get playlists containing song error: $e');
      throw Exception('Failed to fetch playlists containing song: $e');
    }
  }
}
