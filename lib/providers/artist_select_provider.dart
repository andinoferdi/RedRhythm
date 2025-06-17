import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/artist_select.dart';
import '../repositories/artist_select_repository.dart';
import '../services/pocketbase_service.dart';
import 'dart:async';

// Artist Select Provider
class ArtistSelectProvider extends StateNotifier<List<ArtistSelect>> {
  Timer? _refreshTimer;
  final ArtistSelectRepository _repository;

  ArtistSelectProvider(this._repository) : super([]) {
    _startAutoRefresh();
    loadSelectedArtists(); // Initial load
  }

  void _startAutoRefresh() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      loadSelectedArtists();
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  /// Load selected artists for current user
  Future<void> loadSelectedArtists() async {
    try {
      final selections = await _repository.getUserSelectedArtists();
      state = selections;
    } catch (e) {
      print('Error loading selected artists: $e');
      // Keep current state on error
    }
  }

  /// Add artist selection
  Future<bool> addArtistSelection(String artistId) async {
    try {
      final result = await _repository.addArtistSelection(artistId);
      if (result != null) {
        // Add to current state
        state = [...state, result];
        return true;
      }
      return false;
    } catch (e) {
      print('Error adding artist selection: $e');
      return false;
    }
  }

  /// Remove artist selection
  Future<bool> removeArtistSelection(String artistId) async {
    try {
      final success = await _repository.removeArtistSelection(artistId);
      if (success) {
        // Remove from current state
        state = state.where((selection) => selection.artistId != artistId).toList();
        return true;
      }
      return false;
    } catch (e) {
      print('Error removing artist selection: $e');
      return false;
    }
  }

  /// Add multiple artist selections
  Future<void> addMultipleArtistSelections(List<String> artistIds) async {
    try {
      final results = await _repository.addMultipleArtistSelections(artistIds);
      if (results.isNotEmpty) {
        // Add to current state
        state = [...state, ...results];
      }
    } catch (e) {
      print('Error adding multiple artist selections: $e');
    }
  }

  /// Check if artist is selected
  bool isArtistSelected(String artistId) {
    return state.any((selection) => selection.artistId == artistId);
  }

  /// Get selected artist IDs
  List<String> getSelectedArtistIds() {
    return state.map((selection) => selection.artistId).toList();
  }

  /// Notify that artist selections have been updated (for manual refresh)
  void notifyArtistSelectionsUpdated() {
    loadSelectedArtists();
  }

  /// Refresh selected artists manually
  Future<void> refreshSelectedArtists() async {
    await loadSelectedArtists();
  }
}

// Repository provider
final artistSelectRepositoryProvider = Provider<ArtistSelectRepository>((ref) {
  final pocketBaseService = PocketBaseService();
  return ArtistSelectRepository(pocketBaseService);
});

// Artist select provider
final artistSelectProvider = StateNotifierProvider<ArtistSelectProvider, List<ArtistSelect>>((ref) {
  final repository = ref.watch(artistSelectRepositoryProvider);
  return ArtistSelectProvider(repository);
});

// Auto-refresh artist select provider
final autoRefreshArtistSelectProvider = Provider<List<ArtistSelect>>((ref) {
  return ref.watch(artistSelectProvider);
}); 