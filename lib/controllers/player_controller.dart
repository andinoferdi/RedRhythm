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
  final AudioPlayer _audioPlayer = AudioPlayer();
  final Ref ref;
  Timer? _positionTimer;
  String? _currentAudioUrl;
  bool _isDisposed = false;
  
  PlayerController(this.ref) : super(PlayerState.initial()) {
    _initAudioPlayer();
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
    
    switch (state.repeatMode) {
      case RepeatMode.off:
        if (state.currentIndex < state.queue.length - 1) {
          await skipNext();
        } else {
          state = state.copyWith(isPlaying: false, currentPosition: state.currentSong?.duration ?? Duration.zero);
        }
        break;
      case RepeatMode.all:
        if (state.currentIndex < state.queue.length - 1) {
          await skipNext();
        } else if (state.queue.isNotEmpty) {
          // Loop back to first song
          await playQueue(state.queue, 0);
        }
        break;
      case RepeatMode.one:
        // Replay current song
        final currentSong = state.currentSong;
        if (currentSong != null) {
          await playSong(currentSong);
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
      
      // Stop any current playback first
      try {
        await _audioPlayer.stop();
        // Small delay to ensure stop completes
        await Future.delayed(const Duration(milliseconds: 100));
      } catch (e) {
        debugPrint('Warning: Error stopping current playback: $e');
      }
      
      // Set state to buffering while we prepare to play
      state = state.copyWith(
        currentSong: song,
        isBuffering: true,
        currentPosition: Duration.zero,
        isPlaying: false,
        // Don't modify currentPlaylistId here - preserve existing context
      );
      
      // Set the audio source with timeout
      _currentAudioUrl = audioUrl;
      
      // Use a timeout to prevent loading from hanging
      await Future.any([
        _audioPlayer.setUrl(audioUrl),
        Future.delayed(const Duration(seconds: 10), () => throw TimeoutException('Audio loading timeout')),
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
      
      // Try fallback URL if available
      if (!audioUrl.contains('soundhelix.com')) {
        debugPrint('Trying fallback audio URL...');
        final fallbackUrl = 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3';
        try {
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
    
    if (state.queue.isEmpty || state.currentIndex >= state.queue.length - 1) {
      return;
    }
    
    final nextIndex = state.currentIndex + 1;
    final nextSong = state.queue[nextIndex];
    
    state = state.copyWith(
      currentIndex: nextIndex,
    );
    
    await playSong(nextSong);
  }
  
  /// Skip to previous song
  Future<void> skipPrevious() async {
    if (_isDisposed) return;
    
    // If we're more than 3 seconds into the song, restart it instead
    if (state.currentPosition.inSeconds > 3) {
      await seekTo(Duration.zero);
      return;
    }
    
    if (state.queue.isEmpty || state.currentIndex <= 0) {
      return;
    }
    
    final prevIndex = state.currentIndex - 1;
    final prevSong = state.queue[prevIndex];
    
    state = state.copyWith(
      currentIndex: prevIndex,
    );
    
    await playSong(prevSong);
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
    debugPrint('🎵 PLAYLIST: Setting playlist context - playlistId: $playlistId');
    final oldPlaylistId = state.currentPlaylistId;
    state = state.copyWith(
      queue: songs,
      currentIndex: startIndex,
      currentPlaylistId: playlistId,
    );
    debugPrint('🎵 PLAYLIST: State updated - OLD: $oldPlaylistId -> NEW: ${state.currentPlaylistId}');
    debugCurrentPlaylistId();
    await playSong(songs[startIndex]);
  }

  /// Set queue and play (no playlist context)
  Future<void> playQueue(List<Song> songs, int startIndex) async {
    if (_isDisposed) return;
    if (songs.isEmpty || startIndex < 0 || startIndex >= songs.length) {
      return;
    }
    debugPrint('🎵 QUEUE: Playing queue WITHOUT playlist context');
    final oldPlaylistId = state.currentPlaylistId;
    state = state.copyWith(
      queue: songs,
      currentIndex: startIndex,
      currentPlaylistId: null,
    );
    debugPrint('🎵 QUEUE: State updated - OLD: $oldPlaylistId -> NEW: ${state.currentPlaylistId}');
    debugCurrentPlaylistId();
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
    
    // Implement next song logic here
    // For now, just pause the current song
    pauseSong();
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
    debugPrint('🎵 DEBUG: Current playlist ID is: ${state.currentPlaylistId}');
    debugPrint('🎵 DEBUG: Current song: ${state.currentSong?.title}');
    debugPrint('🎵 DEBUG: Queue length: ${state.queue.length}');
  }

  /// Play a song without playlist context (for individual song playback)
  Future<void> playSongWithoutPlaylist(Song song) async {
    if (_isDisposed) return;
    
    debugPrint('🎵 Playing song WITHOUT playlist context: ${song.title}');
    
    // Clear any existing playlist context first
    state = state.copyWith(
      currentPlaylistId: null,
      queue: [song], // Set queue to just this song
      currentIndex: 0,
    );
    
    debugPrint('🎵 Cleared playlist context - currentPlaylistId: ${state.currentPlaylistId}');
    
    // Then play the song (this will now preserve the null playlist ID)
    await playSong(song);
  }
  
  /// Play a song and explicitly clear playlist context
  Future<void> playSongWithoutPlaylistContext(Song song) async {
    if (_isDisposed) return;
    
    debugPrint('🎵 Playing individual song: ${song.title}');
    
    // First clear playlist context
    state = state.copyWith(
      currentPlaylistId: null,
      queue: [song],
      currentIndex: 0,
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
}
