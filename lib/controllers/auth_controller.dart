import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import '../repositories/user_repository.dart';
import '../services/pocketbase_service.dart';
import '../states/auth_state.dart';
import 'player_controller.dart';

/// Provider for the AuthController
final authControllerProvider = StateNotifierProvider<AuthController, AuthState>(
  (ref) => AuthController(GetIt.I<UserRepository>(), ref),
);

/// Controller for handling authentication
class AuthController extends StateNotifier<AuthState> {
  final UserRepository _userRepository;
  final PocketBaseService _pocketBaseService = GetIt.I<PocketBaseService>();
  final Ref _ref;

  AuthController(this._userRepository, this._ref) : super(AuthState.initial()) {
    _initializeAuth();
  }

  /// Initialize authentication and check for stored credentials
  Future<void> _initializeAuth() async {
    try {
      state = AuthState.loading();
      
      // First ensure PocketBase is initialized
      await _pocketBaseService.initialize();

      // Check remember me preference
      final rememberMe = await _pocketBaseService.getRememberMe();
      
      if (rememberMe && _pocketBaseService.isAuthenticated) {
        // Try to get current user from stored auth
        final user = _pocketBaseService.currentUser;
        
        if (user != null) {
          // Try auth refresh with retry logic
          try {
            // First try normal refresh
            await _userRepository.refreshAuth();
            final freshUser = _userRepository.currentUser;
            if (freshUser != null) {
              state = AuthState.authenticated(freshUser);
              return;
            }
          } catch (e) {
            // Try one more time with PocketBase service retry
            final retrySuccess = await _pocketBaseService.retryAuthRefresh();
            if (retrySuccess) {
              final freshUser = _userRepository.currentUser;
              if (freshUser != null) {
                state = AuthState.authenticated(freshUser);
                return;
              }
            }
            
            // If both attempts failed, check if it's a network error
            if (e.toString().contains('Connection') || 
                e.toString().contains('SocketException') ||
                e.toString().contains('NetworkException')) {
              // Don't clear auth on network errors, just set unauthenticated state
              state = AuthState.unauthenticated();
              return;
            } else {
              // Token might be expired, clear stored auth
              await _pocketBaseService.logout();
              await _pocketBaseService.setRememberMe(false);
            }
          }
        }
      } else if (rememberMe) {
        // Remember me enabled but no stored auth found - just continue to unauthenticated
      } else {
        // Remember me disabled, clear any stored auth
        await _pocketBaseService.logout();
      }
      
      // If we reach here, user is not authenticated
      // Stop audio player when not authenticated
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
        // Network error during initialization - set as unauthenticated for now
        
        // Stop audio player on network error
        try {
          final playerController = _ref.read(playerControllerProvider.notifier);
          await playerController.stopAndReset();
        } catch (playerError) {
          debugPrint('Error stopping audio player (network error): $playerError');
        }
        
        state = AuthState.unauthenticated();
      } else {
        state = AuthState.error('Connection failed. Please check your network and try again.');
        // Fallback to unauthenticated state after showing error
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            // Stop audio player on fallback
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

  /// Login with email and password
  Future<void> login(String email, String password, [bool rememberMe = false]) async {
    try {
      state = AuthState.loading();

      // Set remember me preference before login
      await _pocketBaseService.setRememberMe(rememberMe);
      
      // Perform login
      final user = await _userRepository.login(email, password);
      state = AuthState.authenticated(user);
    } catch (e) {
      state = AuthState.error(e.toString());
    }
  }

  /// Register a new user
  Future<bool> register(String email, String password, String name) async {
    try {
      state = AuthState.loading();
      await _userRepository.register(email, password, name);
      // Set state to registration success instead of logging in
      state = AuthState.registrationSuccess("Registration successful! You can now log in.");
      return true;
    } catch (e) {
      state = AuthState.error(e.toString());
      return false;
    }
  }

  /// Logout the current user
  Future<void> logout() async {
    try {
      // Stop audio player and reset state
      try {
        final playerController = _ref.read(playerControllerProvider.notifier);
        await playerController.stopAndReset();
      } catch (e) {
        debugPrint('Error stopping audio player: $e');
      }

      // Perform logout operations
      await _userRepository.logout();
      await _pocketBaseService.setRememberMe(false);

      state = AuthState.unauthenticated();
    } catch (e) {
      debugPrint('Error during logout: $e');
      
      // Even if logout fails, clear local state and stop player
      try {
        final playerController = _ref.read(playerControllerProvider.notifier);
        await playerController.stopAndReset();
      } catch (playerError) {
        debugPrint('Error stopping audio player during fallback: $playerError');
      }
      
      state = AuthState.unauthenticated();
    }
  }

  /// Refresh user data from server
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
      // If refresh fails, logout
      if (e.toString().contains('401') || e.toString().contains('auth')) {
        await logout();
      }
    }
  }

  /// Force re-initialization of auth (useful for app resume)
  Future<void> reinitializeAuth() async {
    // Only reinitialize if we're not currently loading
    if (state.isLoading) {
      return;
    }
    
    // Check remember me preference first
    final rememberMe = await _pocketBaseService.getRememberMe();
    
    if (!rememberMe) {
      // If remember me is false, ensure we're not authenticated
      if (state.isAuthenticated) {
        await logout();
      } else {
        // Even if not authenticated, stop any playing audio
        try {
          final playerController = _ref.read(playerControllerProvider.notifier);
          await playerController.stopAndReset();
        } catch (e) {
          debugPrint('Error stopping audio player (remember me disabled): $e');
        }
      }
      return;
    }

    // If remember me is true, check if we need to restore auth
    if (!state.isAuthenticated && _pocketBaseService.isAuthenticated) {
      await _initializeAuth();
    } else if (state.isAuthenticated) {
      // If already authenticated, just verify the token is still valid
      try {
        await _userRepository.refreshAuth();
      } catch (e) {
        await _initializeAuth();
      }
    }
  }
}

