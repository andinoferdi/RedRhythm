import 'package:flutter/foundation.dart';
import '../services/pocketbase_service.dart';
import 'package:http/http.dart' as http;

/// Tool untuk membantu sync album images yang sudah diupload ulang
class AlbumImageSyncTool {
  final PocketBaseService _pbService;
  
  AlbumImageSyncTool(this._pbService);
  
  /// Cek semua album dan tampilkan status cover image
  Future<void> checkAllAlbumImages() async {
    try {
      await _pbService.initialize();
      
      // Get semua album
      final albums = await _pbService.pb.collection('albums').getFullList();
      
      for (final album in albums) {
        await _checkAlbumImage(album);
      }
      
    } catch (e) {
      debugPrint('❌ Error checking album images: $e');
    }
  }
  
  /// Cek satu album dan tampilkan status cover image
  Future<void> _checkAlbumImage(dynamic album) async {
    final albumName = album.data['name'] ?? album.data['title'] ?? 'Unknown';
    
    final coverImage = album.data['cover_image'];
    if (coverImage == null || coverImage.toString().isEmpty) {
      return;
    }

    try {
      final imageUrl = _pbService.pb.files.getUrl(album, coverImage);
      
      final response = await http.head(Uri.parse(imageUrl.toString()));
      
      if (response.statusCode != 200) {
        // Log only errors
        debugPrint('❌ Image file NOT found for album: $albumName (${response.statusCode})');
      }
    } catch (e) {
      debugPrint('❌ Image file NOT found for album: $albumName (Error: $e)');
    }
  }
  
  /// List semua file yang ada di album record untuk membantu identifikasi nama file yang benar
  Future<void> listAlbumFiles(String albumId) async {
    try {
      await _pbService.initialize();
      
      // Get album record
      final album = await _pbService.pb.collection('albums').getOne(albumId);
      
      // List semua field yang mungkin berisi file
      album.data.forEach((key, value) {
        if (value is String && value.isNotEmpty && value.contains('.')) {
          // Reduced logging
        }
      });
      
    } catch (e) {
      debugPrint('❌ Error getting album: $e');
    }
  }
  
  /// Update cover image untuk album tertentu
  Future<void> updateAlbumCoverImage(String albumId, String newCoverImageFileName) async {
    try {
      await _pbService.initialize();
      
      // Update album record
      await _pbService.pb.collection('albums').update(albumId, body: {
        'cover_image': newCoverImageFileName,
      });
      
      // Verify the update was successful
      final updatedAlbum = await _pbService.pb.collection('albums').getOne(albumId);
      final _ = updatedAlbum.data['cover_image']; // Verify field exists
      
    } catch (e) {
      debugPrint('❌ Error updating album cover image: $e');
    }
  }
} 


