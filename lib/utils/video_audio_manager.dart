import 'package:flutter_riverpod/flutter_riverpod.dart';

/// State for coordinating video and audio playback
class VideoAudioManagerState {
  final bool isMusicPlaying;
  final bool shouldPauseVideos;
  final bool isAppPaused;

  const VideoAudioManagerState({
    this.isMusicPlaying = false,
    this.shouldPauseVideos = false,
    this.isAppPaused = false,
  });

  VideoAudioManagerState copyWith({
    bool? isMusicPlaying,
    bool? shouldPauseVideos,
    bool? isAppPaused,
  }) {
    return VideoAudioManagerState(
      isMusicPlaying: isMusicPlaying ?? this.isMusicPlaying,
      shouldPauseVideos: shouldPauseVideos ?? this.shouldPauseVideos,
      isAppPaused: isAppPaused ?? this.isAppPaused,
    );
  }
}

/// Controller for managing video and audio coordination
class VideoAudioManagerController extends StateNotifier<VideoAudioManagerState> {
  VideoAudioManagerController() : super(const VideoAudioManagerState());

  /// Called when music starts playing
  void musicStarted() {
    state = state.copyWith(
      isMusicPlaying: true,
      shouldPauseVideos: true,
    );
  }

  /// Called when music stops
  void musicStopped() {
    state = state.copyWith(
      isMusicPlaying: false,
      shouldPauseVideos: false,
    );
  }

  /// Called when app is paused (goes to background)
  void appPaused() {
    state = state.copyWith(
      isAppPaused: true,
      shouldPauseVideos: true,
    );
  }

  /// Called when app resumes (comes to foreground)
  void appResumed() {
    state = state.copyWith(
      isAppPaused: false,
      shouldPauseVideos: state.isMusicPlaying, // Only pause if music is playing
    );
  }

  /// Manually set video pause state
  void setShouldPauseVideos(bool shouldPause) {
    state = state.copyWith(shouldPauseVideos: shouldPause);
  }

  /// Check if videos should be paused (due to music or app state)
  bool get shouldPauseVideos => state.shouldPauseVideos || state.isAppPaused;
}

/// Provider for video audio manager
final videoAudioManagerProvider = StateNotifierProvider<VideoAudioManagerController, VideoAudioManagerState>((ref) {
  return VideoAudioManagerController();
});
