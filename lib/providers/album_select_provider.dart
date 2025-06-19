import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/album_select.dart';
import '../repositories/album_select_repository.dart';
import '../services/pocketbase_service.dart';
import 'dart:async';

// Album Select Provider
class AlbumSelectProvider extends StateNotifier<List<AlbumSelect>> {
  Timer? _refreshTimer;
  final AlbumSelectRepository _repository;

  AlbumSelectProvider(this._repository) : super([]) {
    _startAutoRefresh();
    loadSelectedAlbums(); // Initial load
  }

  void _startAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      loadSelectedAlbums();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  /// Load selected albums for current user
  Future<void> loadSelectedAlbums() async {
    try {
      final selections = await _repository.getUserSelectedAlbums();
      state = selections;
    } catch (e) {
      // Keep current state on error
    }
  }

  /// Add album selection
  Future<bool> addAlbumSelection(String albumId) async {
    try {
      final result = await _repository.addAlbumSelection(albumId);
      if (result != null) {
        // Add to current state
        state = [...state, result];
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Remove album selection
  Future<bool> removeAlbumSelection(String albumId) async {
    try {
      final success = await _repository.removeAlbumSelection(albumId);
      if (success) {
        // Remove from current state
        state = state.where((selection) => selection.albumId != albumId).toList();
        return true;
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Add multiple album selections
  Future<void> addMultipleAlbumSelections(List<String> albumIds) async {
    try {
      final results = await _repository.addMultipleAlbumSelections(albumIds);
      if (results.isNotEmpty) {
        // Add to current state
        state = [...state, ...results];
      }
    } catch (e) {
      // Silently handle error
    }
  }

  /// Check if album is selected
  bool isAlbumSelected(String albumId) {
    return state.any((selection) => selection.albumId == albumId);
  }

  /// Get selected album IDs
  List<String> getSelectedAlbumIds() {
    return state.map((selection) => selection.albumId).toList();
  }

  /// Notify that album selections have been updated (for manual refresh)
  void notifyAlbumSelectionsUpdated() {
    loadSelectedAlbums();
  }

  /// Refresh selected albums manually
  Future<void> refreshSelectedAlbums() async {
    await loadSelectedAlbums();
  }
}

// Repository provider
final albumSelectRepositoryProvider = Provider<AlbumSelectRepository>((ref) {
  final pocketBaseService = PocketBaseService();
  return AlbumSelectRepository(pocketBaseService);
});

// Album select provider
final albumSelectProvider = StateNotifierProvider<AlbumSelectProvider, List<AlbumSelect>>((ref) {
  final repository = ref.watch(albumSelectRepositoryProvider);
  return AlbumSelectProvider(repository);
});

// Auto-refresh album select provider
final autoRefreshAlbumSelectProvider = Provider<List<AlbumSelect>>((ref) {
  return ref.watch(albumSelectProvider);
}); 