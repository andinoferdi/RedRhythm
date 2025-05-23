import 'package:pocketbase/pocketbase.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

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
    required List<String> lyrics,
    String? playlistId,
    String? audioFileUrl,
    String? audioFileName,
  }) = _Song;

  factory Song.fromJson(Map<String, dynamic> json) => _$SongFromJson(json);
  
  /// Create a Song from a PocketBase record
  static Song fromRecord(RecordModel record) {
    // Get expanded artist and album if available
    final artistRecord = record.expand['artist']?[0];
    final albumRecord = record.expand['album']?[0];
    
    // Extract data from record
    final artistName = artistRecord?.data['name'] as String? ?? 'Unknown Artist';
    final albumName = albumRecord?.data['name'] as String? ?? 'Unknown Album';
    final albumArtUrl = albumRecord?.data['cover_url'] as String? ?? '';
    final lyrics = (record.data['lyrics'] as String?)?.split('\n') ?? <String>[];
    
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