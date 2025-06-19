import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Global video audio manager to prevent conflicts between music player and video shorts
class VideoAudioManager extends StateNotifier<VideoAudioState> {
  VideoAudioManager() : super(VideoAudioState.initial());

  /// Call this when music starts playing
  void musicStarted() {
    if (state.isMusicPlaying != true) {
      state = state.copyWith(isMusicPlaying: true);
      debugPrint('🎵 Music started - videos should pause');
    }
  }

  /// Call this when music stops
  void musicStopped() {
    if (state.isMusicPlaying != false) {
      state = state.copyWith(isMusicPlaying: false);
      debugPrint('🎵 Music stopped - videos can resume');
    }
  }

  /// Call this when app goes to background
  void appPaused() {
    state = state.copyWith(isAppInBackground: true);
    debugPrint('📱 App paused - videos should pause');
  }

  /// Call this when app comes to foreground
  void appResumed() {
    state = state.copyWith(isAppInBackground: false);
    debugPrint('📱 App resumed - videos can resume if music not playing');
  }

  /// Check if videos should be paused
  bool get shouldPauseVideos => state.isMusicPlaying || state.isAppInBackground;
}

/// State class for video audio management
class VideoAudioState {
  final bool isMusicPlaying;
  final bool isAppInBackground;

  const VideoAudioState({
    required this.isMusicPlaying,
    required this.isAppInBackground,
  });

  factory VideoAudioState.initial() => const VideoAudioState(
    isMusicPlaying: false,
    isAppInBackground: false,
  );

  VideoAudioState copyWith({
    bool? isMusicPlaying,
    bool? isAppInBackground,
  }) {
    return VideoAudioState(
      isMusicPlaying: isMusicPlaying ?? this.isMusicPlaying,
      isAppInBackground: isAppInBackground ?? this.isAppInBackground,
    );
  }

  /// Videos should be paused if music is playing OR app is in background
  bool get shouldPauseVideos => isMusicPlaying || isAppInBackground;
}

/// Global provider for video audio management
final videoAudioManagerProvider = StateNotifierProvider<VideoAudioManager, VideoAudioState>(
  (ref) => VideoAudioManager(),
); 