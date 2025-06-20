import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import '../repositories/favorite_repository.dart';
import '../services/pocketbase_service.dart';
import '../models/song.dart';

/// State class for favorites
class FavoriteState {
  final List<Song> favoriteSongs;
  final bool isLoading;
  final String? error;
  final DateTime? lastUpdated;

  const FavoriteState({
    this.favoriteSongs = const [],
    this.isLoading = false,
    this.error,
    this.lastUpdated,
  });

  FavoriteState copyWith({
    List<Song>? favoriteSongs,
    bool? isLoading,
    String? error,
    DateTime? lastUpdated,
  }) {
    return FavoriteState(
      favoriteSongs: favoriteSongs ?? this.favoriteSongs,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }
}

/// Provider for favorites repository
final favoriteRepositoryProvider = Provider<FavoriteRepository>((ref) {
  return FavoriteRepository(GetIt.I<PocketBaseService>());
});

/// Provider for favorites state
final favoriteProvider = StateNotifierProvider<FavoriteNotifier, FavoriteState>((ref) {
  return FavoriteNotifier(ref.read(favoriteRepositoryProvider));
});

/// Auto-refresh favorites provider
final autoRefreshFavoriteProvider = Provider<FavoriteState>((ref) {
  return ref.watch(favoriteProvider);
});

/// StateNotifier for managing favorites
class FavoriteNotifier extends StateNotifier<FavoriteState> {
  final FavoriteRepository _repository;

  FavoriteNotifier(this._repository) : super(const FavoriteState());

  /// Load favorite songs
  Future<void> loadFavorites() async {
    if (state.isLoading) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      final favoriteSongs = await _repository.getFavoriteSongs();
      state = state.copyWith(
        favoriteSongs: favoriteSongs,
        isLoading: false,
        lastUpdated: DateTime.now(),
      );
    } catch (e) {
      debugPrint('Error loading favorites: $e');
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Refresh favorites (force reload)
  Future<void> refreshFavorites() async {
    try {
      state = state.copyWith(isLoading: true, error: null);
      final favoriteSongs = await _repository.refreshFavorites();
      state = state.copyWith(
        favoriteSongs: favoriteSongs,
        isLoading: false,
        lastUpdated: DateTime.now(),
      );
    } catch (e) {
      debugPrint('Error refreshing favorites: $e');
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Add song to favorites
  Future<bool> addToFavorites(String songId) async {
    try {
      await _repository.addToFavorites(songId);
      
      // Reload favorites to update UI
      await loadFavorites();
      
      return true;
    } catch (e) {
      debugPrint('Error adding to favorites: $e');
      state = state.copyWith(error: e.toString());
      return false;
    }
  }

  /// Remove song from favorites
  Future<bool> removeFromFavorites(String songId) async {
    try {
      await _repository.removeFromFavorites(songId);
      
      // Remove from current state immediately for better UX
      final updatedSongs = state.favoriteSongs.where((song) => song.id != songId).toList();
      state = state.copyWith(
        favoriteSongs: updatedSongs,
        lastUpdated: DateTime.now(),
      );
      
      return true;
    } catch (e) {
      debugPrint('Error removing from favorites: $e');
      state = state.copyWith(error: e.toString());
      // Reload favorites to ensure consistency
      loadFavorites();
      return false;
    }
  }

  /// Check if song is favorite
  Future<bool> isFavorite(String songId) async {
    try {
      return await _repository.isFavorite(songId);
    } catch (e) {
      debugPrint('Error checking favorite status: $e');
      return false;
    }
  }

  /// Get favorite count
  Future<int> getFavoriteCount() async {
    try {
      return await _repository.getFavoriteCount();
    } catch (e) {
      debugPrint('Error getting favorite count: $e');
      return 0;
    }
  }

  /// Clear favorites (useful for logout)
  void clearFavorites() {
    state = const FavoriteState();
  }

  /// Notify that favorites were updated externally
  void notifyFavoritesUpdated() {
    loadFavorites();
  }

  /// Check if a song is in current favorites list (from state)
  bool isSongInFavorites(String songId) {
    return state.favoriteSongs.any((song) => song.id == songId);
  }
} 