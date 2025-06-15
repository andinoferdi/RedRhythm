import 'package:get_it/get_it.dart';
import '../../services/pocketbase_service.dart';
import '../../services/audio_duration_service.dart';
import '../../repositories/song_repository.dart';
import '../../repositories/user_repository.dart';
import '../../repositories/genre_repository.dart';
import '../../controllers/auth_controller.dart';

/// Sets up dependency injection using GetIt
Future<void> setupServiceLocator() async {
  final getIt = GetIt.instance;
  
  // Services - Singleton
  getIt.registerLazySingleton<PocketBaseService>(() => PocketBaseService());
  getIt.registerLazySingleton<AudioDurationService>(() => AudioDurationService());
  
  // Repositories - Singleton
  getIt.registerLazySingleton<SongRepository>(() => SongRepository(
    getIt<PocketBaseService>(),
  ));
  
  getIt.registerLazySingleton<UserRepository>(() => UserRepository(
    getIt<PocketBaseService>(),
  ));
  
  getIt.registerLazySingleton<GenreRepository>(() => GenreRepository(
    getIt<PocketBaseService>(),
  ));
  
  // Controllers - Factory (new instance each time)
  getIt.registerFactory<AuthController>(() => AuthController(
    getIt<UserRepository>(),
  ));
  
  // PlayerController is now managed by Riverpod, not GetIt
}
