import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/artist_repository.dart';
import '../services/pocketbase_service.dart';
import '../models/artist.dart';
import 'dart:io';

// Artist State
class ArtistState {
  final List<Artist> artists;
  final bool isLoading;
  final String? error;
  final List<Artist> searchResults;
  final bool isSearching;

  ArtistState({
    this.artists = const [],
    this.isLoading = false,
    this.error,
    this.searchResults = const [],
    this.isSearching = false,
  });

  ArtistState copyWith({
    List<Artist>? artists,
    bool? isLoading,
    String? error,
    List<Artist>? searchResults,
    bool? isSearching,
  }) {
    return ArtistState(
      artists: artists ?? this.artists,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      searchResults: searchResults ?? this.searchResults,
      isSearching: isSearching ?? this.isSearching,
    );
  }
}

// Artist Controller
class ArtistController extends StateNotifier<ArtistState> {
  final ArtistRepository _repository;

  ArtistController(this._repository) : super(ArtistState());

  /// Load all artists
  Future<void> loadArtists() async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final artists = await _repository.getAllArtists();
      
      state = state.copyWith(
        artists: artists,
        isLoading: false,
      );
    } catch (e) {
      debugPrint('Error loading artists: $e');
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// Create new artist
  Future<bool> createArtist({
    required String name,
    required String bio,
    File? imageFile,
  }) async {
    state = state.copyWith(isLoading: true, error: null);
    
    try {
      final artist = await _repository.createArtist(
        name: name,
        bio: bio,
        imageFile: imageFile,
      );
      
      if (artist != null) {
        // Add to current list
        final updatedArtists = [...state.artists, artist];
        state = state.copyWith(
          artists: updatedArtists,
          isLoading: false,
        );
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Failed to create artist',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  /// Search artists
  Future<void> searchArtists(String query) async {
    if (query.isEmpty) {
      state = state.copyWith(searchResults: [], isSearching: false);
      return;
    }

    state = state.copyWith(isSearching: true);
    
    try {
      final results = await _repository.searchArtists(query);
      state = state.copyWith(
        searchResults: results,
        isSearching: false,
      );
    } catch (e) {
      state = state.copyWith(
        isSearching: false,
        error: e.toString(),
      );
    }
  }

  /// Clear search
  void clearSearch() {
    state = state.copyWith(searchResults: [], isSearching: false);
  }

  /// Refresh artists
  Future<void> refreshArtists() async {
    await loadArtists();
  }
}

// Providers
final artistRepositoryProvider = Provider<ArtistRepository>((ref) {
  final pocketBaseService = PocketBaseService();
  return ArtistRepository(pocketBaseService);
});

final artistControllerProvider = StateNotifierProvider<ArtistController, ArtistState>((ref) {
  final repository = ref.watch(artistRepositoryProvider);
  return ArtistController(repository);
});
