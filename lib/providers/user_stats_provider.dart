import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import '../repositories/user_stats_repository.dart';
import '../models/user_stats.dart';
import '../controllers/auth_controller.dart';

final userStatsRepositoryProvider = Provider<UserStatsRepository>((ref) {
  return GetIt.I<UserStatsRepository>();
});

final userStatsProvider = FutureProvider<UserStats?>((ref) async {
  final authState = ref.watch(authControllerProvider);
  
  if (!authState.isAuthenticated || authState.user == null) {
    return null;
  }
  
  final repository = ref.read(userStatsRepositoryProvider);
  final userId = authState.user!.id;
  
  try {
    return await repository.getUserStats(userId);
  } catch (e) {
    // Return default stats if error occurs
    return UserStats(
      songsPlayed: 0,
      playlistsCount: 0,
      likedSongs: 0,
      following: 0,
    );
  }
}); 