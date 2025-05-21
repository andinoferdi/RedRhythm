import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import '../../repositories/genre_repository.dart';
import '../../models/genre_model.dart';

/// Genre state class without freezed
class GenreState {
  final List<GenreModel> genres;
  final bool isLoading;
  final String? error;
  final bool hasLoaded;

  const GenreState({
    this.genres = const [],
    this.isLoading = false,
    this.error,
    this.hasLoaded = false,
  });

  /// Create a copy of this state
  GenreState copyWith({
    List<GenreModel>? genres,
    bool? isLoading,
    String? error,
    bool? hasLoaded,
  }) {
    return GenreState(
      genres: genres ?? this.genres,
      isLoading: isLoading ?? this.isLoading,
      error: error,
      hasLoaded: hasLoaded ?? this.hasLoaded,
    );
  }

  /// Initial state
  factory GenreState.initial() => const GenreState();
}

/// Genre controller notifier
class GenreController extends StateNotifier<GenreState> {
  final GenreRepository _genreRepository;

  GenreController(this._genreRepository) : super(GenreState.initial());

  /// Load all genres
  Future<void> loadGenres() async {
    if (state.genres.isNotEmpty && state.error == null) {
      return;
    }

    state = state.copyWith(isLoading: true, error: null);

    try {
      final genres = await _genreRepository.getGenres();
      
      state = state.copyWith(
        genres: genres,
        isLoading: false,
        hasLoaded: true,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }
}

/// Provider for genre controller
final genreControllerProvider = StateNotifierProvider<GenreController, GenreState>((ref) {
  return GenreController(GetIt.I<GenreRepository>());
}); 