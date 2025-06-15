import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart' hide PlayerState;
import '../../models/song.dart';
import '../../services/pocketbase_service.dart';
import '../states/player_state.dart';
import 'play_history_controller.dart';

/// Provider for player controller
final playerControllerProvider = StateNotifierProvider<PlayerController, PlayerState>(
  (ref) => PlayerController(ref),
);

/// Controller for handling music playback
class PlayerController extends StateNotifier<PlayerState> {
  late final AudioPlayer _audioPlayer;
  final Ref ref;
  Timer? _positionTimer;
  String? _currentAudioUrl;
  bool _isDisposed = false;
  
  PlayerController(this.ref) : super(PlayerState.initial()) {
    _initializeAudioPlayer();
  }
  
  /// Initialize audio player with error handling
  void _initializeAudioPlayer() {
    try {
      _audioPlayer = AudioPlayer();
      _initAudioPlayer();
    } catch (e) {
      debugPrint('Error initializing audio player: $e');
      // Try to reinitialize after a delay
      Future.delayed(const Duration(milliseconds: 500), () {
        if (!_isDisposed) {
          try {
            _audioPlayer = AudioPlayer();
            _initAudioPlayer();
          } catch (retryError) {
            debugPrint('Failed to reinitialize audio player: $retryError');
          }
        }
      });
    }
  }
  
  /// Recreate audio player to fix instance conflicts
  Future<void> _recreateAudioPlayer() async {
    if (_isDisposed) return;
    
    try {
      debugPrint('🔄 Recreating audio player...');
      
      // Cancel position timer
      _positionTimer?.cancel();
      
      // Dispose current player
      await _audioPlayer.dispose();
      
      // Wait for cleanup
      await Future.delayed(const Duration(milliseconds: 200));
      
      // Create new player
      _audioPlayer = AudioPlayer();
      
      // Reinitialize listeners
      _initAudioPlayer();
      
      debugPrint('✅ Audio player recreated successfully');
    } catch (e) {
      debugPrint('❌ Error recreating audio player: $e');
      rethrow;
    }
  }
  
  @override
  void dispose() {
    _isDisposed = true;
    _positionTimer?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }
  
  void _initAudioPlayer() {
    // Listen to playback state changes
    _audioPlayer.playerStateStream.listen((playerState) {
      if (_isDisposed) return;
      
      final isPlaying = playerState.playing;
      final processingState = playerState.processingState;
      
      if (processingState == ProcessingState.loading || 
          processingState == ProcessingState.buffering) {
        state = state.copyWith(isBuffering: true);
      } else {
        state = state.copyWith(
          isPlaying: isPlaying,
          isBuffering: false,
        );
        
        if (processingState == ProcessingState.completed) {
          _handleSongCompletion();
        }
      }
    });
    
    // Listen to duration changes to update song duration
    _audioPlayer.durationStream.listen((duration) {
      if (_isDisposed) return;
      
      if (duration != null && state.currentSong != null) {
        final updatedSong = _updateSongWithRealDuration(state.currentSong!, duration);
        state = state.copyWith(currentSong: updatedSong);
      }
    });
    
    // Listen to player errors
    _audioPlayer.playerStateStream.listen((playerState) {
      if (_isDisposed) return;
      
      if (playerState.processingState == ProcessingState.idle && 
          !playerState.playing && 
          state.isBuffering) {
        // Reset buffering state if player becomes idle while buffering
        state = state.copyWith(isBuffering: false);
      }
    });
    
    // Start position update timer
    _positionTimer = Timer.periodic(const Duration(milliseconds:200), (_) {
      if (!_isDisposed && _audioPlayer.playing) {
        _updatePosition();
      }
    });
  }
  
  /// Update current position (separate method to handle async properly)
  void _updatePosition() {
    if (_isDisposed) return;
    
    try {
      final position = _audioPlayer.position;
      state = state.copyWith(currentPosition: position);
    } catch (e) {
      // Ignore position update errors
    }
  }
  
  /// Update song with actual audio duration
  Song _updateSongWithRealDuration(Song song, Duration realDuration) {
    // Only update if the real duration is significantly different or if duration is 0
    if ((song.duration - realDuration).inSeconds.abs() > 5 || song.durationInSeconds == 0) {
      debugPrint('Memperbarui durasi lagu dari ${song.durationInSeconds}s menjadi ${realDuration.inSeconds}s');
      
      // Update the song duration in database if it's 0 or significantly different
      _updateDurationInDatabase(song.id, realDuration.inSeconds);
      
      return song.copyWith(durationInSeconds: realDuration.inSeconds);
    }
    return song;
  }

  /// Update song duration in PocketBase database
  Future<void> _updateDurationInDatabase(String songId, int durationInSeconds) async {
    try {
      final pbService = PocketBaseService();
      await pbService.pb.collection('songs').update(songId, body: {
        'duration': durationInSeconds,
      });
      debugPrint('✅ Song duration updated in database: $songId -> ${durationInSeconds}s');
    } catch (e) {
      debugPrint('❌ Error updating song duration in database: $e');
    }
  }
  
  /// Handle song completion based on repeat mode
  Future<void> _handleSongCompletion() async {
    if (_isDisposed) return;
    
    debugPrint('🎵 SONG_COMPLETE: Song completed - Repeat mode: ${state.repeatMode}, Current index: ${state.currentIndex}, Queue length: ${state.queue.length}');
    
    switch (state.repeatMode) {
      case RepeatMode.off:
        if (state.currentIndex < state.queue.length - 1) {
          debugPrint('🎵 SONG_COMPLETE: Auto-playing next song');
          await skipNext();
        } else {
          debugPrint('🎵 SONG_COMPLETE: Last song reached, stopping playback');
          state = state.copyWith(
            isPlaying: false, 
            currentPosition: state.currentSong?.duration ?? Duration.zero
          );
        }
        break;
      case RepeatMode.all:
        if (state.currentIndex < state.queue.length - 1) {
          debugPrint('🎵 SONG_COMPLETE: Auto-playing next song (repeat all)');
          await skipNext();
        } else if (state.queue.isNotEmpty) {
          debugPrint('🎵 SONG_COMPLETE: Looping back to first song (repeat all)');
          // Use skipNext which will handle the loop logic
          await skipNext();
        }
        break;
      case RepeatMode.one:
        debugPrint('🎵 SONG_COMPLETE: Replaying current song (repeat one)');
        // Restart current song
        await seekTo(Duration.zero);
        if (!state.isPlaying) {
          await resume();
        }
        break;
    }
  }
  
  /// Play song by ID (load full data from PocketBase)
  Future<void> playSongById(String songId) async {
    if (_isDisposed) return;
    
    try {
      debugPrint('Loading song by ID: $songId');
      
      final pbService = PocketBaseService();
      final record = await pbService.pb.collection('songs').getOne(
        songId,
        expand: 'artist_id,album_id',
      );
      
      final song = Song.fromRecord(record);
      debugPrint('Loaded song from PocketBase: ${song.title}');
      
      await playSong(song);
    } catch (e) {
      debugPrint('Error loading song by ID: $e');
      // Reset buffering state on error
      if (!_isDisposed) {
        state = state.copyWith(isBuffering: false);
      }
    }
  }

  /// Play a song
  Future<void> playSong(Song song) async {
    if (_isDisposed) return;
    
    // Get audio URL
    final audioUrl = _getSongAudioUrl(song);
    if (audioUrl == null) {
      // If no audio URL is available, update state but don't play
      state = state.copyWith(
        currentSong: song,
        isPlaying: false,
        isBuffering: false,
        // Don't modify currentPlaylistId here - preserve existing context
      );
      return;
    }
    
    try {
      debugPrint('Attempting to play song: ${song.title} with URL: $audioUrl');
      
      // Check if we're already playing this URL to avoid unnecessary loading
      if (_currentAudioUrl == audioUrl && _audioPlayer.playing) {
        debugPrint('Song already playing, skipping load');
        return;
      }
      
      // Set state to buffering while we prepare to play
      state = state.copyWith(
        currentSong: song,
        isBuffering: true,
        currentPosition: Duration.zero,
        isPlaying: false,
        // Don't modify currentPlaylistId here - preserve existing context
      );
      
      // Properly stop and dispose current playback to avoid "player already exists" error
      try {
        if (_audioPlayer.playing) {
          await _audioPlayer.stop();
        }
        // Clear any existing audio source
        await _audioPlayer.setUrl('');
        // Small delay to ensure cleanup completes
        await Future.delayed(const Duration(milliseconds: 200));
      } catch (e) {
        debugPrint('Warning: Error stopping current playback: $e');
      }
      
      // Set the audio source with timeout
      _currentAudioUrl = audioUrl;
      
      // Use a timeout to prevent loading from hanging
      await Future.any([
        _audioPlayer.setUrl(audioUrl),
        Future.delayed(const Duration(seconds: 15), () => throw TimeoutException('Audio loading timeout')),
      ]);
      
      // Check if we're still supposed to be playing this song (user might have changed song)
      if (_isDisposed || _currentAudioUrl != audioUrl) {
        debugPrint('Song changed during loading, aborting');
        return;
      }
      
      // Start playback
      await _audioPlayer.play();
      
      // Update state only if everything succeeded
      if (!_isDisposed && _currentAudioUrl == audioUrl) {
        state = state.copyWith(
          isPlaying: true,
          isBuffering: false,
        );
        debugPrint('Successfully started playing: ${song.title}');
        
        // Add to play history when song starts playing
        _addToPlayHistory(song.id);
      }
    } catch (e) {
      // Handle errors
      debugPrint('Error playing song "${song.title}": $e');
      
      // Reset current URL on error
      _currentAudioUrl = null;
      
      if (!_isDisposed) {
        state = state.copyWith(
          isBuffering: false,
          isPlaying: false,
        );
      }
      
      // Handle "player already exists" error by recreating the player
      if (e.toString().contains('already exists')) {
        debugPrint('Player instance conflict detected, recreating audio player...');
        try {
          // Dispose current player and create new one
          await _recreateAudioPlayer();
          
          // Retry playing the song with new player
          await Future.delayed(const Duration(milliseconds: 300));
          await _audioPlayer.setUrl(audioUrl);
          await _audioPlayer.play();
          _currentAudioUrl = audioUrl;
          
          if (!_isDisposed) {
            state = state.copyWith(
              isPlaying: true,
              isBuffering: false,
            );
          }
          debugPrint('Successfully played song after recreating player');
          
          // Add to play history when song starts playing
          _addToPlayHistory(song.id);
          return;
        } catch (recreateError) {
          debugPrint('Failed to recreate player and play song: $recreateError');
        }
      }
      
      // Try fallback URL if available and it's not a player instance error
      if (!audioUrl.contains('soundhelix.com') && !e.toString().contains('already exists')) {
        debugPrint('Trying fallback audio URL...');
        final fallbackUrl = 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3';
        try {
          // Wait a bit more before trying fallback to ensure cleanup
          await Future.delayed(const Duration(milliseconds: 500));
          await _audioPlayer.setUrl(fallbackUrl);
          await _audioPlayer.play();
          _currentAudioUrl = fallbackUrl;
          
          if (!_isDisposed) {
            state = state.copyWith(
              isPlaying: true,
              isBuffering: false,
            );
          }
          debugPrint('Fallback audio playing successfully');
        } catch (fallbackError) {
          debugPrint('Fallback audio also failed: $fallbackError');
        }
      }
    }
  }
  
  /// Get audio URL from a song
  String? _getSongAudioUrl(Song song) {
    // File audio contoh untuk fallback jika audio PocketBase gagal
    final String demoAudioUrl = 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3';
    
    try {
      final pbService = PocketBaseService();
      
      // Log untuk debugging
      debugPrint('Song ID: ${song.id}');
      String? url;
      
      // Coba gunakan nama file audio dari model jika tersedia
      if (song.audioFileName != null && song.audioFileName!.isNotEmpty) {
        url = '${pbService.pb.baseUrl}/api/files/songs/${song.id}/${song.audioFileName}';
        debugPrint('Menggunakan nama file dari model: ${song.audioFileName}');
      } else {
        // Gunakan nama file default jika tidak tersedia di model
        url = '${pbService.pb.baseUrl}/api/files/songs/${song.id}/dream_on_no3ma56xq7.mp3';
        debugPrint('Menggunakan nama file default: dream_on_no3ma56xq7.mp3');
      }
      
      debugPrint('URL audio final: $url');
      return url;
    } catch (e) {
      debugPrint('Error getting song audio URL: $e, menggunakan file audio demo');
      return demoAudioUrl; // Fallback ke demo jika terjadi error
    }
  }
  
  /// Pause playback
  Future<void> pause() async {
    if (_isDisposed) return;
    
    try {
      if (state.isPlaying) {
        await _audioPlayer.pause();
        state = state.copyWith(isPlaying: false);
      }
    } catch (e) {
      debugPrint('Error pausing playback: $e');
    }
  }
  
  /// Resume playback
  Future<void> resume() async {
    if (_isDisposed) return;
    
    try {
      if (!state.isPlaying && state.currentSong != null) {
        if (_audioPlayer.playing) {
          state = state.copyWith(isPlaying: true);
        } else {
          await _audioPlayer.play();
        }
      }
    } catch (e) {
      debugPrint('Error resuming playback: $e');
      // Try to restart the song if resume fails
      if (state.currentSong != null) {
        await playSong(state.currentSong!);
      }
    }
  }
  
  /// Skip to next song
  Future<void> skipNext() async {
    if (_isDisposed) return;
    
    try {
      final currentIndex = state.currentIndex;
      final queueLength = state.queue.length;
      
      // Reduced debug logging for better performance
      
      if (queueLength == 0) {
        return;
      }
      
      int nextIndex;
      
      if (state.repeatMode == RepeatMode.one) {
        // Repeat current song
        nextIndex = currentIndex;
      } else if (currentIndex < queueLength - 1) {
        // Go to next song
        nextIndex = currentIndex + 1;
      } else if (state.repeatMode == RepeatMode.all) {
        // Loop back to first song
        nextIndex = 0;
      } else {
        // End of queue and no repeat
        return;
      }
      
      final nextSong = state.queue[nextIndex];
      
      state = state.copyWith(currentIndex: nextIndex);
      
      // Reduced debug logging for better performance
      await playSong(nextSong);
    } catch (e) {
      // Reduced debug logging for better performance
      // Reset buffering state on error
      if (!_isDisposed) {
        state = state.copyWith(isBuffering: false);
      }
    }
  }
  
  /// Skip to previous song
  Future<void> skipPrevious() async {
    if (_isDisposed) return;
    
    try {
      final currentIndex = state.currentIndex;
      final queueLength = state.queue.length;
      
      // Reduced debug logging for better performance
      
      if (queueLength == 0) {
        return;
      }
      
      int prevIndex;
      
      if (state.repeatMode == RepeatMode.one) {
        // Repeat current song
        prevIndex = currentIndex;
      } else if (currentIndex > 0) {
        // Go to previous song
        prevIndex = currentIndex - 1;
      } else if (state.repeatMode == RepeatMode.all) {
        // Loop to last song
        prevIndex = queueLength - 1;
      } else {
        // Beginning of queue and no repeat
        return;
      }
      
      final prevSong = state.queue[prevIndex];
      
      state = state.copyWith(currentIndex: prevIndex);
      
      // Reduced debug logging for better performance
      await playSong(prevSong);
    } catch (e) {
      // Reduced debug logging for better performance
      // Reset buffering state on error
      if (!_isDisposed) {
        state = state.copyWith(isBuffering: false);
      }
    }
  }
  
  /// Seek to a position
  Future<void> seekTo(Duration position) async {
    if (_isDisposed) return;
    
    try {
      await _audioPlayer.seek(position);
      state = state.copyWith(currentPosition: position);
    } catch (e) {
      debugPrint('Error seeking to position: $e');
    }
  }
  
  /// Set queue and play, with playlist context
  Future<void> playQueueFromPlaylist(List<Song> songs, int startIndex, String playlistId) async {
    if (_isDisposed) return;
    if (songs.isEmpty || startIndex < 0 || startIndex >= songs.length) {
      return;
    }
    state = state.copyWith(
      queue: songs,
      currentIndex: startIndex,
      currentPlaylistId: playlistId,
    );
    await playSong(songs[startIndex]);
  }

  /// Set queue and play (no playlist context)
  Future<void> playQueue(List<Song> songs, int startIndex) async {
    if (_isDisposed) return;
    if (songs.isEmpty || startIndex < 0 || startIndex >= songs.length) {
      return;
    }
    state = state.copyWith(
      queue: songs,
      currentIndex: startIndex,
      currentPlaylistId: null,
    );
    await playSong(songs[startIndex]);
  }
  
  /// Toggle shuffle mode
  void toggleShuffle() {
    if (_isDisposed) return;
    
    final newShuffleMode = !state.shuffleMode;
    state = state.copyWith(shuffleMode: newShuffleMode);
    
    if (newShuffleMode && state.queue.isNotEmpty) {
      // Shuffle the queue but keep current song as first
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
  }
  
  /// Toggle repeat mode
  void toggleRepeatMode() {
    if (_isDisposed) return;
    
    switch (state.repeatMode) {
      case RepeatMode.off:
        state = state.copyWith(repeatMode: RepeatMode.all);
        break;
      case RepeatMode.all:
        state = state.copyWith(repeatMode: RepeatMode.one);
        break;
      case RepeatMode.one:
        state = state.copyWith(repeatMode: RepeatMode.off);
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
    
    if (index < 0 || index >= state.queue.length) {
      return;
    }
    
    final newQueue = List<Song>.from(state.queue)..removeAt(index);
    
    // Adjust current index if needed
    int newIndex = state.currentIndex;
    if (index < state.currentIndex) {
      newIndex--;
    } else if (index == state.currentIndex) {
      // Stop playback if current song is removed
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
      
      // Play next song if available
      if (newIndex >= newQueue.length) {
        newIndex = newQueue.length - 1;
      }
      
      // Prepare to play the new song
      final newSong = newQueue[newIndex];
      state = state.copyWith(
        queue: newQueue,
        currentIndex: newIndex,
        currentSong: newSong,
      );
      playSong(newSong);
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
      debugPrint('🛑 Stopping and resetting player state');
      
      // Stop audio player
      await _audioPlayer.stop();
      
      // Clear current audio URL
      _currentAudioUrl = null;
      
      // Reset state to initial values
      state = PlayerState.initial();
      
      debugPrint('✅ Player state reset complete');
    } catch (e) {
      debugPrint('❌ Error stopping and resetting player: $e');
      // Force reset state even if stop fails
      _currentAudioUrl = null;
      state = PlayerState.initial();
    }
  }

  void skipToNext() {
    if (_isDisposed) return;
    
    // Use the proper skipNext implementation
    skipNext();
  }
  
  /// Add song to play history
  void _addToPlayHistory(String songId) {
    try {
      // Add to play history without waiting for completion
      ref.read(playHistoryControllerProvider.notifier).addPlayHistory(songId);
    } catch (e) {
      debugPrint('Error adding to play history: $e');
      // Don't throw error, just log it
    }
  }

  /// Debug helper to track currentPlaylistId state
  void debugCurrentPlaylistId() {
    // Reduced debug logging for better performance
  }

  /// Play a song without playlist context (for individual song playback)
  Future<void> playSongWithoutPlaylist(Song song) async {
    if (_isDisposed) return;
    
    debugPrint('🎵 Playing song WITHOUT playlist context: ${song.title}');
    debugPrint('🎵 STACK TRACE: ${StackTrace.current}');
    
    // Clear any existing playlist context and reset shuffle mode
    state = state.copyWith(
      currentPlaylistId: null,
      queue: [song], // Set queue to just this song
      currentIndex: 0,
      shuffleMode: false, // Reset shuffle when playing without playlist
    );
    
    debugPrint('🎵 Cleared playlist context - currentPlaylistId: ${state.currentPlaylistId}, shuffleMode: ${state.shuffleMode}');
    
    // Then play the song (this will now preserve the null playlist ID)
    await playSong(song);
  }
  
  /// Play a song and explicitly clear playlist context
  Future<void> playSongWithoutPlaylistContext(Song song) async {
    if (_isDisposed) return;
    
    debugPrint('🎵 Playing individual song: ${song.title}');
    
    // First clear playlist context and reset shuffle
    state = state.copyWith(
      currentPlaylistId: null,
      queue: [song],
      currentIndex: 0,
      shuffleMode: false, // Reset shuffle when playing without playlist
    );
    
    // Then play the song
    await playSong(song);
  }

  /// Play song by ID without playlist context (for individual song playback)
  Future<void> playSongByIdWithoutPlaylist(String songId) async {
    if (_isDisposed) return;
    
    try {
      debugPrint('🎵 Loading song by ID WITHOUT playlist context: $songId');
      
      final pbService = PocketBaseService();
      final record = await pbService.pb.collection('songs').getOne(
        songId,
        expand: 'artist_id,album_id',
      );
      
      final song = Song.fromRecord(record);
      debugPrint('🎵 Loaded song from PocketBase: ${song.title}');
      
      await playSongWithoutPlaylist(song);
    } catch (e) {
      debugPrint('Error loading song by ID: $e');
      // Reset buffering state on error
      if (!_isDisposed) {
        state = state.copyWith(isBuffering: false);
      }
    }
  }
  
  /// Update the current queue and index (for shuffle functionality)
  void updateQueue(List<Song> newQueue, int newIndex) {
    if (_isDisposed) return;
    
    debugPrint('🔄 Updating queue with ${newQueue.length} songs, new index: $newIndex');
    
    // Validate new index
    if (newIndex < 0 || newIndex >= newQueue.length) {
      debugPrint('❌ Invalid new index: $newIndex for queue of length ${newQueue.length}');
      return;
    }
    
    final newCurrentSong = newQueue[newIndex];
    
    state = state.copyWith(
      queue: newQueue,
      currentIndex: newIndex,
      currentSong: newCurrentSong,
    );
    
    debugPrint('✅ Queue updated: current song "${newCurrentSong.title}" at index $newIndex');
  }
}
