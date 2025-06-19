import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import 'package:flutter/foundation.dart';
import '../models/shorts.dart';
import '../repositories/shorts_repository.dart';
import '../states/shorts_state.dart';

/// Controller for managing shorts globally with advanced video features
class ShortsController extends StateNotifier<ShortsState> {
  final ShortsRepository _repository;
  final Ref _ref;

  ShortsController(this._repository, this._ref) : super(const ShortsState());

  /// Load shorts from the repository with enhanced error handling
  Future<void> loadShorts({int page = 1, int limit = 20}) async {
    if (state.isLoading) return; // Prevent multiple simultaneous loads

    state = state.copyWith(isLoading: true, error: null);

    try {
      final shorts = await _repository.getShorts(page: page, limit: limit);
      
      state = state.copyWith(
        shorts: shorts,
        isLoading: false,
        hasReachedMax: shorts.length < limit,
        currentGenreFilter: null, // Clear genre filter for general load
      );
    } catch (e) {
      debugPrint('❌ ShortsController error: $e');
      
      // For now, we'll create an empty state to prevent the home screen from failing
      // TODO: Fix the repository parsing issue
      state = state.copyWith(
        shorts: [], // Empty list instead of failing
        isLoading: false,
        error: null, // Don't show error to user for now
        hasReachedMax: true,
      );
    }
  }

  /// Load shorts filtered by genre
  Future<void> loadShortsByGenre(String genreId, {int page = 1, int limit = 20}) async {
    if (state.isLoading) return; // Prevent multiple simultaneous loads

    state = state.copyWith(isLoading: true, error: null, currentGenreFilter: genreId);

    try {
      final shorts = await _repository.getShortsByGenre(genreId, limit: limit);
      
      state = state.copyWith(
        shorts: shorts,
        isLoading: false,
        hasReachedMax: shorts.length < limit,
        currentGenreFilter: genreId,
      );
    } catch (e) {
      debugPrint('❌ ShortsController loadShortsByGenre error: $e');
      
      state = state.copyWith(
        shorts: [], // Empty list instead of failing
        isLoading: false,
        error: null, // Don't show error to user for now
        hasReachedMax: true,
        currentGenreFilter: genreId,
      );
    }
  }

  /// Refresh shorts (force reload)
  Future<void> refreshShorts() async {
    final currentGenreFilter = state.currentGenreFilter;
    state = const ShortsState(); // Reset state
    
    if (currentGenreFilter != null) {
      await loadShortsByGenre(currentGenreFilter);
    } else {
      await loadShorts();
    }
  }

  /// Load more shorts for pagination
  Future<void> loadMoreShorts() async {
    if (state.isLoadingMore || state.hasReachedMax) return;

    state = state.copyWith(isLoadingMore: true);

    try {
      final nextPage = (state.shorts.length ~/ 20) + 1;
      List<dynamic> newShorts;
      
      if (state.currentGenreFilter != null) {
        // Load more shorts for specific genre
        newShorts = await _repository.getShortsByGenre(
          state.currentGenreFilter!, 
          limit: 20
        );
      } else {
        // Load more general shorts
        newShorts = await _repository.getShorts(page: nextPage, limit: 20);
      }
      
      state = state.copyWith(
        shorts: [...state.shorts, ...newShorts],
        isLoadingMore: false,
        hasReachedMax: newShorts.length < 20,
      );
    } catch (e) {
      debugPrint('❌ Load more shorts error: $e');
      state = state.copyWith(
        isLoadingMore: false,
        error: null, // Don't show error for pagination
      );
    }
  }

  /// Update current playing index
  void updateCurrentIndex(int index) {
    if (index >= 0 && index < state.shorts.length) {
      final currentShort = state.shorts[index];
      state = state.copyWith(
        currentIndex: index,
        currentShort: currentShort,
      );
    }
  }

  /// Toggle play/pause state
  void togglePlayPause() {
    state = state.copyWith(isPlaying: !state.isPlaying);
  }

  /// Set playing state
  void setPlaying(bool isPlaying) {
    state = state.copyWith(isPlaying: isPlaying);
  }

  /// Toggle mute state
  void toggleMute() {
    state = state.copyWith(isMuted: !state.isMuted);
  }

  /// Set volume
  void setVolume(double volume) {
    state = state.copyWith(
      volume: volume.clamp(0.0, 1.0),
      isMuted: volume == 0.0,
    );
  }

  /// Update view count for a short
  Future<void> incrementViews(String shortId) async {
    try {
      await _repository.incrementViews(shortId);
      
      // Update local state
      final updatedShorts = state.shorts.map((short) {
        if (short.id == shortId) {
          return short.copyWith(views: short.views + 1);
        }
        return short;
      }).toList();
      
      state = state.copyWith(shorts: updatedShorts);
    } catch (e) {
      // Silently fail for view count updates
    }
  }

  /// Update like count for a short
  Future<void> toggleLike(String shortId) async {
    try {
      await _repository.toggleLike(shortId);
      
      // Update local state (simplified - in real app you'd track user likes)
      final updatedShorts = state.shorts.map((short) {
        if (short.id == shortId) {
          return short.copyWith(likes: short.likes + 1);
        }
        return short;
      }).toList();
      
      state = state.copyWith(shorts: updatedShorts);
    } catch (e) {
      // Silently fail for like updates
    }
  }

  /// Get shorts by genre
  List<Shorts> getShortsByGenre(String genreId) {
    return state.shorts.where((short) => short.genresId == genreId).toList();
  }

  /// Search shorts
  List<Shorts> searchShorts(String query) {
    if (query.isEmpty) return state.shorts;
    
    final lowercaseQuery = query.toLowerCase();
    return state.shorts.where((short) {
      return (short.title?.toLowerCase().contains(lowercaseQuery) ?? false) ||
             (short.artistName?.toLowerCase().contains(lowercaseQuery) ?? false) ||
             (short.songTitle?.toLowerCase().contains(lowercaseQuery) ?? false) ||
             (short.hashtags?.toLowerCase().contains(lowercaseQuery) ?? false);
    }).toList();
  }

  /// Clear error state
  void clearError() {
    if (state.error != null) {
      state = state.copyWith(error: null);
    }
  }

  /// Preload next videos for smooth scrolling
  void preloadNextVideos() {
    // This can be implemented to preload video controllers
    // for better UX in video feeds
  }

  /// Clear current genre filter and reload all shorts
  Future<void> clearFilter() async {
    debugPrint('🔄 Clearing genre filter');
    state = state.copyWith(currentGenreFilter: null);
    await loadShorts(page: 1, limit: 20); // Reload all shorts
  }
}

/// Provider for shorts repository
final shortsRepositoryProvider = Provider<ShortsRepository>((ref) {
  return GetIt.instance<ShortsRepository>();
});

/// Main shorts provider
final shortsProvider = StateNotifierProvider<ShortsController, ShortsState>((ref) {
  final repository = ref.watch(shortsRepositoryProvider);
  return ShortsController(repository, ref);
});

/// Provider for getting shorts by genre (uses filtered shorts from state if available)
final shortsByGenreProvider = Provider.family<List<Shorts>, String>((ref, genreId) {
  final shortsState = ref.watch(shortsProvider);
  
  // If we're currently filtering by this genre, return all shorts from state
  if (shortsState.currentGenreFilter == genreId) {
    return shortsState.shorts;
  }
  
  // Otherwise, filter from all shorts
  return shortsState.shorts.where((short) => short.genresId == genreId).toList();
});

/// Provider for current playing short
final currentShortProvider = Provider<Shorts?>((ref) {
  final shortsState = ref.watch(shortsProvider);
  return shortsState.currentShort;
});
