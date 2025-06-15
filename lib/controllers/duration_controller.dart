import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import '../services/audio_duration_service.dart';
import '../services/pocketbase_service.dart';
import '../models/song.dart';

/// State for duration update operations
@immutable
class DurationUpdateState {
  final bool isUpdating;
  final int totalSongs;
  final int processedSongs;
  final int successCount;
  final int failCount;
  final String? currentSongTitle;
  final String? error;

  const DurationUpdateState({
    this.isUpdating = false,
    this.totalSongs = 0,
    this.processedSongs = 0,
    this.successCount = 0,
    this.failCount = 0,
    this.currentSongTitle,
    this.error,
  });

  DurationUpdateState copyWith({
    bool? isUpdating,
    int? totalSongs,
    int? processedSongs,
    int? successCount,
    int? failCount,
    String? currentSongTitle,
    String? error,
  }) {
    return DurationUpdateState(
      isUpdating: isUpdating ?? this.isUpdating,
      totalSongs: totalSongs ?? this.totalSongs,
      processedSongs: processedSongs ?? this.processedSongs,
      successCount: successCount ?? this.successCount,
      failCount: failCount ?? this.failCount,
      currentSongTitle: currentSongTitle ?? this.currentSongTitle,
      error: error ?? this.error,
    );
  }

  double get progress {
    if (totalSongs == 0) return 0.0;
    return processedSongs / totalSongs;
  }

  bool get isCompleted => processedSongs >= totalSongs && totalSongs > 0;
}

/// Controller for managing duration updates
class DurationController extends StateNotifier<DurationUpdateState> {
  final AudioDurationService _audioService = GetIt.I<AudioDurationService>();

  DurationController() : super(const DurationUpdateState());

  /// Update single song duration
  Future<bool> updateSingleSongDuration(Song song) async {
    try {
      state = state.copyWith(
        isUpdating: true,
        currentSongTitle: song.title,
        error: null,
      );

      final success = await _audioService.updateSongDuration(song);

      state = state.copyWith(
        isUpdating: false,
        currentSongTitle: null,
      );

      return success;
    } catch (e) {
      state = state.copyWith(
        isUpdating: false,
        error: e.toString(),
        currentSongTitle: null,
      );
      return false;
    }
  }

  /// Update all songs with missing duration
  Future<void> updateAllSongsDuration() async {
    try {
      state = state.copyWith(
        isUpdating: true,
        totalSongs: 0,
        processedSongs: 0,
        successCount: 0,
        failCount: 0,
        error: null,
      );

      // Get all songs with duration = 0
      final pbService = GetIt.I<PocketBaseService>();
      final response = await pbService.pb.collection('songs').getList(
        page: 1,
        perPage: 500,
        filter: 'duration = 0',
        expand: 'artist_id,album_id',
      );

      final List<Song> songsToUpdate = response.items
          .map((record) => Song.fromRecord(record))
          .toList();

      if (songsToUpdate.isEmpty) {
        state = state.copyWith(
          isUpdating: false,
          totalSongs: 0,
        );
        return;
      }

      state = state.copyWith(totalSongs: songsToUpdate.length);

      int successCount = 0;
      int failCount = 0;

      // Process each song
      for (int i = 0; i < songsToUpdate.length; i++) {
        final song = songsToUpdate[i];
        
        state = state.copyWith(
          currentSongTitle: song.title,
          processedSongs: i,
        );

        final success = await _audioService.updateSongDuration(song);
        if (success) {
          successCount++;
        } else {
          failCount++;
        }

        state = state.copyWith(
          successCount: successCount,
          failCount: failCount,
          processedSongs: i + 1,
        );

        // Add small delay to avoid overwhelming the server
        await Future.delayed(const Duration(milliseconds: 500));
      }

      state = state.copyWith(
        isUpdating: false,
        currentSongTitle: null,
      );

      debugPrint('📈 Duration update completed:');
      debugPrint('✅ Success: $successCount songs');
      debugPrint('❌ Failed: $failCount songs');
      debugPrint('📊 Total processed: ${songsToUpdate.length} songs');

    } catch (e) {
      state = state.copyWith(
        isUpdating: false,
        error: e.toString(),
        currentSongTitle: null,
      );
      debugPrint('❌ Error in bulk song duration update: $e');
    }
  }

  /// Clear error state
  void clearError() {
    state = state.copyWith(error: null);
  }

  /// Reset state
  void reset() {
    state = const DurationUpdateState();
  }
}

/// Provider for the duration controller
final durationControllerProvider = StateNotifierProvider<DurationController, DurationUpdateState>((ref) {
  return DurationController();
}); 