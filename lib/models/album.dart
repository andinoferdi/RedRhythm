import 'package:flutter/foundation.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import '../services/pocketbase_service.dart';

part 'album.g.dart';
part 'album.freezed.dart';

@freezed
class Album with _$Album {
  const factory Album({
    required String id,
    required String title,
    required String artistName,
    required String artistId,
    String? coverImageUrl,
    String? coverImageFilename,
    @Default(0) int releaseYear,
    DateTime? releaseDate,
    String? description,
    @Default(0) int trackCount,
    required DateTime created,
    required DateTime updated,
  }) = _Album;

  factory Album.fromJson(Map<String, dynamic> json) => _$AlbumFromJson(json);
  
  /// Create an Album from a PocketBase record
  static Album fromRecord(RecordModel record) {
    // Get expanded artist if available
    final artistRecord = record.expand['artist_id']?[0];
    final artistName = artistRecord?.data['name'] as String? ?? 'Unknown Artist';
    final artistId = record.data['artist_id'] as String? ?? '';
    
    // Extract cover image URL
    String? coverImageUrl;
    String? coverImageFilename;
    
    if (record.data['cover_image'] != null) {
      try {
        final coverImage = record.data['cover_image'] as String;
        
        if (coverImage.trim().isNotEmpty) {
          coverImageFilename = coverImage.trim();
          
          // Validate filename format
          if (coverImage.contains('.') && !coverImage.startsWith('.') && 
              !coverImage.endsWith('.') && coverImage.length >= 3) {
            
            final pbService = PocketBaseService();
            final baseUrl = pbService.pb.baseUrl;
            final collectionId = record.collectionId;
            final recordId = record.id;
            
            if (baseUrl.trim().isNotEmpty && 
                collectionId.trim().isNotEmpty && 
                recordId.trim().isNotEmpty) {
              
              coverImageUrl = '$baseUrl/api/files/$collectionId/$recordId/$coverImage';
              
              // Validate generated URL
              if (!_isValidPocketBaseUrl(coverImageUrl!)) {
                coverImageUrl = null;
                coverImageFilename = null;
              }
            }
          }
        }
      } catch (e) {
        debugPrint('Error processing album cover image: $e');
        coverImageUrl = null;
        coverImageFilename = null;
      }
    }
    
    // Parse release date
    DateTime? releaseDate;
    try {
      final releaseDateStr = record.data['release_date'] as String?;
      if (releaseDateStr != null && releaseDateStr.isNotEmpty) {
        releaseDate = DateTime.parse(releaseDateStr);
      }
    } catch (e) {
      debugPrint('Error parsing release_date: $e');
      releaseDate = null;
    }
    
    return Album(
      id: record.id,
      title: record.data['title'] as String? ?? record.data['name'] as String? ?? 'Unknown Album',
      artistName: artistName,
      artistId: artistId,
      coverImageUrl: coverImageUrl,
      coverImageFilename: coverImageFilename,
      releaseYear: record.data['release_year'] as int? ?? 0,
      releaseDate: releaseDate,
      description: record.data['description'] as String?,
      trackCount: record.data['track_count'] as int? ?? 0,
      created: DateTime.parse(record.created),
      updated: DateTime.parse(record.updated),
    );
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

/// Extension for Album utility methods
extension AlbumExt on Album {
  /// Get formatted release year for display
  String get formattedReleaseYear {
    if (releaseDate != null) {
      return releaseDate!.year.toString();
    } else if (releaseYear > 0) {
      return releaseYear.toString();
    }
    return 'Unknown Year';
  }
  
  /// Get formatted track count for display
  String get formattedTrackCount {
    if (trackCount <= 0) {
      return 'No tracks';
    } else if (trackCount == 1) {
      return '1 track';
    } else {
      return '$trackCount tracks';
    }
  }
} 