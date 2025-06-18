
import '../models/artist_select.dart';
import '../services/pocketbase_service.dart';


class ArtistSelectRepository {
  final PocketBaseService _pbService;

  ArtistSelectRepository(this._pbService);

  /// Get all selected artists for current user
  Future<List<ArtistSelect>> getUserSelectedArtists() async {
    try {
      await _pbService.initialize(); // Make sure PocketBase is initialized
      final pb = _pbService.pb;
      final currentUser = pb.authStore.model;
      
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      final records = await pb.collection('artist_selects').getFullList(
        filter: 'user_id = "${currentUser.id}"',
        expand: 'artist_id',
        sort: '-created',
      );

      return records.map((record) => ArtistSelect.fromRecord(record, pb)).toList();
    } catch (e) {
      rethrow;
    }
  }

  /// Add artist to user's selections
  Future<ArtistSelect?> addArtistSelection(String artistId) async {
    try {
      await _pbService.initialize(); // Make sure PocketBase is initialized
      final pb = _pbService.pb;
      final currentUser = pb.authStore.model;
      
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Check if already selected
      final existing = await pb.collection('artist_selects').getFullList(
        filter: 'user_id = "${currentUser.id}" && artist_id = "$artistId"',
        expand: 'artist_id', // Add expand here too
      );

      if (existing.isNotEmpty) {
        // Already selected, return existing
        return ArtistSelect.fromRecord(existing.first, pb);
      }

      // Create new selection
      final record = await pb.collection('artist_selects').create(
        body: {
          'user_id': currentUser.id,
          'artist_id': artistId,
        },
      );

      // Fetch with expanded data
      final expandedRecord = await pb.collection('artist_selects').getOne(
        record.id,
        expand: 'artist_id',
      );

      return ArtistSelect.fromRecord(expandedRecord, pb);
    } catch (e) {
      return null;
    }
  }

  /// Remove artist from user's selections
  Future<bool> removeArtistSelection(String artistId) async {
    try {
      final pb = _pbService.pb;
      final currentUser = pb.authStore.model;
      
      if (currentUser == null) {
        throw Exception('User not authenticated');
      }

      // Find the selection record
      final records = await pb.collection('artist_selects').getFullList(
        filter: 'user_id = "${currentUser.id}" && artist_id = "$artistId"',
      );

      if (records.isEmpty) {
        return false; // Not found
      }

      // Delete the selection
      await pb.collection('artist_selects').delete(records.first.id);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Add multiple artist selections (for bulk operations)
  Future<List<ArtistSelect>> addMultipleArtistSelections(List<String> artistIds) async {
    final results = <ArtistSelect>[];
    
    for (final artistId in artistIds) {
      final result = await addArtistSelection(artistId);
      if (result != null) {
        results.add(result);
      }
    }
    
    return results;
  }

  /// Check if user has selected a specific artist
  Future<bool> isArtistSelected(String artistId) async {
    try {
      final pb = _pbService.pb;
      final currentUser = pb.authStore.model;
      
      if (currentUser == null) {
        return false;
      }

      final records = await pb.collection('artist_selects').getFullList(
        filter: 'user_id = "${currentUser.id}" && artist_id = "$artistId"',
      );

      return records.isNotEmpty;
    } catch (e) {
      return false;
    }
  }

  /// Get selected artist IDs for current user
  Future<List<String>> getSelectedArtistIds() async {
    try {
      final selections = await getUserSelectedArtists();
      return selections.map((selection) => selection.artistId).toList();
    } catch (e) {
      return [];
    }
  }
} 

