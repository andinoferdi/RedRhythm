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
        throw Exception('Login failed: No user record returned');
      }
      
      return authData.record!;
    } catch (e) {
      throw Exception('Login failed: $e');
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
      throw Exception('Registration failed: $e');
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