import 'package:pocketbase/pocketbase.dart';
import '../services/pocketbase_service.dart';
import '../models/song.dart';

/// Repository for handling song-related data
class SongRepository {
  final PocketBaseService _pocketBaseService;
  
  SongRepository(this._pocketBaseService);
  
  /// Get PocketBase instance
  PocketBase get _pb => _pocketBaseService.pb;
  
  /// Fetch all songs
  Future<List<Song>> getAllSongs() async {
    try {
      final response = await _pb.collection('songs').getList(
        page: 1,
        perPage: 100,
        expand: 'artist,album',
      );
      
      return response.items.map((record) => Song.fromRecord(record)).toList();
    } catch (e) {
      throw Exception('Failed to fetch songs: $e');
    }
  }
  
  /// Fetch songs by artist ID
  Future<List<Song>> getSongsByArtist(String artistId) async {
    try {
      final response = await _pb.collection('songs').getList(
        page: 1,
        perPage: 100,
        filter: 'artist.id = "$artistId"',
        expand: 'artist,album',
      );
      
      return response.items.map((record) => Song.fromRecord(record)).toList();
    } catch (e) {
      throw Exception('Failed to fetch songs by artist: $e');
    }
  }
  
  /// Fetch songs by album ID
  Future<List<Song>> getSongsByAlbum(String albumId) async {
    try {
      final response = await _pb.collection('songs').getList(
        page: 1,
        perPage: 100,
        filter: 'album.id = "$albumId"',
        expand: 'artist,album',
      );
      
      return response.items.map((record) => Song.fromRecord(record)).toList();
    } catch (e) {
      throw Exception('Failed to fetch songs by album: $e');
    }
  }
  
  /// Fetch songs by playlist ID
  Future<List<Song>> getSongsByPlaylist(String playlistId) async {
    try {
      final response = await _pb.collection('playlist_songs').getList(
        page: 1,
        perPage: 100,
        filter: 'playlist.id = "$playlistId"',
        expand: 'song,song.artist,song.album',
      );
      
      return response.items
          .map((record) {
            final songRecord = record.expand['song']?[0] as RecordModel?;
            if (songRecord != null) {
              return Song.fromRecord(songRecord);
            }
            return null;
          })
          .where((song) => song != null)
          .cast<Song>()
          .toList();
    } catch (e) {
      throw Exception('Failed to fetch songs by playlist: $e');
    }
  }
  
  /// Search songs
  Future<List<Song>> searchSongs(String query) async {
    try {
      final response = await _pb.collection('songs').getList(
        page: 1,
        perPage: 100,
        filter: 'title ~ "$query" || artist.name ~ "$query" || album.name ~ "$query"',
        expand: 'artist,album',
      );
      
      return response.items.map((record) => Song.fromRecord(record)).toList();
    } catch (e) {
      throw Exception('Failed to search songs: $e');
    }
  }
} 