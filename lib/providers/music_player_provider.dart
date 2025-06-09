import 'package:flutter/foundation.dart';
import '../models/song.dart';

/// Class for managing music player state using Provider pattern
class MusicPlayerProvider extends ChangeNotifier {
  Song? _currentSong;
  List<Song> _queue = [];
  int _currentIndex = 0;
  Duration _currentPosition = Duration.zero;
  bool _isPlaying = false;
  final bool _isBuffering = false;
  bool _isShuffleEnabled = false;
  bool _isRepeatEnabled = false;

  // Getters
  Song? get currentSong => _currentSong;
  List<Song> get queue => _queue;
  int get currentIndex => _currentIndex;
  Duration get currentPosition => _currentPosition;
  bool get isPlaying => _isPlaying;
  bool get isBuffering => _isBuffering;
  bool get isShuffleEnabled => _isShuffleEnabled;
  bool get isRepeatEnabled => _isRepeatEnabled;

  // Methods
  void playSong(Song song) {
    _currentSong = song;
    _isPlaying = true;
    _currentPosition = Duration.zero;
    notifyListeners();
  }

  void pause() {
    if (_isPlaying) {
      _isPlaying = false;
      notifyListeners();
    }
  }

  void resume() {
    if (!_isPlaying && _currentSong != null) {
      _isPlaying = true;
      notifyListeners();
    }
  }

  void togglePlayPause() {
    if (_currentSong != null) {
      _isPlaying = !_isPlaying;
      notifyListeners();
    }
  }

  void seekTo(Duration position) {
    _currentPosition = position;
    notifyListeners();
  }

  void nextSong() {
    if (_queue.isEmpty || _currentIndex >= _queue.length - 1) {
      return;
    }
    
    _currentIndex++;
    _currentSong = _queue[_currentIndex];
    _currentPosition = Duration.zero;
    notifyListeners();
  }

  void previousSong() {
    if (_queue.isEmpty || _currentIndex <= 0) {
      return;
    }
    
    _currentIndex--;
    _currentSong = _queue[_currentIndex];
    _currentPosition = Duration.zero;
    notifyListeners();
  }

  void toggleShuffle() {
    _isShuffleEnabled = !_isShuffleEnabled;
    
    if (_isShuffleEnabled && _queue.isNotEmpty) {
      // Shuffle the queue but keep current song as first
      final currentSong = _currentSong;
      final List<Song> shuffledQueue = List.from(_queue)..shuffle();
      
      if (currentSong != null) {
        shuffledQueue.remove(currentSong);
        shuffledQueue.insert(0, currentSong);
      }
      
      _queue = shuffledQueue;
      _currentIndex = 0;
    }
    
    notifyListeners();
  }

  void toggleRepeat() {
    _isRepeatEnabled = !_isRepeatEnabled;
    notifyListeners();
  }
} 