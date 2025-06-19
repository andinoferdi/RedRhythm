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
}
