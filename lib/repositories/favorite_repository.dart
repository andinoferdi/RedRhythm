import 'package:pocketbase/pocketbase.dart';
import '../services/pocketbase_service.dart';
import '../models/favorite.dart';
import '../models/song.dart';

/// Repository for handling favorite songs
class FavoriteRepository {
  final PocketBaseService _pocketBaseService;
  
  // Cache for user's favorite songs
  static List<Song>? _favoriteSongsCache;
  static DateTime? _cacheTimestamp;
  static String? _cachedUserId;
  static const Duration _cacheExpiry = Duration(minutes: 3);
  
  FavoriteRepository(this._pocketBaseService);
  
  /// Get PocketBase instance
  PocketBase get _pb => _pocketBaseService.pb;
  
  /// Get current user ID
  String? get _currentUserId => _pocketBaseService.currentUser?.id;
  
  /// Add song to favorites
  Future<void> addToFavorites(String songId) async {
    final userId = _currentUserId;
    if (userId == null) {
      throw Exception('User not authenticated');
    }
    
    try {
      // Check if already in favorites
      final existing = await _pb.collection('favorites').getList(
        page: 1,
        perPage: 1,
        filter: 'user_id = "$userId" && song_id = "$songId"',
      );
      
      if (existing.items.isNotEmpty) {
        return; // Already in favorites
      }
      
      // Add to favorites
      await _pb.collection('favorites').create(body: {
        'user_id': userId,
        'song_id': songId,
      });
      
      // Clear cache to force refresh
      _clearCache();
    } catch (e) {
      throw Exception('Failed to add to favorites: $e');
    }
  }
  
  /// Remove song from favorites
  Future<void> removeFromFavorites(String songId) async {
    final userId = _currentUserId;
    if (userId == null) {
      throw Exception('User not authenticated');
    }
    
    try {
      // Find the favorite record
      final existing = await _pb.collection('favorites').getList(
        page: 1,
        perPage: 1,
        filter: 'user_id = "$userId" && song_id = "$songId"',
      );
      
      if (existing.items.isNotEmpty) {
        // Remove from favorites
        await _pb.collection('favorites').delete(existing.items.first.id);
        
        // Clear cache to force refresh
        _clearCache();
      }
    } catch (e) {
      throw Exception('Failed to remove from favorites: $e');
    }
  }
  
  /// Check if song is in favorites
  Future<bool> isFavorite(String songId) async {
    final userId = _currentUserId;
    if (userId == null) {
      return false;
    }
    
    try {
      final result = await _pb.collection('favorites').getList(
        page: 1,
        perPage: 1,
        filter: 'user_id = "$userId" && song_id = "$songId"',
      );
      
      return result.items.isNotEmpty;
    } catch (e) {
      return false;
    }
  }
  
  /// Get all favorite songs for current user with caching
  Future<List<Song>> getFavoriteSongs() async {
    final userId = _currentUserId;
    if (userId == null) {
      return [];
    }
    
    try {
      // Check cache first
      if (_favoriteSongsCache != null && 
          _cacheTimestamp != null && 
          _cachedUserId == userId) {
        final cacheAge = DateTime.now().difference(_cacheTimestamp!);
        if (cacheAge < _cacheExpiry) {
          return _favoriteSongsCache!;
        }
      }
      
      // Load from database with expanded song data
      final response = await _pb.collection('favorites').getList(
        page: 1,
        perPage: 200,
        filter: 'user_id = "$userId"',
        expand: 'song_id,song_id.artist_id,song_id.album_id',
        sort: '-created', // Most recent first
      );
      
      final songs = <Song>[];
      for (final record in response.items) {
        final songRecord = record.expand['song_id']?[0];
        if (songRecord != null) {
          songs.add(Song.fromRecord(songRecord));
        }
      }
      
      // Update cache
      _favoriteSongsCache = songs;
      _cacheTimestamp = DateTime.now();
      _cachedUserId = userId;
      
      return songs;
    } catch (e) {
      // If error and we have cache for this user, return cache
      if (_favoriteSongsCache != null && _cachedUserId == userId) {
        return _favoriteSongsCache!;
      }
      throw Exception('Failed to fetch favorite songs: $e');
    }
  }
  
  /// Get favorite count for current user
  Future<int> getFavoriteCount() async {
    final userId = _currentUserId;
    if (userId == null) {
      return 0;
    }
    
    try {
      final result = await _pb.collection('favorites').getList(
        page: 1,
        perPage: 1,
        filter: 'user_id = "$userId"',
      );
      
      return result.totalItems;
    } catch (e) {
      return 0;
    }
  }
  
  /// Clear the cache (useful for refresh)
  static void _clearCache() {
    _favoriteSongsCache = null;
    _cacheTimestamp = null;
    _cachedUserId = null;
  }
  
  /// Clear cache for specific user (useful for logout)
  static void clearCacheForUser(String userId) {
    if (_cachedUserId == userId) {
      _clearCache();
    }
  }
  
  /// Force refresh favorites
  Future<List<Song>> refreshFavorites() async {
    _clearCache();
    return await getFavoriteSongs();
  }
} 