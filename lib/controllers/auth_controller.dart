import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';

import '../repositories/user_repository.dart';
import '../services/pocketbase_service.dart';
import '../states/auth_state.dart';
import '../utils/search_history_utils.dart';
import '../providers/user_provider.dart';
import '../providers/playlist_provider.dart';
import '../providers/play_history_provider.dart';
import '../providers/favorite_provider.dart';
import 'player_controller.dart';

final authControllerProvider = StateNotifierProvider<AuthController, AuthState>(
  (ref) => AuthController(GetIt.I<UserRepository>(), ref),
);

class AuthController extends StateNotifier<AuthState> {
  final UserRepository _userRepository;
  final PocketBaseService _pocketBaseService = GetIt.I<PocketBaseService>();
  final Ref _ref;

  AuthController(this._userRepository, this._ref) : super(AuthState.initial()) {
    _initializeAuth();
  }

  Future<void> _initializeAuth() async {
    try {
      state = AuthState.loading();
      
      await _pocketBaseService.initialize();

      final rememberMe = await _pocketBaseService.getRememberMe();
      
      if (rememberMe && _pocketBaseService.isAuthenticated) {
        final user = _pocketBaseService.currentUser;
        
        if (user != null) {
          try {
            await _userRepository.refreshAuth();
            final freshUser = _userRepository.currentUser;
            if (freshUser != null) {
              state = AuthState.authenticated(freshUser);
              return;
            }
          } catch (e) {
            final retrySuccess = await _pocketBaseService.retryAuthRefresh();
            if (retrySuccess) {
              final freshUser = _userRepository.currentUser;
              if (freshUser != null) {
                state = AuthState.authenticated(freshUser);
                return;
              }
            }
            
            if (e.toString().contains('Connection') || 
                e.toString().contains('SocketException') ||
                e.toString().contains('NetworkException')) {
              state = AuthState.unauthenticated();
              return;
            } else {
              await _pocketBaseService.logout();
              await _pocketBaseService.setRememberMe(false);
            }
          }
        }
      } else if (rememberMe) {
      } else {
        await _pocketBaseService.logout();
      }
      
      try {
        final playerController = _ref.read(playerControllerProvider.notifier);
        await playerController.stopAndReset();
      } catch (e) {
        debugPrint('Error stopping audio player (not authenticated): $e');
      }
      
      state = AuthState.unauthenticated();
    } catch (e) {
      if (e.toString().contains('Connection') || 
          e.toString().contains('SocketException') ||
          e.toString().contains('NetworkException')) {
        
        try {
          final playerController = _ref.read(playerControllerProvider.notifier);
          await playerController.stopAndReset();
        } catch (playerError) {
          debugPrint('Error stopping audio player (network error): $playerError');
        }
        
        state = AuthState.unauthenticated();
      } else {
        state = AuthState.error('Connection failed. Please check your network and try again.');
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            try {
              final playerController = _ref.read(playerControllerProvider.notifier);
              playerController.stopAndReset();
            } catch (playerError) {
              debugPrint('Error stopping audio player (fallback): $playerError');
            }
            
            state = AuthState.unauthenticated();
          }
        });
      }
    }
  }

  Future<void> login(String email, String password, [bool rememberMe = false]) async {
    try {
      state = AuthState.loading();

      await _pocketBaseService.setRememberMe(rememberMe);
      
      final user = await _userRepository.login(email, password);
      state = AuthState.authenticated(user);
    } catch (e) {
      state = AuthState.error(e.toString());
    }
  }

  Future<bool> register(String email, String password, String name) async {
    try {
      state = AuthState.loading();
      await _userRepository.register(email, password, name);
      state = AuthState.registrationSuccess("Registration successful! You can now log in.");
      return true;
    } catch (e) {
      state = AuthState.error(e.toString());
      return false;
    }
  }

  Future<void> logout() async {
    try {
      // Get current user ID before logout to clear their search history
      String? currentUserId;
      if (_userRepository.isAuthenticated && _userRepository.currentUser != null) {
        currentUserId = _userRepository.currentUser!.id;
      }

      try {
        final playerController = _ref.read(playerControllerProvider.notifier);
        await playerController.stopAndReset();
      } catch (e) {
        debugPrint('Error stopping audio player: $e');
      }

      await _userRepository.logout();
      await _pocketBaseService.setRememberMe(false);

      // Clear search history for the logged out user
      if (currentUserId != null) {
        try {
          await SearchHistoryUtils.clearUserSearchHistory(currentUserId);
        } catch (e) {
          debugPrint('Error clearing search history: $e');
        }
      }

      // Clear user-related provider data
      try {
        _ref.read(userProvider.notifier).clearUserCache();
        _ref.read(playlistProvider.notifier).clearPlaylists();
        _ref.read(playHistoryProvider.notifier).clearRecentlyPlayed();
        // Clear favorites
        try {
          _ref.read(favoriteProvider.notifier).clearFavorites();
        } catch (e) {
          debugPrint('Error clearing favorites: $e');
        }
      } catch (e) {
        debugPrint('Error clearing provider cache: $e');
      }

      state = AuthState.unauthenticated();
    } catch (e) {
      debugPrint('Error during logout: $e');
      
      try {
        final playerController = _ref.read(playerControllerProvider.notifier);
        await playerController.stopAndReset();
      } catch (playerError) {
        debugPrint('Error stopping audio player during fallback: $playerError');
      }
      
      state = AuthState.unauthenticated();
    }
  }

  Future<void> refreshUser() async {
    if (!_userRepository.isAuthenticated || _userRepository.currentUser == null) {
      return;
    }
    
    try {
      await _userRepository.refreshAuth();
      
      if (_userRepository.currentUser != null) {
        final userId = _userRepository.currentUser!.id;
        final freshUserData = await _userRepository.getUserProfile(userId);
        state = AuthState.authenticated(freshUserData);
      }
    } catch (e) {
      if (e.toString().contains('401') || e.toString().contains('auth')) {
        await logout();
      }
    }
  }

  Future<void> reinitializeAuth() async {
    if (state.isLoading) {
      return;
    }
    
    final rememberMe = await _pocketBaseService.getRememberMe();
    
    if (!rememberMe) {
      if (state.isAuthenticated) {
        await logout();
      } else {
        try {
          final playerController = _ref.read(playerControllerProvider.notifier);
          await playerController.stopAndReset();
        } catch (e) {
          debugPrint('Error stopping audio player (remember me disabled): $e');
        }
      }
      return;
    }

    if (!state.isAuthenticated && _pocketBaseService.isAuthenticated) {
      await _initializeAuth();
    } else if (state.isAuthenticated) {
     
      try {
        await _userRepository.refreshAuth();
      } catch (e) {
        await _initializeAuth();
      }
    }
  }

  Future<void> updateProfile({
    String? username,
    File? profileImage,
  }) async {
    if (!_userRepository.isAuthenticated || _userRepository.currentUser == null) {
      throw Exception('User not authenticated');
    }

    try {
      final currentUser = _userRepository.currentUser!;
      
      // Update profile via repository
      final updatedUser = await _userRepository.updateProfile(
        userId: currentUser.id,
        username: username,
        profileImage: profileImage,
      );
      
      // Update state with new user data
      state = AuthState.authenticated(updatedUser);
      
      // Refresh user provider cache
      _ref.read(userProvider.notifier).clearUserCache();
      
    } catch (e) {
      debugPrint('Error updating profile: $e');
      throw Exception('Failed to update profile: $e');
    }
  }
}




