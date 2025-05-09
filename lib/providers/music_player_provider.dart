import 'package:flutter/material.dart';
import '../models/song.dart';

enum PlaybackState {
  playing,
  paused,
  stopped,
  loading
}

class MusicPlayerProvider extends ChangeNotifier {
  Song? _currentSong;
  Duration _currentPosition = Duration.zero;
  PlaybackState _playbackState = PlaybackState.stopped;
  bool _isShuffleEnabled = false;
  bool _isRepeatEnabled = false;

  Song? get currentSong => _currentSong;
  Duration get currentPosition => _currentPosition;
  PlaybackState get playbackState => _playbackState;
  bool get isShuffleEnabled => _isShuffleEnabled;
  bool get isRepeatEnabled => _isRepeatEnabled;
  bool get isPlaying => _playbackState == PlaybackState.playing;

  void playSong(Song song) {
    _currentSong = song;
    _currentPosition = Duration.zero;
    _playbackState = PlaybackState.playing;
    notifyListeners();
  }

  void togglePlayPause() {
    if (_currentSong != null) {
      if (_playbackState == PlaybackState.playing) {
        _playbackState = PlaybackState.paused;
      } else {
        _playbackState = PlaybackState.playing;
      }
      notifyListeners();
    }
  }

  void nextSong() {
    // Implementation would depend on playlist management
    notifyListeners();
  }

  void previousSong() {
    // Implementation would depend on playlist management
    notifyListeners();
  }

  void updatePosition(Duration position) {
    _currentPosition = position;
    notifyListeners();
  }

  void seekTo(Duration position) {
    _currentPosition = position;
    notifyListeners();
  }

  void toggleShuffle() {
    _isShuffleEnabled = !_isShuffleEnabled;
    notifyListeners();
  }

  void toggleRepeat() {
    _isRepeatEnabled = !_isRepeatEnabled;
    notifyListeners();
  }
} 