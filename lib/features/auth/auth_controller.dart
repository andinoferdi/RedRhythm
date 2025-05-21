import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/pocketbase_service.dart';
import 'auth_state.dart';

/// Provider for the AuthController
final authControllerProvider = StateNotifierProvider<AuthController, AuthState>(
  (ref) => AuthController(),
);

/// Controller for handling authentication
class AuthController extends StateNotifier<AuthState> {
  final PocketBaseService _pocketBaseService = PocketBaseService();
  
  AuthController() : super(AuthState.initial()) {
    _checkAuthStatus();
  }
  
  /// Checks the current authentication status
  Future<void> _checkAuthStatus() async {
    try {
      if (_pocketBaseService.isAuthenticated) {
        final user = _pocketBaseService.currentUser;
        if (user != null) {
          state = AuthState.authenticated(user);
        } else {
          state = AuthState.unauthenticated();
        }
      } else {
        state = AuthState.unauthenticated();
      }
    } catch (e) {
      state = AuthState.error(e.toString());
    }
  }

  /// Login with email and password
  Future<void> login(String email, String password) async {
    try {
      state = AuthState.loading();
      final user = await _pocketBaseService.login(email, password);
      state = AuthState.authenticated(user);
    } catch (e) {
      state = AuthState.error(e.toString());
    }
  }

  /// Register a new user
  Future<bool> register(String email, String password, String name) async {
    try {
      state = AuthState.loading();
      await _pocketBaseService.register(email, password, name);
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
    await _pocketBaseService.logout();
    state = state.copyWith(user: null);
  }

  // Refresh user data from server
  Future<void> refreshUser() async {
    if (!_pocketBaseService.isAuthenticated || _pocketBaseService.currentUser == null) {
      return;
    }
    
    try {
      // Gunakan direct access ke PocketBase untuk refresh auth
      final pb = _pocketBaseService.pb;
      if (pb.authStore.isValid) {
        await pb.collection('users').authRefresh();
        
        if (pb.authStore.model != null) {
          final userId = pb.authStore.model!.id;
          
          // Langsung fetch user dari PocketBase
          final freshUserData = await pb.collection('users').getOne(userId);
          state = state.copyWith(user: freshUserData);
        }
      }
    } catch (e) {
      // If refresh fails, clear auth
      if (e.toString().contains('401') || e.toString().contains('auth')) {
        logout();
      }
    }
  }
} 