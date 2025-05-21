import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pocketbase/pocketbase.dart';
import '../../models/play_history.dart';
import 'play_history_repository.dart';
import '../auth/auth_controller.dart';

// Import untuk akses PocketBase instance
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
  // Menggunakan PocketBaseService yang sudah ada
  final pb = ref.watch(pocketBaseProvider);
  return PlayHistoryRepository(pb);
});

// Provider untuk PocketBase instance
final pocketBaseProvider = Provider((ref) {
  // Mengambil PocketBase instance yang sudah diinisialisasi
  // dari pocketbase_service.dart
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
      
      // DEBUG: Print logged in user details
      print('======= DEBUG: PLAY HISTORY LOADING =======');
      print('AuthController state: ${_authController.state}');
      print('Current logged-in user: ${user?.id} (${user?.data['name'] ?? 'no name'})');
      
      if (user == null) {
        print('DEBUG: User not logged in or userId is null');
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
        print('DEBUG: User ID is empty');
        state = state.copyWith(
          error: 'Invalid user ID',
          isLoading: false,
        );
        return;
      }

      print('DEBUG: Loading history for user ID: $userId');
      
      // Test direct PocketBase access to verify connection
      try {
        print('DEBUG: Testing direct PocketBase access...');
        final allRecords = await pocketBaseService.pb.collection('user_history').getFullList();
        print('DEBUG: All user_history records count: ${allRecords.length}');
        
        print('DEBUG: Listing all user_history records:');
        for (final record in allRecords) {
          print('  Record ID: ${record.id}');
          print('  user_id value: ${record.data['user_id']}');
          print('  song_id value: ${record.data['song_id']}');
          print('  played_at: ${record.data['played_at']}');
          
          // Check if this record should match our user
          final bool shouldMatch = record.data['user_id'] == userId;
          print('  ✓ Match with current user? $shouldMatch');
          print('  ---');
        }
      } catch (e) {
        print('DEBUG: Error testing PocketBase access: $e');
      }

      final histories = await _repository.getRecentlyPlayed(userId, limit: limit);
      print('DEBUG: Repository returned ${histories.length} history items');
      
      for (int i = 0; i < histories.length; i++) {
        print('DEBUG: History item $i:');
        print('  songTitle: ${histories[i].songTitle}');
        print('  artistName: ${histories[i].artistName}');
        print('  albumCoverUrl: ${histories[i].albumCoverUrl != null ? 'Has URL' : 'No URL'}');
      }

      state = state.copyWith(
        recentlyPlayed: histories,
        isLoading: false,
      );
      print('DEBUG: State updated with ${histories.length} items');
      print('======= DEBUG: PLAY HISTORY LOADING COMPLETE =======');
    } catch (e, stackTrace) {
      print('PlayHistoryController error: $e');
      print('Stack trace: $stackTrace');
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