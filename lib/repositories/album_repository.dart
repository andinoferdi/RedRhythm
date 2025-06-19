import 'package:pocketbase/pocketbase.dart';
import '../services/pocketbase_service.dart';
import '../models/album.dart';
import '../models/song.dart';

/// Repository for handling Album data operations
class AlbumRepository {
  final PocketBaseService _pbService;

  AlbumRepository(this._pbService);

  /// Get all albums
  Future<List<Album>> getAllAlbums() async {
    try {
      await _pbService.initialize();
      
      final result = await _pbService.pb.collection('albums').getList(
        page: 1,
        perPage: 100,
        expand: 'artist_id',
        sort: '-created',
      );

      return result.items.map((record) => Album.fromRecord(record)).toList();
    } catch (e) {
      throw Exception('Failed to get albums: $e');
    }
  }

  /// Get album by ID
  Future<Album?> getAlbumById(String albumId) async {
    try {
      await _pbService.initialize();
      
      final record = await _pbService.pb.collection('albums').getOne(
        albumId,
        expand: 'artist_id',
      );

      return Album.fromRecord(record);
    } catch (e) {
      if (e.toString().contains('404')) {
        return null; // Album not found
      }
      throw Exception('Failed to get album: $e');
    }
  }

  /// Get album by title and artist name
  Future<Album?> getAlbumByTitleAndArtist(String title, String artistName) async {
    try {
      await _pbService.initialize();
      
      final result = await _pbService.pb.collection('albums').getList(
        page: 1,
        perPage: 1,
        filter: 'title = "$title" && artist_id.name = "$artistName"',
        expand: 'artist_id',
      );

      if (result.items.isNotEmpty) {
        return Album.fromRecord(result.items.first);
      }
      
      return null;
    } catch (e) {
      throw Exception('Failed to get album by title and artist: $e');
    }
  }

  /// Get albums by artist ID
  Future<List<Album>> getAlbumsByArtist(String artistId) async {
    try {
      await _pbService.initialize();
      
      final result = await _pbService.pb.collection('albums').getList(
        page: 1,
        perPage: 50,
        filter: 'artist_id = "$artistId"',
        expand: 'artist_id',
        sort: '-release_year,-created',
      );

      return result.items.map((record) => Album.fromRecord(record)).toList();
    } catch (e) {
      throw Exception('Failed to get albums by artist: $e');
    }
  }

  /// Get albums by artist name
  Future<List<Album>> getAlbumsByArtistName(String artistName) async {
    try {
      await _pbService.initialize();
      
      final result = await _pbService.pb.collection('albums').getList(
        page: 1,
        perPage: 50,
        filter: 'artist_id.name = "$artistName"',
        expand: 'artist_id',
        sort: '-release_year,-created',
      );

      return result.items.map((record) => Album.fromRecord(record)).toList();
    } catch (e) {
      throw Exception('Failed to get albums by artist name: $e');
    }
  }

  /// Get songs in an album
  Future<List<Song>> getAlbumSongs(String albumId) async {
    try {
      await _pbService.initialize();
      
      final result = await _pbService.pb.collection('songs').getList(
        page: 1,
        perPage: 100,
        filter: 'album_id = "$albumId"',
        expand: 'artist_id,album_id',
        sort: 'track_number,title',
      );

      return result.items.map((record) => Song.fromRecord(record)).toList();
    } catch (e) {
      throw Exception('Failed to get album songs: $e');
    }
  }

  /// Search albums by title
  Future<List<Album>> searchAlbums(String query) async {
    try {
      await _pbService.initialize();
      
      if (query.trim().isEmpty) {
        return [];
      }

      final result = await _pbService.pb.collection('albums').getList(
        page: 1,
        perPage: 20,
        filter: 'title ~ "$query" || artist_id.name ~ "$query"',
        expand: 'artist_id',
        sort: '-created',
      );

      return result.items.map((record) => Album.fromRecord(record)).toList();
    } catch (e) {
      throw Exception('Failed to search albums: $e');
    }
  }

  /// Get popular albums (by play count or creation date)
  Future<List<Album>> getPopularAlbums({int limit = 20}) async {
    try {
      await _pbService.initialize();
      
      final result = await _pbService.pb.collection('albums').getList(
        page: 1,
        perPage: limit,
        expand: 'artist_id',
        sort: '-created', // Could be enhanced with play count sorting
      );

      return result.items.map((record) => Album.fromRecord(record)).toList();
    } catch (e) {
      throw Exception('Failed to get popular albums: $e');
    }
  }
} 