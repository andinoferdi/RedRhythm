import 'package:pocketbase/pocketbase.dart';
import '../services/pocketbase_service.dart';
import '../models/genre_model.dart';
import '../models/genre.dart';
import '../models/song.dart';

/// Repository for handling genre-related data
class GenreRepository {
  final PocketBaseService _pocketBaseService;
  
  GenreRepository(this._pocketBaseService);
  
  /// Get PocketBase instance
  PocketBase get _pb => _pocketBaseService.pb;
  
  /// Get all genres
  Future<List<GenreModel>> getGenres() async {
    try {
      final response = await _pb.collection('genres').getList(
        page: 1,
        perPage: 50,
      );
      
      // Get the base URL for constructing file URLs
      final baseUrl = _pb.baseUrl;
      
      return response.items.map((record) => 
        GenreModel.fromRecord(record, baseUrl: baseUrl)
      ).toList();
    } catch (e) {
      // Improve error handling with specific error messages
      if (e.toString().contains('Failed to connect') || 
          e.toString().contains('SocketException') ||
          e.toString().contains('Connection')) {
        throw Exception('Network error. Please check your connection');
      }
      
      throw Exception('Failed to load genres: ${e.toString()}');
    }
  }

  /// Get all genres
  Future<List<Genre>> getAllGenres() async {
    await _pocketBaseService.initialize();
    
    final result = await _pocketBaseService.pb.collection('genres').getList(
      page: 1,
      perPage: 50,
      sort: 'name', // Sort by name alphabetically
    );

    return result.items.map((record) => Genre.fromRecord(record)).toList();
  }

  /// Get genre by ID
  Future<Genre?> getGenreById(String genreId) async {
    if (genreId.isEmpty) return null;
    
    try {
      await _pocketBaseService.initialize();
      
      final record = await _pocketBaseService.pb.collection('genres').getOne(genreId);
      return Genre.fromRecord(record);
    } catch (e) {
      return null;
    }
  }

  /// Get songs by genre ID
  Future<List<Song>> getSongsByGenre(String genreId) async {
    await _pocketBaseService.initialize();
    
    final result = await _pocketBaseService.pb.collection('songs').getList(
      page: 1,
      perPage: 200, // Get more songs for genres
      filter: 'genre_id = "$genreId"',
      sort: '-play_count', // Sort by play count (most popular first)
      expand: 'artist_id,album_id,genre_id', // Expand relations
    );

    return result.items.map((record) => Song.fromRecord(record)).toList();
  }

  /// Get genre by name (for fallback)
  Future<Genre?> getGenreByName(String genreName) async {
    if (genreName.isEmpty) return null;
    
    try {
      await _pocketBaseService.initialize();
      
      final result = await _pocketBaseService.pb.collection('genres').getList(
        page: 1,
        perPage: 1,
        filter: 'name = "$genreName"',
      );

      if (result.items.isNotEmpty) {
        return Genre.fromRecord(result.items.first);
      }
      
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Get genre image URL
  String getGenreImageUrl(Genre genre) {
    if (genre.image == null || genre.image!.isEmpty) {
      print('DEBUG: Genre ${genre.name} has no image');
      return '';
    }
    
    try {
      final imageName = genre.image!.trim();
      
      // Validate filename format
      if (!imageName.contains('.') || imageName.startsWith('.') || 
          imageName.endsWith('.') || imageName.length < 3) {
        print('DEBUG: Genre ${genre.name} has invalid image filename: $imageName');
        return '';
      }
      
      // Construct the URL manually using PocketBase URL structure
      final baseUrl = _pocketBaseService.pb.baseUrl;
      
      if (baseUrl.trim().isEmpty) {
        print('DEBUG: PocketBase base URL is empty');
        return '';
      }
      
      final imageUrl = '$baseUrl/api/files/genres/${genre.id}/$imageName';
      
      // Validate generated URL
      if (!_isValidPocketBaseUrl(imageUrl)) {
        print('DEBUG: Generated invalid URL for genre ${genre.name}: $imageUrl');
        return '';
      }
      
      print('DEBUG: Generated genre image URL: $imageUrl');
      return imageUrl;
    } catch (e) {
      print('DEBUG: Error generating genre image URL: $e');
      return '';
    }
  }
  
  /// Validate if a PocketBase URL is likely to be valid
  static bool _isValidPocketBaseUrl(String url) {
    if (url.isEmpty) return false;
    
    try {
      final uri = Uri.parse(url);
      final pathSegments = uri.pathSegments;
      if (pathSegments.length < 4 || 
          pathSegments[0] != 'api' || 
          pathSegments[1] != 'files') {
        return false;
      }
      
      final filename = pathSegments.last;
      if (filename.isEmpty || !filename.contains('.')) {
        return false;
      }
      
      return true;
    } catch (e) {
      return false;
    }
  }
}



