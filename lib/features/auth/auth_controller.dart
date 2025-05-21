import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import '../../repositories/user_repository.dart';
import '../../services/pocketbase_service.dart';
import 'auth_state.dart';

/// Provider for the AuthController
final authControllerProvider = StateNotifierProvider<AuthController, AuthState>(
  (ref) => GetIt.I<AuthController>(),
);

/// Controller for handling authentication
class AuthController extends StateNotifier<AuthState> {
  final UserRepository _userRepository;
  final PocketBaseService _pocketBaseService = GetIt.I<PocketBaseService>();
  
  AuthController(this._userRepository) : super(AuthState.initial()) {
    _checkAuthStatus();
  }
  
  /// Checks the current authentication status
  Future<void> _checkAuthStatus() async {
    try {
      if (_userRepository.isAuthenticated) {
        final user = _userRepository.currentUser;
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
    await _userRepository.logout();
    state = AuthState.unauthenticated();
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
} 