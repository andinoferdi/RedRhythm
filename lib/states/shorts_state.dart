import 'package:freezed_annotation/freezed_annotation.dart';
import '../models/shorts.dart';

part 'shorts_state.freezed.dart';

@freezed
class ShortsState with _$ShortsState {
  const factory ShortsState({
    @Default([]) List<Shorts> shorts,
    @Default(0) int currentIndex,
    @Default(false) bool isLoading,
    @Default(false) bool isLoadingMore,
    @Default(false) bool hasReachedMax,
    @Default(false) bool isPlaying,
    @Default(false) bool isMuted,
    @Default(1.0) double volume,
    String? error,
    Shorts? currentShort,
  }) = _ShortsState;

  /// Initial state
  factory ShortsState.initial() => const ShortsState();

  /// Loading state
  factory ShortsState.loading() => const ShortsState(isLoading: true);

  /// Error state
  factory ShortsState.error(String error) => ShortsState(error: error);

  /// Loaded state with shorts
  factory ShortsState.loaded(List<Shorts> shorts) => ShortsState(
    shorts: shorts,
    currentShort: shorts.isNotEmpty ? shorts.first : null,
  );
}

/// Extension for ShortsState utility methods
extension ShortsStateX on ShortsState {
  /// Check if there are any shorts
  bool get hasShorts => shorts.isNotEmpty;

  /// Check if current index is valid
  bool get hasValidCurrentIndex => currentIndex >= 0 && currentIndex < shorts.length;

  /// Get current short safely
  Shorts? get safeCurrentShort => hasValidCurrentIndex ? shorts[currentIndex] : null;

  /// Check if we can go to next short
  bool get canGoNext => hasValidCurrentIndex && currentIndex < shorts.length - 1;

  /// Check if we can go to previous short
  bool get canGoPrevious => hasValidCurrentIndex && currentIndex > 0;

  /// Check if we should load more shorts (when near the end)
  bool get shouldLoadMore => hasValidCurrentIndex && 
                              currentIndex >= shorts.length - 3 && 
                              !hasReachedMax && 
                              !isLoadingMore;
} 