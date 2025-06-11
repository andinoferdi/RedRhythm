import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import '../../repositories/user_repository.dart';
import '../../services/pocketbase_service.dart';
import '../states/auth_state.dart';

/// Provider for the AuthController
final authControllerProvider = StateNotifierProvider<AuthController, AuthState>(
  (ref) => GetIt.I<AuthController>(),
);

/// Controller for handling authentication
class AuthController extends StateNotifier<AuthState> {
  final UserRepository _userRepository;
  final PocketBaseService _pocketBaseService = GetIt.I<PocketBaseService>();
  
  AuthController(this._userRepository) : super(AuthState.initial()) {
    _initializeAuth();
  }
  
  /// Initialize authentication and check for stored credentials
  Future<void> _initializeAuth() async {
    try {
      debugPrint('AuthController: Starting auth initialization...');
      state = AuthState.loading();
      
      // First ensure PocketBase is initialized
      await _pocketBaseService.initialize();
      debugPrint('AuthController: PocketBase initialized with URL: ${_pocketBaseService.pb.baseUrl}');
      
      // Check remember me preference
      final rememberMe = await _pocketBaseService.getRememberMe();
      debugPrint('AuthController: Remember me preference: $rememberMe');
      
            if (rememberMe && _pocketBaseService.isAuthenticated) {
        debugPrint('AuthController: Found stored auth, verifying...');
        // Try to get current user from stored auth
        final user = _pocketBaseService.currentUser;
        if (user != null) {
          debugPrint('AuthController: User found in storage: ${user.id}');
          
          // Try auth refresh with retry logic
          try {
            debugPrint('AuthController: Attempting auth refresh...');
            
            // First try normal refresh
            await _userRepository.refreshAuth();
            final freshUser = _userRepository.currentUser;
            if (freshUser != null) {
              debugPrint('AuthController: Auth token valid, user authenticated');
              state = AuthState.authenticated(freshUser);
              return;
            }
          } catch (e) {
            debugPrint('AuthController: Initial auth refresh failed: $e');
            
            // Try one more time with PocketBase service retry
            final retrySuccess = await _pocketBaseService.retryAuthRefresh();
            if (retrySuccess) {
              final freshUser = _userRepository.currentUser;
              if (freshUser != null) {
                debugPrint('AuthController: Auth refresh retry successful, user authenticated');
                state = AuthState.authenticated(freshUser);
                return;
              }
            }
            
            // If both attempts failed, check if it's a network error
            if (e.toString().contains('Connection') || 
                e.toString().contains('SocketException') ||
                e.toString().contains('NetworkException')) {
              debugPrint('AuthController: Network error detected, keeping stored auth for later retry');
              // Don't clear auth on network errors, just set unauthenticated state
              state = AuthState.unauthenticated();
              return;
            } else {
              debugPrint('AuthController: Auth token expired/invalid, clearing stored auth');
              // Token might be expired, clear stored auth
              await _pocketBaseService.logout();
              await _pocketBaseService.setRememberMe(false);
            }
          }
        }
      } else if (rememberMe) {
        debugPrint('AuthController: Remember me enabled but no stored auth found');
      } else {
        debugPrint('AuthController: Remember me disabled, clearing any stored auth');
        await _pocketBaseService.logout();
      }
      
      // If we reach here, user is not authenticated
      debugPrint('AuthController: User not authenticated, setting unauthenticated state');
      state = AuthState.unauthenticated();
    } catch (e) {
      debugPrint('AuthController: Error during auth initialization: $e');
      
      // Check if it's a network error
      if (e.toString().contains('Connection') || 
          e.toString().contains('SocketException') ||
          e.toString().contains('NetworkException')) {
        debugPrint('AuthController: Network error during initialization, setting unauthenticated');
        state = AuthState.unauthenticated();
      } else {
        state = AuthState.error('Connection failed. Please check your network and try again.');
        // Fallback to unauthenticated state after showing error
        Future.delayed(const Duration(seconds: 3), () {
          if (mounted) {
            debugPrint('AuthController: Fallback to unauthenticated after error');
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
      await _userRepository.logout();
      await _pocketBaseService.setRememberMe(false);
      state = AuthState.unauthenticated();
    } catch (e) {
      // Even if logout fails, clear local state
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
        logout();
      }
    }
  }
  
  /// Force re-initialization of auth (useful for app resume)
  Future<void> reinitializeAuth() async {
    debugPrint('Reinitializing auth...');
    
    // Only reinitialize if we're not currently loading
    if (state.isLoading) {
      debugPrint('Auth already loading, skipping reinitialize');
      return;
    }
    
    // Check remember me preference first
    final rememberMe = await _pocketBaseService.getRememberMe();
    debugPrint('Remember me preference: $rememberMe');
    
    if (!rememberMe) {
      // If remember me is false, ensure we're not authenticated
      if (state.isAuthenticated) {
        debugPrint('Remember me is false but user is authenticated, logging out');
        await logout();
      }
      return;
    }
    
    // If remember me is true, check if we need to restore auth
    if (!state.isAuthenticated && _pocketBaseService.isAuthenticated) {
      debugPrint('Restoring auth from stored credentials');
      await _initializeAuth();
    } else if (state.isAuthenticated) {
      // If already authenticated, just verify the token is still valid
      try {
        await _userRepository.refreshAuth();
        debugPrint('Auth token refreshed successfully');
      } catch (e) {
        debugPrint('Auth token refresh failed, re-initializing');
        await _initializeAuth();
      }
    }
  }
} 