import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart' as just_audio;
import 'package:get_it/get_it.dart';
import '../../models/song.dart';
import '../../services/pocketbase_service.dart';
import '../../repositories/song_repository.dart';
import '../states/player_state.dart' as app_state;
import 'play_history_controller.dart';

/// Provider for player controller
final playerControllerProvider =
    StateNotifierProvider<PlayerController, app_state.PlayerState>(
  (ref) => PlayerController(ref),
);

/// Controller for handling music playback
class PlayerController extends StateNotifier<app_state.PlayerState> {
  final just_audio.AudioPlayer _audioPlayer = just_audio.AudioPlayer();
  final Ref ref;
  
  // Stream subscriptions for proper disposal
  StreamSubscription<just_audio.PlayerState>? _playerStateSubscription;
  StreamSubscription<Duration?>? _durationSubscription;
  StreamSubscription<Duration>? _positionSubscription;
  
  Timer? _positionTimer;
  bool _isDisposed = false;
  final bool _isInitializing = false;

  // Play count tracking
  String? _currentPlayCountSongId;
  DateTime? _playStartTime;
  bool _playCountCounted = false;
  Duration _accumulatedListeningTime = Duration.zero;
  Duration _lastKnownPosition = Duration.zero;
  
  // Constants for play count logic
  static const Duration _minPlayDuration = Duration(seconds: 30);
  static const Duration _maxSeekJump = Duration(seconds: 10);
  
  // Skip protection
  DateTime? _lastSkipTime;
  static const Duration _minSkipInterval = Duration(milliseconds: 200);

  String? _currentAudioUrl;

  PlayerController(this.ref) : super(app_state.PlayerState.initial()) {
    _initAudioPlayer();
  }

  @override
  void dispose() {
    _isDisposed = true;
    
    // Cancel all stream subscriptions
    _playerStateSubscription?.cancel();
    _durationSubscription?.cancel();
    _positionSubscription?.cancel();
    _positionTimer?.cancel();
    
    // Dispose audio player safely
    try {
      _audioPlayer.dispose();
    } catch (e) {
      debugPrint('Error disposing audio player: $e');
    }
    
    super.dispose();
  }

  void _initAudioPlayer() {
    // Listen to playback state changes with proper subscription management
    _playerStateSubscription = _audioPlayer.playerStateStream.listen((playerState) {
      if (_isDisposed) return;

      try {
        final isPlaying = playerState.playing;
        final processingState = playerState.processingState;

        if (processingState == just_audio.ProcessingState.loading ||
            processingState == just_audio.ProcessingState.buffering) {
          state = state.copyWith(isBuffering: true);
        } else {
          state = state.copyWith(
            isPlaying: isPlaying,
            isBuffering: false,
          );

          // Reset play count timing when playback actually starts
          if (isPlaying && state.currentSong != null && _playStartTime == null) {
            _playStartTime = DateTime.now();
            _playCountCounted = false;
            _lastKnownPosition = _audioPlayer.position;
          }
          
          // Reset timing when paused to avoid counting pause time
          if (!isPlaying && _playStartTime != null && !_playCountCounted) {
            // Add any remaining time before pause
            final now = DateTime.now();
            final timeSinceLastCheck = now.difference(_playStartTime!);
            if (timeSinceLastCheck <= Duration(seconds: 2)) {
              _accumulatedListeningTime += timeSinceLastCheck;
            }
            _playStartTime = null;
          }

          if (processingState == just_audio.ProcessingState.completed) {
            _handleSongCompletion();
          }
        }
      } catch (e) {
        debugPrint('Error in playerStateStream listener: $e');
        if (!_isDisposed) {
          state = state.copyWith(isBuffering: false, isPlaying: false);
        }
      }
    });

    // Listen to duration changes with proper subscription management
    _durationSubscription = _audioPlayer.durationStream.listen((duration) {
      if (_isDisposed) return;

      try {
        if (duration != null && state.currentSong != null) {
          final updatedSong =
              _updateSongWithRealDuration(state.currentSong!, duration);
          state = state.copyWith(currentSong: updatedSong);
        }
      } catch (e) {
        debugPrint('Error in durationStream listener: $e');
      }
    });

    // Position update timer with enhanced error handling
    _positionTimer = Timer.periodic(const Duration(milliseconds: 200), (_) {
      if (!_isDisposed && _audioPlayer.playing) {
        _updatePosition();
      }
    });
  }

  /// Update current position
  void _updatePosition() {
    if (_isDisposed) return;

    try {
      final position = _audioPlayer.position;
      state = state.copyWith(currentPosition: position);
      
      // Check if we should increment play count
      _checkPlayCountConditions(position);
    } catch (e) {
      // Ignore position update errors
    }
  }

  /// Check if conditions are met to increment play count
  void _checkPlayCountConditions(Duration currentPosition) {
    if (_isDisposed || state.currentSong == null) return;
    
    final currentSong = state.currentSong!;
    final songId = currentSong.id;
    
    // Reset if different song
    if (_currentPlayCountSongId != songId) {
      _currentPlayCountSongId = songId;
      _playStartTime = DateTime.now();
      _playCountCounted = false;
      _accumulatedListeningTime = Duration.zero;
      _lastKnownPosition = currentPosition;
      return;
    }
    
    // Skip if already counted for this song
    if (_playCountCounted || _playStartTime == null) return;
    
    // Check for major seek/jump
    final positionDiff = (currentPosition - _lastKnownPosition).abs();
    if (positionDiff > _maxSeekJump) {
      // Major seek detected - reset timing but keep accumulated time
      _playStartTime = DateTime.now();
      _lastKnownPosition = currentPosition;
      return;
    }
    
    // Calculate listening time since last check
    final now = DateTime.now();
    final timeSinceLastCheck = now.difference(_playStartTime!);
    
    // Only add time if it's reasonable (not too long, indicating pause/background)
    if (timeSinceLastCheck <= Duration(seconds: 2)) {
      _accumulatedListeningTime += timeSinceLastCheck;
    }
    
    // Update tracking variables
    _playStartTime = now;
    _lastKnownPosition = currentPosition;
    
    // Check if we've accumulated enough listening time
    final songDuration = currentSong.duration;
    
    // Count as play if:
    // 1. Accumulated listening time >= 30 seconds, OR
    // 2. Accumulated listening time >= 25% of song duration (for very short songs)
    final minDurationForSong = Duration(milliseconds: (songDuration.inMilliseconds * 0.25).round());
    final effectiveMinDuration = minDurationForSong < _minPlayDuration 
        ? minDurationForSong 
        : _minPlayDuration;
    
    if (_accumulatedListeningTime >= effectiveMinDuration) {
      _playCountCounted = true;
      _incrementPlayCount(songId);
    }
  }

  /// Update song with actual audio duration
  Song _updateSongWithRealDuration(Song song, Duration realDuration) {
    if ((song.duration - realDuration).inSeconds.abs() > 5 ||
        song.durationInSeconds == 0) {
      _updateDurationInDatabase(song.id, realDuration.inSeconds);
      return song.copyWith(durationInSeconds: realDuration.inSeconds);
    }
    return song;
  }

  /// Update song duration in database
  Future<void> _updateDurationInDatabase(
      String songId, int durationInSeconds) async {
    try {
      final pbService = PocketBaseService();
      await pbService.pb.collection('songs').update(songId, body: {
        'duration': durationInSeconds,
      });
    } catch (e) {
      debugPrint('Error updating song duration in database: $e');
    }
  }

  /// Increment play count for a song
  Future<void> _incrementPlayCount(String songId) async {
    try {
      final songRepository = GetIt.instance<SongRepository>();
      await songRepository.incrementPlayCount(songId);
      
      debugPrint('Successfully incremented play count for song $songId');
    } catch (e) {
      debugPrint('Error incrementing play count for song $songId: $e');
      // Don't throw error to avoid breaking song playback
    }
  }

  /// Handle song completion with enhanced crash protection
  Future<void> _handleSongCompletion() async {
    if (_isDisposed) return;

    try {
      // Validate state before proceeding
      if (state.queue.isEmpty || state.currentIndex < 0) {
        debugPrint('Invalid state at song completion: queue empty or invalid index');
        if (!_isDisposed) {
          state = state.copyWith(isPlaying: false);
        }
        return;
      }

      switch (state.repeatMode) {
        case app_state.RepeatMode.off:
          if (state.currentIndex < state.queue.length - 1) {
            await skipNext();
          } else {
            // End of queue - stop playback safely
            if (!_isDisposed) {
              state = state.copyWith(
                isPlaying: false,
                currentPosition: state.currentSong?.duration ?? Duration.zero,
              );
            }
            debugPrint('Reached end of queue, stopping playback');
          }
          break;
          
        case app_state.RepeatMode.all:
          if (state.currentIndex < state.queue.length - 1) {
            await skipNext();
          } else if (state.queue.isNotEmpty) {
            // Loop back to beginning
            debugPrint('Looping back to start of queue');
            if (!_isDisposed) {
              state = state.copyWith(currentIndex: 0);
              await _playCurrentSong(autoPlay: true);
            }
          } else {
            // Fallback if queue becomes empty
            if (!_isDisposed) {
              state = state.copyWith(isPlaying: false);
            }
          }
          break;
          
        case app_state.RepeatMode.one:
          // Repeat current song
          debugPrint('Repeating current song');
          await seekTo(Duration.zero);
          break;
      }
    } catch (e) {
      debugPrint('Error in _handleSongCompletion: $e');
      // Fail-safe: stop playback on any error
      if (!_isDisposed) {
        state = state.copyWith(
          isPlaying: false,
          isBuffering: false,
        );
      }
    }
  }

  /// Load song by ID
  Future<Song> loadSongById(String songId) async {
    if (_isDisposed) throw Exception('Player is disposed');

    try {
      final pbService = PocketBaseService();
      final record = await pbService.pb.collection('songs').getOne(
            songId,
            expand: 'artist_id,album_id',
          );

      return Song.fromRecord(record);
    } catch (e) {
      debugPrint('Error loading song by ID: $e');
      throw Exception('Failed to load song: $e');
    }
  }

  /// Core play song method - completely simplified
  Future<void> playSong(Song song,
      {bool forceRestart = false, bool autoPlay = true}) async {
    if (_isDisposed || _isInitializing) return;

    try {
      final isCurrentSong = state.currentSong?.id == song.id;
      final shouldForceRestart = forceRestart || isCurrentSong;

      // Update state immediately
      state = state.copyWith(
        isBuffering: true,
        currentSong: song,
      );

      // Reset play count tracking for new song
      _currentPlayCountSongId = song.id;
      _playStartTime = DateTime.now();
      _playCountCounted = false;
      _accumulatedListeningTime = Duration.zero;
      _lastKnownPosition = Duration.zero;

      // Get audio URL
      final audioUrl = await _getSongAudioUrl(song);

      // Skip if same URL is already playing (unless forced restart)
      if (!shouldForceRestart &&
          _currentAudioUrl == audioUrl &&
          _audioPlayer.playing) {
        state = state.copyWith(isBuffering: false);
        return;
      }

      // Stop current playback
      try {
        await _audioPlayer.stop();
      } catch (e) {
        // Continue on stop errors
      }

      // Load new audio
      await _audioPlayer.setUrl(audioUrl);
      _currentAudioUrl = audioUrl;

      // Always play by default unless autoPlay is explicitly set to false
      if (autoPlay) {
        await _audioPlayer.play();
      }

      // Add to play history
      _addToPlayHistory(song.id);
      
      // Play count will be handled by _checkPlayCountConditions based on play time
    } catch (e) {
      debugPrint('Error playing song "${song.title}": $e');

      // Reset buffering state on error
      if (!_isDisposed) {
        state = state.copyWith(isBuffering: false);
      }
    }
  }

  /// Get song audio URL with fallback
  Future<String> _getSongAudioUrl(Song song) async {
    try {
      final pbService = PocketBaseService();
      final baseUrl = pbService.pb.baseUrl;

      if (song.audioFileName?.isNotEmpty == true) {
        return '$baseUrl/api/files/songs/${song.id}/${song.audioFileName}';
      } else {
        return '$baseUrl/api/files/songs/demo/dream_on_no3ma56xq7.mp3';
      }
    } catch (e) {
      debugPrint('Error getting song audio URL: $e, using fallback');
      return 'http://127.0.0.1:8090/api/files/songs/demo/dream_on_no3ma56xq7.mp3';
    }
  }

  /// Pause playback
  Future<void> pause() async {
    if (_isDisposed) return;
    try {
      await _audioPlayer.pause();
    } catch (e) {
      debugPrint('Error pausing playback: $e');
    }
  }

  /// Resume playback
  Future<void> resume() async {
    if (_isDisposed) return;
    try {
      await _audioPlayer.play();
    } catch (e) {
      debugPrint('Error resuming playback: $e');
    }
  }

  /// Toggle play/pause
  Future<void> togglePlayPause() async {
    if (_isDisposed) return;

    if (state.isPlaying) {
      await pause();
    } else {
      await resume();
    }
  }

  /// Skip to next - Enhanced with crash protection
  Future<void> skipNext() async {
    if (_isDisposed || _isInitializing) {
      return;
    }

    // Simple rate limiting - only prevent extremely rapid clicks
    final now = DateTime.now();
    if (_lastSkipTime != null &&
        now.difference(_lastSkipTime!) < _minSkipInterval) {
      return;
    }
    _lastSkipTime = now;

    try {
      final currentIndex = state.currentIndex;
      final queueLength = state.queue.length;

      if (queueLength == 0) {
        debugPrint('Cannot skip next: queue is empty');
        return;
      }

      // Validate current index
      if (currentIndex < 0 || currentIndex >= queueLength) {
        debugPrint('Cannot skip next: invalid current index $currentIndex for queue length $queueLength');
        if (!_isDisposed) {
          state = state.copyWith(currentIndex: 0, isPlaying: false);
        }
        return;
      }

      int nextIndex;

      if (state.repeatMode == app_state.RepeatMode.one) {
        nextIndex = currentIndex;
      } else if (currentIndex < queueLength - 1) {
        nextIndex = currentIndex + 1;
      } else if (state.repeatMode == app_state.RepeatMode.all) {
        nextIndex = 0;
      } else {
        debugPrint('Reached end of queue in skip next');
        if (!_isDisposed) {
          state = state.copyWith(isPlaying: false);
        }
        return; // End of queue
      }

      // Validate next index
      if (nextIndex < 0 || nextIndex >= queueLength) {
        debugPrint('Invalid next index calculated: $nextIndex for queue length $queueLength');
        return;
      }

      // Update index immediately
      if (!_isDisposed) {
        state = state.copyWith(currentIndex: nextIndex);
        // Play the next song - ALWAYS autoPlay=true for skips
        await _playCurrentSong(autoPlay: true);
      }
    } catch (e) {
      debugPrint('Error in skipNext: $e');
      if (!_isDisposed) {
        state = state.copyWith(isBuffering: false, isPlaying: false);
      }
    }
  }

  /// Skip to previous - Enhanced with crash protection
  Future<void> skipPrevious() async {
    if (_isDisposed || _isInitializing) {
      return;
    }

    // Simple rate limiting - only prevent extremely rapid clicks
    final now = DateTime.now();
    if (_lastSkipTime != null &&
        now.difference(_lastSkipTime!) < _minSkipInterval) {
      return;
    }
    _lastSkipTime = now;

    try {
      final currentIndex = state.currentIndex;
      final queueLength = state.queue.length;

      if (queueLength == 0) {
        debugPrint('Cannot skip previous: queue is empty');
        return;
      }

      // Validate current index
      if (currentIndex < 0 || currentIndex >= queueLength) {
        debugPrint('Cannot skip previous: invalid current index $currentIndex for queue length $queueLength');
        if (!_isDisposed) {
          state = state.copyWith(currentIndex: 0, isPlaying: false);
        }
        return;
      }

      int prevIndex;

      if (state.repeatMode == app_state.RepeatMode.one) {
        prevIndex = currentIndex;
      } else if (currentIndex > 0) {
        prevIndex = currentIndex - 1;
      } else if (state.repeatMode == app_state.RepeatMode.all) {
        prevIndex = queueLength - 1;
      } else {
        debugPrint('Reached beginning of queue in skip previous');
        if (!_isDisposed) {
          state = state.copyWith(isPlaying: false);
        }
        return; // Beginning of queue
      }

      // Validate previous index
      if (prevIndex < 0 || prevIndex >= queueLength) {
        debugPrint('Invalid previous index calculated: $prevIndex for queue length $queueLength');
        return;
      }

      // Update index immediately
      if (!_isDisposed) {
        state = state.copyWith(currentIndex: prevIndex);
        // Play the previous song - ALWAYS autoPlay=true for skips
        await _playCurrentSong(autoPlay: true);
      }
    } catch (e) {
      debugPrint('Error in skipPrevious: $e');
      if (!_isDisposed) {
        state = state.copyWith(isBuffering: false, isPlaying: false);
      }
    }
  }

  /// Play the current song in the queue with enhanced validation
  Future<void> _playCurrentSong({bool autoPlay = true}) async {
    if (_isDisposed) return;

    try {
      // Validate queue and index
      if (state.queue.isEmpty) {
        debugPrint('Cannot play current song: queue is empty');
        if (!_isDisposed) {
          state = state.copyWith(isPlaying: false, isBuffering: false);
        }
        return;
      }

      if (state.currentIndex < 0 || state.currentIndex >= state.queue.length) {
        debugPrint('Cannot play current song: invalid index ${state.currentIndex} for queue length ${state.queue.length}');
        if (!_isDisposed) {
          state = state.copyWith(
            currentIndex: 0,
            isPlaying: false,
            isBuffering: false,
          );
        }
        return;
      }

      final currentSong = state.queue[state.currentIndex];
      if (currentSong.id.isEmpty) {
        debugPrint('Cannot play current song: song has empty ID');
        return;
      }

      await playSong(currentSong, autoPlay: autoPlay);
    } catch (e) {
      debugPrint('Error in _playCurrentSong: $e');
      if (!_isDisposed) {
        state = state.copyWith(
          isPlaying: false,
          isBuffering: false,
        );
      }
    }
  }

  /// Seek to a position
  Future<void> seekTo(Duration position) async {
    if (_isDisposed) return;

    try {
      // Handle play count tracking for manual seek
      if (_playStartTime != null && !_playCountCounted && state.currentSong != null) {
        final seekDiff = (position - _lastKnownPosition).abs();
        final songDuration = state.currentSong!.duration;
        
        // Check for extreme seeks (to very end or very beginning)
        final isSeekToEnd = position >= songDuration - Duration(seconds: 5);
        final isSeekToBeginning = position <= Duration(seconds: 5);
        
        if (seekDiff > _maxSeekJump || isSeekToEnd || isSeekToBeginning) {
          // Major seek - add accumulated time before seek, then reset
          final now = DateTime.now();
          final timeSinceLastCheck = now.difference(_playStartTime!);
          if (timeSinceLastCheck <= Duration(seconds: 2)) {
            _accumulatedListeningTime += timeSinceLastCheck;
          }
          
          // Reset timing for new position
          _playStartTime = DateTime.now();
          _lastKnownPosition = position;
          
          // If seeking to very end, don't restart timing
          if (isSeekToEnd) {
            _playStartTime = null;
          }
        }
      }
      
      await _audioPlayer.seek(position);
      state = state.copyWith(currentPosition: position);
    } catch (e) {
      // Ignore seek errors
    }
  }

  /// Set queue and play with playlist context
  Future<void> playQueueFromPlaylist(
      List<Song> songs, int startIndex, String playlistId) async {
    if (_isDisposed) return;
    if (songs.isEmpty || startIndex < 0 || startIndex >= songs.length) return;

    final songToPlay = songs[startIndex];
    final isCurrentSong = state.currentSong?.id == songToPlay.id;
    final isDifferentContext = state.currentPlaylistId != playlistId;

    final shouldForceRestart = isCurrentSong && isDifferentContext;

    state = state.copyWith(
      queue: songs,
      currentIndex: startIndex,
      currentPlaylistId: playlistId,
      currentArtistId: null, // Clear artist context when playing from playlist
    );

    // Always autoPlay=true when explicitly playing a queue
    await playSong(songToPlay,
        forceRestart: shouldForceRestart, autoPlay: true);
  }

  /// Set queue and play with artist context
  Future<void> playQueueFromArtist(
      List<Song> songs, int startIndex, String artistId) async {
    if (_isDisposed) return;
    if (songs.isEmpty || startIndex < 0 || startIndex >= songs.length) return;

    final songToPlay = songs[startIndex];
    final isCurrentSong = state.currentSong?.id == songToPlay.id;
    final isDifferentContext = state.currentArtistId != artistId;

    final shouldForceRestart = isCurrentSong && isDifferentContext;

    state = state.copyWith(
      queue: songs,
      currentIndex: startIndex,
      currentPlaylistId: null, // Clear playlist context when playing from artist
      currentArtistId: artistId,
    );

    // Always autoPlay=true when explicitly playing a queue
    await playSong(songToPlay,
        forceRestart: shouldForceRestart, autoPlay: true);
  }

  /// Set queue and play without playlist context
  Future<void> playQueue(List<Song> songs, int startIndex) async {
    if (_isDisposed) return;
    if (songs.isEmpty || startIndex < 0 || startIndex >= songs.length) return;

    final songToPlay = songs[startIndex];
    final isCurrentSong = state.currentSong?.id == songToPlay.id;
    final isDifferentContext = state.currentPlaylistId != null || state.currentArtistId != null;

    final shouldForceRestart = isCurrentSong && isDifferentContext;

    state = state.copyWith(
      queue: songs,
      currentIndex: startIndex,
      currentPlaylistId: null,
      currentArtistId: null, // Clear artist context
    );

    // Always autoPlay=true when explicitly playing a queue
    await playSong(songToPlay,
        forceRestart: shouldForceRestart, autoPlay: true);
  }

  /// Toggle shuffle mode
  void toggleShuffle() {
    if (_isDisposed) return;

    final newShuffleMode = !state.shuffleMode;
    state = state.copyWith(shuffleMode: newShuffleMode);

    if (newShuffleMode) {
      if (state.currentPlaylistId != null && state.queue.isNotEmpty) {
        _shuffleCurrentQueue();
      } else {
        _shuffleAllSongs();
      }
    }
  }

  /// Reset shuffle mode when changing context
  void resetShuffleOnContextChange() {
    if (_isDisposed) return;
    
    // Reset shuffle mode when switching to different context
    if (state.shuffleMode) {
      state = state.copyWith(shuffleMode: false);
    }
  }

  /// Shuffle current queue
  void _shuffleCurrentQueue() {
    if (state.queue.isEmpty) return;

    final currentSong = state.currentSong;
    final List<Song> shuffledQueue = List.from(state.queue)..shuffle();

    if (currentSong != null) {
      shuffledQueue.remove(currentSong);
      shuffledQueue.insert(0, currentSong);
    }

    state = state.copyWith(
      queue: shuffledQueue,
      currentIndex: 0,
    );
  }

  /// Shuffle all songs from database
  Future<void> _shuffleAllSongs() async {
    try {
      final songRepository = GetIt.instance<SongRepository>();
      final allSongs = await songRepository.getAllSongs();

      if (allSongs.isEmpty) return;

      final List<Song> shuffledSongs = List.from(allSongs)..shuffle();

      final currentSong = state.currentSong;
      int currentIndex = 0;

      if (currentSong != null) {
        shuffledSongs.removeWhere((song) => song.id == currentSong.id);
        shuffledSongs.insert(0, currentSong);
        currentIndex = 0;
      }

      state = state.copyWith(
        queue: shuffledSongs,
        currentIndex: currentIndex,
        currentPlaylistId: null,
      );
    } catch (e) {
      debugPrint('Error shuffling all songs: $e');
      if (state.queue.isNotEmpty) {
        _shuffleCurrentQueue();
      }
    }
  }

  /// Toggle repeat mode
  void toggleRepeatMode() {
    if (_isDisposed) return;

    switch (state.repeatMode) {
      case app_state.RepeatMode.off:
        state = state.copyWith(repeatMode: app_state.RepeatMode.all);
        break;
      case app_state.RepeatMode.all:
        state = state.copyWith(repeatMode: app_state.RepeatMode.one);
        break;
      case app_state.RepeatMode.one:
        state = state.copyWith(repeatMode: app_state.RepeatMode.off);
        break;
    }
  }

  /// Add song to queue
  void addToQueue(Song song) {
    if (_isDisposed) return;

    final newQueue = List<Song>.from(state.queue)..add(song);
    state = state.copyWith(queue: newQueue);
  }

  /// Remove song from queue
  void removeFromQueue(int index) {
    if (_isDisposed) return;

    if (index < 0 || index >= state.queue.length) return;

    final newQueue = List<Song>.from(state.queue)..removeAt(index);

    int newIndex = state.currentIndex;
    if (index < state.currentIndex) {
      newIndex--;
    } else if (index == state.currentIndex) {
      if (newQueue.isEmpty) {
        _audioPlayer.stop();
        state = state.copyWith(
          queue: newQueue,
          currentSong: null,
          isPlaying: false,
          currentIndex: -1,
        );
        return;
      }

      if (newIndex >= newQueue.length) {
        newIndex = newQueue.length - 1;
      }

      final newSong = newQueue[newIndex];

      state = state.copyWith(
        queue: newQueue,
        currentIndex: newIndex,
        currentSong: newSong,
      );

      // Always autoPlay=true when removing current song
      playSong(newSong, autoPlay: true);
      return;
    }

    state = state.copyWith(
      queue: newQueue,
      currentIndex: newIndex,
    );
  }

  void pauseSong() {
    if (_isDisposed) return;
    if (state.isPlaying) {
      state = state.copyWith(isPlaying: false);
    }
  }

  void resumeSong() {
    if (_isDisposed) return;
    if (!state.isPlaying && state.currentSong != null) {
      state = state.copyWith(isPlaying: true);
    }
  }

  /// Stop playback and reset player state
  Future<void> stopAndReset() async {
    if (_isDisposed) return;

    try {
      await _audioPlayer.stop();
      _currentAudioUrl = null;
      state = app_state.PlayerState.initial();
    } catch (e) {
      debugPrint('Error stopping and resetting player: $e');
      _currentAudioUrl = null;
      state = app_state.PlayerState.initial();
    }
  }

  void skipToNext() {
    if (_isDisposed) return;
    skipNext();
  }

  /// Add song to play history
  void _addToPlayHistory(String songId) {
    try {
      ref.read(playHistoryControllerProvider.notifier).addPlayHistory(songId);
    } catch (e) {
      debugPrint('Error adding to play history: $e');
    }
  }

  /// Debug helper
  void debugCurrentPlaylistId() {
    // Reduced debug logging for performance
  }

  /// Play song without playlist context
  Future<void> playSongWithoutPlaylist(Song song,
      {bool forceRestart = false}) async {
    if (_isDisposed) return;

    final isCurrentSong = state.currentSong?.id == song.id;
    final isDifferentContext = state.currentPlaylistId != null || state.currentArtistId != null;

    final shouldForceRestart =
        forceRestart || isCurrentSong || (isCurrentSong && isDifferentContext);

    try {
      final songRepository = GetIt.instance<SongRepository>();
      final allSongs = await songRepository.getAllSongs();

      if (allSongs.isEmpty) {
        state = state.copyWith(
          queue: [song],
          currentIndex: 0,
          currentPlaylistId: null,
          currentArtistId: null,
        );
      } else {
        final List<Song> shuffledSongs = List.from(allSongs)..shuffle();
        shuffledSongs.removeWhere((s) => s.id == song.id);
        shuffledSongs.insert(0, song);

        state = state.copyWith(
          queue: shuffledSongs,
          currentIndex: 0,
          currentPlaylistId: null,
          currentArtistId: null,
          shuffleMode: true,
        );
      }
    } catch (e) {
      debugPrint('Error loading all songs for individual playbook: $e');
      state = state.copyWith(
        queue: [song],
        currentIndex: 0,
        currentPlaylistId: null,
        currentArtistId: null,
      );
    }

    // Always autoPlay=true when explicitly playing a song
    await playSong(song, forceRestart: shouldForceRestart, autoPlay: true);
  }

  /// Play song by ID without playlist context
  Future<void> playSongByIdWithoutPlaylist(String songId) async {
    if (_isDisposed) return;

    try {
      SongRepository.clearCache();

      final songRepository = GetIt.instance<SongRepository>();
      final song = await songRepository.getSongById(songId);

      if (song == null) {
        if (!_isDisposed) {
          state = state.copyWith(isBuffering: false);
        }
        return;
      }

      await playSongWithoutPlaylist(song);
    } catch (e) {
      debugPrint('Error loading song by ID: $e');
      if (!_isDisposed) {
        state = state.copyWith(isBuffering: false);
      }
    }
  }

  /// Update queue and index
  void updateQueue(List<Song> newQueue, int newIndex) {
    if (_isDisposed) return;

    if (newIndex < 0 || newIndex >= newQueue.length) return;

    final newCurrentSong = newQueue[newIndex];

    state = state.copyWith(
      queue: newQueue,
      currentIndex: newIndex,
      currentSong: newCurrentSong,
    );
  }

  /// Load and shuffle all songs
  Future<void> loadAllSongsAndShuffle() async {
    if (_isDisposed) return;

    try {
      final songRepository = GetIt.instance<SongRepository>();
      final allSongs = await songRepository.getAllSongs();

      if (allSongs.isEmpty) return;

      final List<Song> shuffledSongs = List.from(allSongs)..shuffle();

      final currentSong = state.currentSong;
      int currentIndex = 0;

      if (currentSong != null) {
        shuffledSongs.removeWhere((song) => song.id == currentSong.id);
        shuffledSongs.insert(0, currentSong);
        currentIndex = 0;
      }

      state = state.copyWith(
        queue: shuffledSongs,
        currentIndex: currentIndex,
        currentPlaylistId: null,
        shuffleMode: true,
      );
    } catch (e) {
      debugPrint('Error loading and shuffling all songs: $e');
    }
  }
}

