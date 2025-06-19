import 'package:flutter/foundation.dart';
import 'package:pocketbase/pocketbase.dart';
import '../models/shorts.dart';
import '../services/pocketbase_service.dart';

class ShortsRepository {
  final PocketBaseService _pocketBaseService;

  ShortsRepository(this._pocketBaseService);

  /// Get all shorts with pagination
  Future<List<Shorts>> getShorts({
    int page = 1,
    int perPage = 10,
    String filter = '',
    String sort = '-created',
  }) async {
    try {
      await _pocketBaseService.initialize();
      
      if (!_pocketBaseService.isAuthenticated) {
        throw Exception('User not authenticated');
      }

      final records = await _pocketBaseService.pb.collection('shorts').getList(
        page: page,
        perPage: perPage,
        filter: filter,
        sort: sort,
        expand: 'artist_id,song_id,genres_id',
      );

      final baseUrl = _pocketBaseService.pb.baseUrl;
      
      return records.items.map((record) {
        var shorts = Shorts.fromRecord(record);
        
        // Fix video URL with proper base URL
        if (shorts.videoUrl.isNotEmpty) {
          final videoField = record.data['video'] as String?;
          if (videoField != null && videoField.isNotEmpty) {
            final correctedVideoUrl = '$baseUrl/api/files/${record.collectionId}/${record.id}/$videoField';
            shorts = shorts.copyWith(videoUrl: correctedVideoUrl);
          }
        }
        
        return shorts;
      }).toList();
    } catch (e) {
      debugPrint('Error fetching shorts: $e');
      rethrow;
    }
  }

  /// Get shorts by genre
  Future<List<Shorts>> getShortsByGenre(String genreId, {
    int page = 1,
    int perPage = 10,
  }) async {
    return getShorts(
      page: page,
      perPage: perPage,
      filter: 'genres_id = "$genreId"',
    );
  }

  /// Get random shorts for discovery
  Future<List<Shorts>> getRandomShorts({int count = 10}) async {
    try {
      await _pocketBaseService.initialize();
      
      if (!_pocketBaseService.isAuthenticated) {
        throw Exception('User not authenticated');
      }

      // Get random shorts - PocketBase doesn't have RANDOM() so we'll get more and shuffle
      final records = await _pocketBaseService.pb.collection('shorts').getList(
        page: 1,
        perPage: count * 2, // Get more to have better randomization
        sort: '-created',
        expand: 'artist_id,song_id,genres_id',
      );

      final baseUrl = _pocketBaseService.pb.baseUrl;
      
      var shorts = records.items.map((record) {
        var shortItem = Shorts.fromRecord(record);
        
        // Fix video URL with proper base URL
        if (shortItem.videoUrl.isNotEmpty) {
          final videoField = record.data['video'] as String?;
          if (videoField != null && videoField.isNotEmpty) {
            final correctedVideoUrl = '$baseUrl/api/files/${record.collectionId}/${record.id}/$videoField';
            shortItem = shortItem.copyWith(videoUrl: correctedVideoUrl);
          }
        }
        
        return shortItem;
      }).toList();

      // Shuffle and take requested count
      shorts.shuffle();
      return shorts.take(count).toList();
    } catch (e) {
      debugPrint('Error fetching random shorts: $e');
      rethrow;
    }
  }

  /// Get shorts by artist
  Future<List<Shorts>> getShortsByArtist(String artistId, {
    int page = 1,
    int perPage = 10,
  }) async {
    return getShorts(
      page: page,
      perPage: perPage,
      filter: 'artist_id = "$artistId"',
    );
  }

  /// Increment view count for a short
  Future<void> incrementViewCount(String shortId) async {
    try {
      await _pocketBaseService.initialize();
      
      if (!_pocketBaseService.isAuthenticated) {
        return; // Silently fail if not authenticated
      }

      // Get current short data
      final record = await _pocketBaseService.pb.collection('shorts').getOne(shortId);
      final currentViews = record.data['views'] as int? ?? 0;

      // Update view count
      await _pocketBaseService.pb.collection('shorts').update(shortId, body: {
        'views': currentViews + 1,
      });
    } catch (e) {
      debugPrint('Error incrementing view count: $e');
      // Don't rethrow - view count is not critical
    }
  }

  /// Toggle like for a short
  Future<bool> toggleLike(String shortId) async {
    try {
      await _pocketBaseService.initialize();
      
      if (!_pocketBaseService.isAuthenticated) {
        throw Exception('User not authenticated');
      }

      // Get current short data
      final record = await _pocketBaseService.pb.collection('shorts').getOne(shortId);
      final currentLikes = record.data['likes'] as int? ?? 0;

      // For now, just increment likes (later we can add user-specific like tracking)
      await _pocketBaseService.pb.collection('shorts').update(shortId, body: {
        'likes': currentLikes + 1,
      });

      return true; // Return true to indicate liked
    } catch (e) {
      debugPrint('Error toggling like: $e');
      rethrow;
    }
  }

  /// Get trending shorts (most viewed/liked recently)
  Future<List<Shorts>> getTrendingShorts({
    int page = 1,
    int perPage = 10,
  }) async {
    return getShorts(
      page: page,
      perPage: perPage,
      sort: '-views,-likes,-created', // Sort by views, then likes, then recency
    );
  }
} 