import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../utils/color_extractor.dart';
import '../models/song.dart';

/// Provider for managing dynamic colors based on current song's album art
final dynamicColorProvider = StateNotifierProvider<DynamicColorNotifier, DynamicColorState>((ref) {
  return DynamicColorNotifier();
});

class DynamicColorNotifier extends StateNotifier<DynamicColorState> {
  DynamicColorNotifier() : super(DynamicColorState.initial());
  
  /// Extract colors from song's album art
  Future<void> extractColorsFromSong(Song song) async {
    // Don't extract if same song and colors already extracted
    if (state.currentSongId == song.id && state.colors != null && !state.isLoading) {
      return;
    }
    
    // Set loading state
    state = state.copyWith(
      isLoading: true,
      currentSongId: song.id,
    );
    
    try {
      // Extract colors from album art URL
      final colors = await ColorExtractor.extractColorsFromUrl(song.albumArtUrl);
      
      // Update state with extracted colors
      state = state.copyWith(
        colors: colors,
        isLoading: false,
        hasError: false,
      );
    } catch (e) {
      // Set error state with default colors
      state = state.copyWith(
        colors: ColorExtractor.getDefaultColors(),
        isLoading: false,
        hasError: true,
      );
    }
  }
  
  /// Reset to default colors
  void resetToDefault() {
    state = DynamicColorState.initial();
  }
  
  /// Clear colors for specific song
  void clearColorsForSong(String songId) {
    if (state.currentSongId == songId) {
      state = DynamicColorState.initial();
    }
  }
}

/// State class for dynamic colors
class DynamicColorState {
  final DominantColors? colors;
  final bool isLoading;
  final bool hasError;
  final String? currentSongId;
  
  const DynamicColorState({
    this.colors,
    this.isLoading = false,
    this.hasError = false,
    this.currentSongId,
  });
  
  /// Initial state with default colors
  factory DynamicColorState.initial() {
    return DynamicColorState(
      colors: ColorExtractor.getDefaultColors(),
      isLoading: false,
      hasError: false,
      currentSongId: null,
    );
  }
  
  /// Copy with method for state updates
  DynamicColorState copyWith({
    DominantColors? colors,
    bool? isLoading,
    bool? hasError,
    String? currentSongId,
  }) {
    return DynamicColorState(
      colors: colors ?? this.colors,
      isLoading: isLoading ?? this.isLoading,
      hasError: hasError ?? this.hasError,
      currentSongId: currentSongId ?? this.currentSongId,
    );
  }
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DynamicColorState &&
          runtimeType == other.runtimeType &&
          colors == other.colors &&
          isLoading == other.isLoading &&
          hasError == other.hasError &&
          currentSongId == other.currentSongId;

  @override
  int get hashCode =>
      colors.hashCode ^
      isLoading.hashCode ^
      hasError.hashCode ^
      currentSongId.hashCode;
} 