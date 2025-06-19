import 'package:flutter/foundation.dart';
import 'package:pocketbase/pocketbase.dart';
import '../models/shorts.dart';
import '../services/pocketbase_service.dart';

class ShortsRepository {
  final PocketBaseService _pbService;
  late final PocketBase _pb;

  ShortsRepository(this._pbService) {
    _pb = _pbService.pb;
  }

  /// Get all shorts with pagination
  Future<List<Shorts>> getShorts({
    int page = 1,
    int limit = 20,
    String? genreFilter,
    String? searchQuery,
  }) async {
    try {
      debugPrint('🔍 Fetching shorts from collection: shorts');
      
      String filter = '';
      
      // Add search query if specified
      if (searchQuery != null && searchQuery.isNotEmpty) {
        filter = 'title ~ "$searchQuery" || hashtags ~ "$searchQuery"';
      }

      debugPrint('🔍 Query filter: $filter');
      debugPrint('🔍 PocketBase URL: ${_pb.baseUrl}');

      final resultList = await _pb.collection('shorts').getList(
        page: page,
        perPage: limit,
        filter: filter.isEmpty ? null : filter,
        sort: '-created', // Most recent first
        expand: 'artist_id,song_id,genres_id',
      );

      debugPrint('✅ Found ${resultList.items.length} shorts in database');
      
      final shorts = resultList.items.map((record) {
        debugPrint('📹 Processing record: ${record.id}');
        debugPrint('📹 Record data: ${record.data}');
        debugPrint('📹 Record expand: ${record.expand}');
        return _recordToShorts(record);
      }).toList();

      debugPrint('✅ Converted ${shorts.length} shorts to models');
      
      // Apply genre filter in memory if specified
      if (genreFilter != null && genreFilter.isNotEmpty) {
        debugPrint('🔍 Applying genre filter in memory: $genreFilter');
        final filteredShorts = shorts.where((short) {
          // Filter by genre_id (from song) or artist_id
          final matchesGenre = short.genresId == genreFilter;
          final matchesArtist = short.artistId == genreFilter;
          
          debugPrint('📹 Short ${short.id}: genresId=${short.genresId}, artistId=${short.artistId}, filter=$genreFilter');
          debugPrint('📹 Matches genre: $matchesGenre, Matches artist: $matchesArtist');
          
          return matchesGenre || matchesArtist;
        }).toList();
        
        debugPrint('✅ Filtered to ${filteredShorts.length} shorts');
        return filteredShorts;
      }
      
      return shorts;
    } catch (e) {
      debugPrint('❌ Error fetching shorts: $e');
      rethrow;
    }
  }

  /// Get shorts by genre
  Future<List<Shorts>> getShortsByGenre(String genreId, {int limit = 10}) async {
    return getShorts(genreFilter: genreId, limit: limit);
  }

  /// Get a single short by ID
  Future<Shorts?> getShortsById(String id) async {
    try {
      final record = await _pb.collection('shorts').getOne(
        id,
        expand: 'artist_id,song_id,genres_id',
      );
      return _recordToShorts(record);
    } catch (e) {
      return null;
    }
  }

  /// Increment view count for a short
  Future<void> incrementViews(String shortId) async {
    try {
      // Get current short
      final current = await _pb.collection('shorts').getOne(shortId);
      final currentViews = current.data['views'] ?? 0;
      
      // Update with incremented view count
      await _pb.collection('shorts').update(shortId, body: {
        'views': currentViews + 1,
      });
    } catch (e) {
      // Silently fail for view increments to not disrupt UX
      debugPrint('Failed to increment views for short $shortId: $e');
    }
  }

  /// Toggle like for a short (simplified - in real app would track user likes)
  Future<void> toggleLike(String shortId) async {
    try {
      // Get current short
      final current = await _pb.collection('shorts').getOne(shortId);
      final currentLikes = current.data['likes'] ?? 0;
      
      // For now, just increment likes (in real app, you'd check if user already liked)
      await _pb.collection('shorts').update(shortId, body: {
        'likes': currentLikes + 1,
      });
    } catch (e) {
      throw Exception('Failed to toggle like for short $shortId: $e');
    }
  }

  /// Search shorts by query
  Future<List<Shorts>> searchShorts(String query, {int limit = 20}) async {
    return getShorts(searchQuery: query, limit: limit);
  }

  /// Get trending shorts (most viewed in last 7 days)
  Future<List<Shorts>> getTrendingShorts({int limit = 20}) async {
    try {
      final sevenDaysAgo = DateTime.now().subtract(const Duration(days: 7));
      
      final resultList = await _pb.collection('shorts').getList(
        page: 1,
        perPage: limit,
        filter: 'created >= "${sevenDaysAgo.toIso8601String()}"',
        sort: '-views,-likes', // Sort by views and likes
        expand: 'artist_id,song_id,genres_id',
      );

      return resultList.items.map((record) => _recordToShorts(record)).toList();
    } catch (e) {
      throw Exception('Failed to fetch trending shorts: $e');
    }
  }

  /// Get recent shorts (latest uploads)
  Future<List<Shorts>> getRecentShorts({int limit = 20}) async {
    try {
      final resultList = await _pb.collection('shorts').getList(
        page: 1,
        perPage: limit,
        sort: '-created',
        expand: 'artist_id,song_id,genres_id',
      );

      return resultList.items.map((record) => _recordToShorts(record)).toList();
    } catch (e) {
      throw Exception('Failed to fetch recent shorts: $e');
    }
  }

  /// Convert PocketBase record to Shorts model
  Shorts _recordToShorts(RecordModel record) {
    final data = record.data;
    
    // Extract expanded data safely handling both List and RecordModel
    String? artistName;
    String? songTitle;
    String? genreIdFromSong;
    
    try {
      // Parse artist expand data - PocketBase can return List<RecordModel>
      final artistExpand = record.expand?['artist_id'];
      if (artistExpand != null) {
        if (artistExpand is List) {
          if (artistExpand.isNotEmpty) {
            final artistRecord = artistExpand.first;
            if (artistRecord is RecordModel) {
              artistName = artistRecord.data['name'] as String?;
            }
          }
        } else if (artistExpand is RecordModel) {
          artistName = (artistExpand as RecordModel).data['name'] as String?;
        }
      }

      // Parse song expand data
      final songExpand = record.expand?['song_id'];
      if (songExpand != null) {
        if (songExpand is List) {
          if (songExpand.isNotEmpty) {
            final songRecord = songExpand.first;
            if (songRecord is RecordModel) {
              songTitle = songRecord.data['title'] as String?;
              genreIdFromSong = songRecord.data['genre_id'] as String?;
            }
          }
        } else if (songExpand is RecordModel) {
          songTitle = (songExpand as RecordModel).data['title'] as String?;
          genreIdFromSong = (songExpand as RecordModel).data['genre_id'] as String?;
        }
      }
    } catch (e) {
      debugPrint('❌ Error parsing expand data: $e');
      // Continue with null values
    }

    // Generate video URL from filename
    final String videoFileName = data['video'] as String? ?? '';
    final String videoUrl = videoFileName.isNotEmpty 
        ? '${_pb.baseUrl}/api/files/${record.collectionId}/${record.id}/$videoFileName'
        : '';

    debugPrint('📹 Video filename: $videoFileName');
    debugPrint('📹 Generated video URL: $videoUrl');

    // Get genre ID - prioritize direct field, then from song
    String genreId = data['genres_id'] as String? ?? '';
    if (genreId.isEmpty && genreIdFromSong != null && genreIdFromSong.isNotEmpty) {
      genreId = genreIdFromSong;
      debugPrint('📹 Using genre_id from song: $genreId');
    }

    debugPrint('📹 Short data: Shorts(id: ${record.id}, genresId: $genreId, videoUrl: $videoUrl, artistId: ${data['artist_id']}, songId: ${data['song_id']}, title: ${data['title']}, hashtags: ${data['hashtags']}, artistName: ${artistName ?? 'Unknown Artist'}, songTitle: ${songTitle ?? 'Unknown Song'}, thumbnailUrl: ${data['thumbnail_url']}, views: ${data['views'] ?? 0}, likes: ${data['likes'] ?? 0}, createdAt: ${record.created}, updatedAt: ${record.updated})');
    debugPrint('📹 Final Genre ID: $genreId');

    return Shorts(
      id: record.id,
      genresId: genreId,
      videoUrl: videoUrl,
      artistId: data['artist_id'] as String? ?? '',
      songId: data['song_id'] as String? ?? '',
      title: data['title'] as String?,
      hashtags: data['hashtags'] as String?,
      artistName: artistName ?? 'Unknown Artist',
      songTitle: songTitle ?? 'Unknown Song',
      thumbnailUrl: data['thumbnail_url'] as String?,
      views: data['views'] as int? ?? 0,
      likes: data['likes'] as int? ?? 0,
      createdAt: record.created.isNotEmpty 
          ? DateTime.parse(record.created) 
          : null,
      updatedAt: record.updated.isNotEmpty 
          ? DateTime.parse(record.updated) 
          : null,
    );
  }

  /// Create a new short (for admin/upload functionality)
  Future<Shorts?> createShort({
    required String genresId,
    required String videoUrl,
    required String artistId,
    required String songId,
    String? title,
    String? hashtags,
    String? thumbnailUrl,
  }) async {
    try {
      final record = await _pb.collection('shorts').create(body: {
        'genres_id': genresId,
        'video': videoUrl,
        'artist_id': artistId,
        'song_id': songId,
        'title': title,
        'hashtags': hashtags,
        'thumbnail_url': thumbnailUrl,
        'views': 0,
        'likes': 0,
      });

      return _recordToShorts(record);
    } catch (e) {
      throw Exception('Failed to create short: $e');
    }
  }

  /// Delete a short (admin functionality)
  Future<void> deleteShort(String shortId) async {
    try {
      await _pb.collection('shorts').delete(shortId);
    } catch (e) {
      throw Exception('Failed to delete short $shortId: $e');
    }
  }

  /// Update short metadata
  Future<Shorts?> updateShort(
    String shortId, {
    String? title,
    String? hashtags,
    String? thumbnailUrl,
  }) async {
    try {
      final updateData = <String, dynamic>{};
      
      if (title != null) updateData['title'] = title;
      if (hashtags != null) updateData['hashtags'] = hashtags;
      if (thumbnailUrl != null) updateData['thumbnail_url'] = thumbnailUrl;
      
      if (updateData.isEmpty) return null;
      
      final record = await _pb.collection('shorts').update(shortId, body: updateData);
      return _recordToShorts(record);
    } catch (e) {
      throw Exception('Failed to update short $shortId: $e');
    }
  }
} 