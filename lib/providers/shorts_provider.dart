import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';

import '../repositories/shorts_repository.dart';
import '../services/pocketbase_service.dart';
import '../states/shorts_state.dart';

/// Provider for shorts repository
final shortsRepositoryProvider = Provider<ShortsRepository>((ref) {
  return ShortsRepository(GetIt.I<PocketBaseService>());
});

/// Provider for shorts state management
final shortsProvider = StateNotifierProvider<ShortsNotifier, ShortsState>((ref) {
  final repository = ref.watch(shortsRepositoryProvider);
  return ShortsNotifier(repository);
});

/// StateNotifier for managing shorts
class ShortsNotifier extends StateNotifier<ShortsState> {
  final ShortsRepository _repository;
  int _currentPage = 1;
  static const int _perPage = 10;

  ShortsNotifier(this._repository) : super(ShortsState.initial());

  /// Load initial shorts
  Future<void> loadShorts() async {
    if (state.isLoading) return;

    try {
      state = state.copyWith(isLoading: true, error: null);

      final shorts = await _repository.getRandomShorts(count: _perPage);
      
      if (shorts.isEmpty) {
        state = state.copyWith(
          isLoading: false,
          hasReachedMax: true,
        );
        return;
      }

      state = state.copyWith(
        shorts: shorts,
        currentIndex: 0,
        currentShort: shorts.isNotEmpty ? shorts.first : null,
        isLoading: false,
        hasReachedMax: shorts.length < _perPage,
      );

      _currentPage = 1;

      // Auto-increment view count for first short
      if (shorts.isNotEmpty) {
        _incrementViewCount(shorts.first.id);
      }
    } catch (e) {
      debugPrint('Error loading shorts: $e');
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Load more shorts for infinite scroll
  Future<void> loadMoreShorts() async {
    if (state.isLoadingMore || state.hasReachedMax) return;

    try {
      state = state.copyWith(isLoadingMore: true);

      final newShorts = await _repository.getRandomShorts(count: _perPage);
      
      if (newShorts.isEmpty) {
        state = state.copyWith(
          isLoadingMore: false,
          hasReachedMax: true,
        );
        return;
      }

      final updatedShorts = [...state.shorts, ...newShorts];
      
      state = state.copyWith(
        shorts: updatedShorts,
        isLoadingMore: false,
        hasReachedMax: newShorts.length < _perPage,
      );

      _currentPage++;
    } catch (e) {
      debugPrint('Error loading more shorts: $e');
      state = state.copyWith(
        isLoadingMore: false,
        error: e.toString(),
      );
    }
  }

  /// Go to next short
  void nextShort() {
    if (!state.canGoNext) return;

    final newIndex = state.currentIndex + 1;
    final newShort = state.shorts[newIndex];

    state = state.copyWith(
      currentIndex: newIndex,
      currentShort: newShort,
    );

    // Increment view count for new short
    _incrementViewCount(newShort.id);

    // Check if we need to load more shorts
    if (state.shouldLoadMore) {
      loadMoreShorts();
    }
  }

  /// Go to previous short
  void previousShort() {
    if (!state.canGoPrevious) return;

    final newIndex = state.currentIndex - 1;
    final newShort = state.shorts[newIndex];

    state = state.copyWith(
      currentIndex: newIndex,
      currentShort: newShort,
    );

    // Increment view count for previous short
    _incrementViewCount(newShort.id);
  }

  /// Jump to specific short by index
  void goToShort(int index) {
    if (index < 0 || index >= state.shorts.length) return;

    final newShort = state.shorts[index];

    state = state.copyWith(
      currentIndex: index,
      currentShort: newShort,
    );

    // Increment view count for new short
    _incrementViewCount(newShort.id);

    // Check if we need to load more shorts
    if (state.shouldLoadMore) {
      loadMoreShorts();
    }
  }

  /// Toggle play/pause
  void togglePlayPause() {
    state = state.copyWith(isPlaying: !state.isPlaying);
  }

  /// Set playing state
  void setPlaying(bool isPlaying) {
    state = state.copyWith(isPlaying: isPlaying);
  }

  /// Toggle mute
  void toggleMute() {
    state = state.copyWith(isMuted: !state.isMuted);
  }

  /// Set volume
  void setVolume(double volume) {
    state = state.copyWith(volume: volume.clamp(0.0, 1.0));
  }

  /// Like a short
  Future<void> likeShort(String shortId) async {
    try {
      await _repository.toggleLike(shortId);
      
      // Update the short in the list
      final updatedShorts = state.shorts.map((short) {
        if (short.id == shortId) {
          return short.copyWith(likes: short.likes + 1);
        }
        return short;
      }).toList();

      state = state.copyWith(shorts: updatedShorts);

      // Update current short if it matches
      if (state.currentShort?.id == shortId) {
        final updatedCurrentShort = updatedShorts.firstWhere((s) => s.id == shortId);
        state = state.copyWith(currentShort: updatedCurrentShort);
      }
    } catch (e) {
      debugPrint('Error liking short: $e');
      // Show error to user if needed
    }
  }

  /// Increment view count (internal method)
  void _incrementViewCount(String shortId) {
    // Fire and forget - don't await
    _repository.incrementViewCount(shortId).catchError((e) {
      debugPrint('Error incrementing view count: $e');
    });
  }

  /// Refresh shorts (pull to refresh)
  Future<void> refreshShorts() async {
    _currentPage = 1;
    state = ShortsState.initial();
    await loadShorts();
  }

  /// Load shorts by genre
  Future<void> loadShortsByGenre(String genreId) async {
    if (state.isLoading) return;

    try {
      state = state.copyWith(isLoading: true, error: null);

      final shorts = await _repository.getShortsByGenre(genreId, perPage: _perPage);
      
      if (shorts.isEmpty) {
        state = state.copyWith(
          isLoading: false,
          hasReachedMax: true,
        );
        return;
      }

      state = state.copyWith(
        shorts: shorts,
        currentIndex: 0,
        currentShort: shorts.isNotEmpty ? shorts.first : null,
        isLoading: false,
        hasReachedMax: shorts.length < _perPage,
      );

      _currentPage = 1;

      // Auto-increment view count for first short
      if (shorts.isNotEmpty) {
        _incrementViewCount(shorts.first.id);
      }
    } catch (e) {
      debugPrint('Error loading shorts by genre: $e');
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Load trending shorts
  Future<void> loadTrendingShorts() async {
    if (state.isLoading) return;

    try {
      state = state.copyWith(isLoading: true, error: null);

      final shorts = await _repository.getTrendingShorts(perPage: _perPage);
      
      if (shorts.isEmpty) {
        state = state.copyWith(
          isLoading: false,
          hasReachedMax: true,
        );
        return;
      }

      state = state.copyWith(
        shorts: shorts,
        currentIndex: 0,
        currentShort: shorts.isNotEmpty ? shorts.first : null,
        isLoading: false,
        hasReachedMax: shorts.length < _perPage,
      );

      _currentPage = 1;

      // Auto-increment view count for first short
      if (shorts.isNotEmpty) {
        _incrementViewCount(shorts.first.id);
      }
    } catch (e) {
      debugPrint('Error loading trending shorts: $e');
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }
} 