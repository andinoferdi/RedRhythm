
import '../models/artist.dart';
import '../services/pocketbase_service.dart';
import 'dart:io';
import 'package:http/http.dart' as http;

class ArtistRepository {
  final PocketBaseService _pocketBaseService;

  ArtistRepository(this._pocketBaseService);

  /// Create a new artist
  Future<Artist?> createArtist({
    required String name,
    required String bio,
    File? imageFile,
  }) async {
    try {
      final pb = _pocketBaseService.pb;
      
      // Prepare data for creation
      final data = <String, dynamic>{
        'name': name,
        'bio': bio,
      };

      // Add image file if provided
      if (imageFile != null) {
        data['image'] = await http.MultipartFile.fromPath('image', imageFile.path);
      }

      // Create the artist record
      final record = await pb.collection('artists').create(body: data);
      
      return Artist.fromRecord(record, pb);
    } catch (e) {
      return null;
    }
  }

  /// Get artist by name
  Future<Artist?> getArtistByName(String artistName) async {
    try {
      final pb = _pocketBaseService.pb;
      
      // Search for artist by name (case-insensitive)
      final records = await pb.collection('artists').getList(
        page: 1,
        perPage: 1,
        filter: 'name ~ "$artistName"',
      );

      if (records.items.isNotEmpty) {
        return Artist.fromRecord(records.items.first, pb);
      }
      
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Get artist by ID
  Future<Artist?> getArtistById(String artistId) async {
    try {
      final pb = _pocketBaseService.pb;
      final record = await pb.collection('artists').getOne(artistId);
      return Artist.fromRecord(record, pb);
    } catch (e) {
      return null;
    }
  }

  /// Get all artists
  Future<List<Artist>> getAllArtists() async {
    try {
      final pb = _pocketBaseService.pb;
      final records = await pb.collection('artists').getFullList(
        sort: 'name',
      );
      
      return records.map((record) => Artist.fromRecord(record, pb)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Search artists by name
  Future<List<Artist>> searchArtists(String query) async {
    try {
      final pb = _pocketBaseService.pb;
      final records = await pb.collection('artists').getList(
        page: 1,
        perPage: 50,
        filter: 'name ~ "$query"',
        sort: 'name',
      );
      
      return records.items.map((record) => Artist.fromRecord(record, pb)).toList();
    } catch (e) {
      return [];
    }
  }

  /// Update artist
  Future<Artist?> updateArtist({
    required String artistId,
    String? name,
    String? bio,
    File? imageFile,
  }) async {
    try {
      final pb = _pocketBaseService.pb;
      
      final data = <String, dynamic>{};
      
      if (name != null) data['name'] = name;
      if (bio != null) data['bio'] = bio;
      if (imageFile != null) {
        data['image'] = await http.MultipartFile.fromPath('image', imageFile.path);
      }

      final record = await pb.collection('artists').update(artistId, body: data);
      return Artist.fromRecord(record, pb);
    } catch (e) {
      return null;
    }
  }

  /// Delete artist
  Future<bool> deleteArtist(String artistId) async {
    try {
      final pb = _pocketBaseService.pb;
      await pb.collection('artists').delete(artistId);
      return true;
    } catch (e) {
      return false;
    }
  }
}
