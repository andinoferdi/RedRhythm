import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:just_audio/just_audio.dart' hide PlayerState;
import '../../models/song.dart';
import '../../services/pocketbase_service.dart';
import '../states/player_state.dart';

/// Provider for player controller
final playerControllerProvider = StateNotifierProvider<PlayerController, PlayerState>(
  (ref) => PlayerController(),
);

/// Controller for handling music playback
class PlayerController extends StateNotifier<PlayerState> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  Timer? _positionTimer;
  
  PlayerController() : super(PlayerState.initial()) {
    _initAudioPlayer();
  }
  
  @override
  void dispose() {
    _positionTimer?.cancel();
    _audioPlayer.dispose();
    super.dispose();
  }
  
  void _initAudioPlayer() {
    // Listen to playback state changes
    _audioPlayer.playerStateStream.listen((playerState) {
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
      if (duration != null && state.currentSong != null) {
        final updatedSong = _updateSongWithRealDuration(state.currentSong!, duration);
        state = state.copyWith(currentSong: updatedSong);
      }
    });
    
    // Start position update timer
    _positionTimer = Timer.periodic(const Duration(milliseconds: 200), (_) {
      if (_audioPlayer.playing) {
        _updatePosition();
      }
    });
  }
  
  /// Update current position (separate method to handle async properly)
  void _updatePosition() {
    try {
      final position = _audioPlayer.position;
      state = state.copyWith(currentPosition: position);
    } catch (e) {
      // Ignore position update errors
    }
  }
  
  /// Update song with actual audio duration
  Song _updateSongWithRealDuration(Song song, Duration realDuration) {
    // Only update if the real duration is significantly different
    if ((song.duration - realDuration).inSeconds.abs() > 5) {
      debugPrint('Memperbarui durasi lagu dari ${song.durationInSeconds}s menjadi ${realDuration.inSeconds}s');
      return song.copyWith(durationInSeconds: realDuration.inSeconds);
    }
    return song;
  }
  
  /// Handle song completion based on repeat mode
  Future<void> _handleSongCompletion() async {
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
  
  /// Play a song
  Future<void> playSong(Song song) async {
    // Get audio URL
    final audioUrl = _getSongAudioUrl(song);
    if (audioUrl == null) {
      // If no audio URL is available, update state but don't play
      state = state.copyWith(
        currentSong: song,
        isPlaying: false,
      );
      return;
    }
    
    try {
      // Stop any current playback
      await _audioPlayer.stop();
      
      // Set state to buffering while we prepare to play
      state = state.copyWith(
        currentSong: song,
        isBuffering: true,
        currentPosition: Duration.zero,
      );
      
      // Set the audio source and start playback
      await _audioPlayer.setUrl(audioUrl);
      await _audioPlayer.play();
      
      // Update state
      state = state.copyWith(
        isPlaying: true,
        isBuffering: false,
      );
    } catch (e) {
      // Handle errors
      debugPrint('Error playing song: $e');
      state = state.copyWith(
        isBuffering: false,
        isPlaying: false,
      );
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
    if (state.isPlaying) {
      await _audioPlayer.pause();
      state = state.copyWith(isPlaying: false);
    }
  }
  
  /// Resume playback
  Future<void> resume() async {
    if (!state.isPlaying && state.currentSong != null) {
      if (_audioPlayer.playing) {
        state = state.copyWith(isPlaying: true);
      } else {
        await _audioPlayer.play();
      }
    }
  }
  
  /// Skip to next song
  Future<void> skipNext() async {
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
    await _audioPlayer.seek(position);
    state = state.copyWith(currentPosition: position);
  }
  
  /// Set queue and play
  Future<void> playQueue(List<Song> songs, int startIndex) async {
    if (songs.isEmpty || startIndex < 0 || startIndex >= songs.length) {
      return;
    }
    
    state = state.copyWith(
      queue: songs,
      currentIndex: startIndex,
    );
    
    await playSong(songs[startIndex]);
  }
  
  /// Toggle shuffle mode
  void toggleShuffle() {
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
    final newQueue = List<Song>.from(state.queue)..add(song);
    state = state.copyWith(queue: newQueue);
  }
  
  /// Remove song from queue
  void removeFromQueue(int index) {
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
    if (state.isPlaying) {
      state = state.copyWith(isPlaying: false);
    }
  }

  void resumeSong() {
    if (!state.isPlaying && state.currentSong != null) {
      state = state.copyWith(isPlaying: true);
    }
  }

  void skipToNext() {
    // Implement next song logic here
    // For now, just pause the current song
    pauseSong();
  }
} 