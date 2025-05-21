import 'package:pocketbase/pocketbase.dart';
import '../services/pocketbase_service.dart';

/// Repository for handling user-related data
class UserRepository {
  final PocketBaseService _pocketBaseService;
  
  UserRepository(this._pocketBaseService);
  
  /// Get PocketBase instance
  PocketBase get _pb => _pocketBaseService.pb;
  
  /// Login with email and password
  Future<RecordModel> login(String email, String password) async {
    try {
      final authData = await _pb.collection('users').authWithPassword(
        email,
        password,
      );
      
      if (authData.record == null) {
        throw Exception('Username or password is incorrect');
      }
      
      return authData.record!;
    } catch (e) {
      // Check if the error is related to authentication
      if (e.toString().contains('Failed to authenticate') || 
          e.toString().contains('400') ||
          e.toString().contains('auth-with') ||
          e.toString().contains('failed')) {
        throw Exception('Username or password is incorrect');
      }
      // For network errors
      if (e.toString().contains('SocketException') || 
          e.toString().contains('Connection') ||
          e.toString().contains('network')) {
        throw Exception('Network error. Please check your connection');
      }
      // For server errors
      if (e.toString().contains('500')) {
        throw Exception('Server error. Please try again later');
      }
      // Generic error fallback
      throw Exception('Login failed. Please try again');
    }
  }
  
  /// Register a new user
  Future<RecordModel> register(String email, String password, String name) async {
    try {
      final userData = <String, dynamic>{
        'email': email,
        'password': password,
        'passwordConfirm': password,
        'name': name,
      };
      
      return await _pb.collection('users').create(body: userData);
    } catch (e) {
      // Check if it's an email already exists error
      if (e.toString().contains('email') && e.toString().contains('exists')) {
        throw Exception('An account with this email already exists');
      }
      throw Exception('Registration failed: ${e.toString().replaceAll('Exception:', '')}');
    }
  }
  
  /// Logout the current user
  Future<void> logout() async {
    _pb.authStore.clear();
  }
  
  /// Check if user is authenticated
  bool get isAuthenticated => _pb.authStore.isValid;
  
  /// Get current user info
  RecordModel? get currentUser => _pb.authStore.model;
  
  /// Get user profile
  Future<RecordModel> getUserProfile(String userId) async {
    try {
      return await _pb.collection('users').getOne(userId);
    } catch (e) {
      throw Exception('Failed to get user profile: $e');
    }
  }
  
  /// Update user profile
  Future<RecordModel> updateUserProfile(String userId, Map<String, dynamic> data) async {
    try {
      return await _pb.collection('users').update(userId, body: data);
    } catch (e) {
      throw Exception('Failed to update user profile: $e');
    }
  }
  
  /// Refresh authentication
  Future<void> refreshAuth() async {
    try {
      if (_pb.authStore.isValid) {
        await _pb.collection('users').authRefresh();
      }
    } catch (e) {
      // If refresh fails, clear auth
      _pb.authStore.clear();
      throw Exception('Failed to refresh authentication: $e');
    }
  }
} 