import 'package:flutter/foundation.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import '../services/pocketbase_service.dart';

part 'song.g.dart';
part 'song.freezed.dart';

@freezed
class Song with _$Song {
  const factory Song({
    required String id,
    required String title,
    required String artist,
    required String albumArtUrl,
    required int durationInSeconds,
    required String albumName,
    String? lyrics,
    String? playlistId,
    String? audioFileUrl,
    String? audioFileName,
  }) = _Song;

  factory Song.fromJson(Map<String, dynamic> json) => _$SongFromJson(json);
  
  /// Create a Song from a PocketBase record
  static Song fromRecord(RecordModel record) {
    // Get expanded artist and album if available
    final artistRecord = record.expand['artist_id']?[0];
    final albumRecord = record.expand['album_id']?[0];
    
    // Extract artist name
    final artistName = artistRecord?.data['name'] as String? ?? 'Unknown Artist';
    
    // Extract album name - try 'title' first, then 'name'
    String albumName = 'Unknown Album';
    if (albumRecord != null) {
      albumName = albumRecord.data['title'] as String? ?? 
                  albumRecord.data['name'] as String? ?? 
                  'Unknown Album';
    }
    
    // Extract album cover URL
    String albumArtUrl = '';
    if (albumRecord != null && albumRecord.data['cover_image'] != null) {
      try {
        final coverImage = albumRecord.data['cover_image'];
        if (coverImage is String && coverImage.isNotEmpty) {
          // Generate proper PocketBase file URL using service
          final pbService = PocketBaseService();
          albumArtUrl = '${pbService.pb.baseUrl}/api/files/${albumRecord.collectionId}/${albumRecord.id}/$coverImage';
        }
      } catch (e) {
        // Silently handle album cover URL generation errors
      }
    }
    
    final lyrics = record.data['lyrics'] as String?;
    
    // Get audio file information
    String? audioFileName;
    
    // Nama field audio di PocketBase
    const String audioField = 'audio_file';
    
    // Cek apakah field audio_file ada dan berisi nilai
    if (record.data.containsKey(audioField) && record.data[audioField] != null) {
      final audioFileValue = record.data[audioField];
      
      // PocketBase menyimpan nama file di field, ambil nama file jika bisa
      if (audioFileValue is String && audioFileValue.isNotEmpty) {
        audioFileName = audioFileValue;
      }
    }
    
    return Song(
      id: record.id,
      title: record.data['title'] as String? ?? 'Unknown Title',
      artist: artistName,
      albumArtUrl: albumArtUrl,
      durationInSeconds: record.data['duration'] as int? ?? 0,
      albumName: albumName,
      lyrics: lyrics,
      playlistId: record.data['playlist_id'] as String?,
      audioFileName: audioFileName,
      audioFileUrl: null, // URL akan dibuat di PlayerController
    );
  }
}

/// Extension to convert duration in seconds to Duration
extension DurationExt on Song {
  Duration get duration => Duration(seconds: durationInSeconds);
}
