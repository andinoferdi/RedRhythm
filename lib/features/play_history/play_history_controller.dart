import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/play_history.dart';
import 'play_history_repository.dart';
import '../auth/auth_controller.dart';
import '../../services/pocketbase_service.dart';

// State untuk play history
class PlayHistoryState {
  final List<PlayHistory> recentlyPlayed;
  final bool isLoading;
  final String? error;

  PlayHistoryState({
    this.recentlyPlayed = const [],
    this.isLoading = false,
    this.error,
  });

  PlayHistoryState copyWith({
    List<PlayHistory>? recentlyPlayed,
    bool? isLoading,
    String? error,
  }) {
    return PlayHistoryState(
      recentlyPlayed: recentlyPlayed ?? this.recentlyPlayed,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

// Provider untuk repository
final playHistoryRepositoryProvider = Provider<PlayHistoryRepository>((ref) {
  final pb = ref.watch(pocketBaseProvider);
  return PlayHistoryRepository(pb);
});

// Provider untuk PocketBase instance
final pocketBaseProvider = Provider((ref) {
  return pocketBaseService.pb;
});

// Controller provider
class PlayHistoryController extends StateNotifier<PlayHistoryState> {
  final PlayHistoryRepository _repository;
  final AuthController _authController;

  PlayHistoryController(this._repository, this._authController)
      : super(PlayHistoryState());

  Future<void> loadRecentlyPlayed({int limit = 5}) async {
    try {
      // Cek apakah user sudah login
      final user = _authController.state.user;
      
      if (user == null) {
        state = state.copyWith(
          error: 'User not logged in',
          isLoading: false,
        );
        return;
      }

      state = state.copyWith(isLoading: true, error: null);

      // Cek jika userId valid
      final userId = user.id;
      if (userId.isEmpty) {
        state = state.copyWith(
          error: 'Invalid user ID',
          isLoading: false,
        );
        return;
      }

      final histories = await _repository.getRecentlyPlayed(userId, limit: limit);

      state = state.copyWith(
        recentlyPlayed: histories,
        isLoading: false,
      );
    } catch (e) {
      // Jangan rethrow, hanya update state dengan error
      state = state.copyWith(
        error: 'Failed to load recently played: $e',
        isLoading: false,
        // Pastikan recentlyPlayed tidak null
        recentlyPlayed: [],
      );
    }
  }

  Future<void> addPlayHistory(String songId, {int? durationSeconds, bool completed = false}) async {
    final user = _authController.state.user;
    if (user == null) {
      return;
    }

    try {
      await _repository.addPlayHistory(
        userId: user.id,
        songId: songId,
        durationSeconds: durationSeconds,
        completed: completed,
      );
      
      // Reload data setelah menambahkan history baru
      await loadRecentlyPlayed();
    } catch (e) {
      state = state.copyWith(
        error: 'Failed to add play history: $e',
      );
    }
  }
}

// Provider untuk PlayHistoryController
final playHistoryControllerProvider =
    StateNotifierProvider<PlayHistoryController, PlayHistoryState>((ref) {
  final repository = ref.watch(playHistoryRepositoryProvider);
  final authController = ref.watch(authControllerProvider.notifier);
  return PlayHistoryController(repository, authController);
});

// Provider untuk recently played songs (lebih mudah digunakan di UI)
final recentlyPlayedProvider = Provider<List<PlayHistory>>((ref) {
  return ref.watch(playHistoryControllerProvider).recentlyPlayed;
}); 