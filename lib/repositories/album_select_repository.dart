import '../models/album_select.dart';
import '../services/pocketbase_service.dart';
import 'package:flutter/foundation.dart';

class AlbumSelectRepository {
  final PocketBaseService _pbService;

  AlbumSelectRepository(this._pbService);

  /// Get all selected albums for current user
  Future<List<AlbumSelect>> getUserSelectedAlbums() async {
    try {
      await _pbService.initialize(); // Make sure PocketBase is initialized
      final pb = _pbService.pb;
      final currentUser = pb.authStore.model;
      
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      final records = await pb.collection('album_selects').getFullList(
        filter: 'user_id = "${currentUser.id}"',
        expand: 'album_id,album_id.artist_id',
        sort: '-created',
      );

      return records.map((record) => AlbumSelect.fromRecord(record, pb)).toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Add album to user's selections
  Future<AlbumSelect?> addAlbumSelection(String albumId) async {
    try {
      await _pbService.initialize(); // Make sure PocketBase is initialized
      final pb = _pbService.pb;
      final currentUser = pb.authStore.model;
      
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Check if already selected
      final existing = await pb.collection('album_selects').getFullList(
        filter: 'user_id = "${currentUser.id}" && album_id = "$albumId"',
        expand: 'album_id,album_id.artist_id',
      );

      if (existing.isNotEmpty) {
        // Already selected, return existing
        return AlbumSelect.fromRecord(existing.first, pb);
      }

      // Create new selection
      final record = await pb.collection('album_selects').create(
        body: {
          'user_id': currentUser.id,
          'album_id': albumId,
        },
      );

      // Fetch with expanded data
      final expandedRecord = await pb.collection('album_selects').getOne(
        record.id,
        expand: 'album_id,album_id.artist_id',
      );

      return AlbumSelect.fromRecord(expandedRecord, pb);
    } catch (e) {
      return null;
    }
  }

  /// Remove album from user's selections
  Future<bool> removeAlbumSelection(String albumId) async {
    try {
      final pb = _pbService.pb;
      final currentUser = pb.authStore.model;
      
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Find the selection record
      final records = await pb.collection('album_selects').getFullList(
        filter: 'user_id = "${currentUser.id}" && album_id = "$albumId"',
      );

      if (records.isEmpty) {
        return false; // Not found
      }

      // Delete the selection
      await pb.collection('album_selects').delete(records.first.id);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Add multiple album selections (for bulk operations)
  Future<List<AlbumSelect>> addMultipleAlbumSelections(List<String> albumIds) async {
    final results = <AlbumSelect>[];
    
    for (final albumId in albumIds) {
      final result = await addAlbumSelection(albumId);
      if (result != null) {
        results.add(result);
      }
    }
    
    return results;
  }

  /// Check if user has selected a specific album
  Future<bool> isAlbumSelected(String albumId) async {
    try {
      final pb = _pbService.pb;
      final currentUser = pb.authStore.model;
      
      if (currentUser == null) {
        return false;
      }

      final records = await pb.collection('album_selects').getFullList(
        filter: 'user_id = "${currentUser.id}" && album_id = "$albumId"',
      );

      return records.isNotEmpty;
    } catch (e) {
      return false;
    }
  }
} 