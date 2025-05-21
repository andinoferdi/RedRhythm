import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/song.dart';
import 'player_state.dart';

/// Provider for player controller
final playerControllerProvider = StateNotifierProvider<PlayerController, PlayerState>(
  (ref) => PlayerController(),
);



/// Controller for handling music playback
class PlayerController extends StateNotifier<PlayerState> {
  PlayerController() : super(PlayerState.initial());
  
  /// Play a song
  void playSong(Song song) {
    state = state.copyWith(
      currentSong: song,
      isPlaying: true,
      currentPosition: Duration.zero,
    );
    // Actual audio playback logic would be here
  }
  
  /// Pause playback
  void pause() {
    if (state.isPlaying) {
      state = state.copyWith(isPlaying: false);
      // Actual audio pause logic would be here
    }
  }
  
  /// Resume playback
  void resume() {
    if (!state.isPlaying && state.currentSong != null) {
      state = state.copyWith(isPlaying: true);
      // Actual audio resume logic would be here
    }
  }
  
  /// Skip to next song
  void skipNext() {
    if (state.queue.isEmpty || state.currentIndex >= state.queue.length - 1) {
      return;
    }
    
    final nextIndex = state.currentIndex + 1;
    final nextSong = state.queue[nextIndex];
    
    state = state.copyWith(
      currentSong: nextSong,
      isPlaying: true,
      currentPosition: Duration.zero,
      currentIndex: nextIndex,
    );
    // Actual audio playback logic would be here
  }
  
  /// Skip to previous song
  void skipPrevious() {
    if (state.queue.isEmpty || state.currentIndex <= 0) {
      return;
    }
    
    final prevIndex = state.currentIndex - 1;
    final prevSong = state.queue[prevIndex];
    
    state = state.copyWith(
      currentSong: prevSong,
      isPlaying: true,
      currentPosition: Duration.zero,
      currentIndex: prevIndex,
    );
    // Actual audio playback logic would be here
  }
  
  /// Seek to a position
  void seekTo(Duration position) {
    state = state.copyWith(currentPosition: position);
    // Actual seek logic would be here
  }
  
  /// Set queue and play
  void playQueue(List<Song> songs, int startIndex) {
    if (songs.isEmpty || startIndex < 0 || startIndex >= songs.length) {
      return;
    }
    
    state = state.copyWith(
      queue: songs,
      currentIndex: startIndex,
      currentSong: songs[startIndex],
      isPlaying: true,
      currentPosition: Duration.zero,
    );
    // Actual audio playback logic would be here
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
    }
    
    state = state.copyWith(
      queue: newQueue,
      currentIndex: newIndex,
      currentSong: newIndex >= 0 && newIndex < newQueue.length ? newQueue[newIndex] : state.currentSong,
    );
  }
} 