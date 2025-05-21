import 'package:flutter/foundation.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:io' show Platform;
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Service class for PocketBase API interactions
class PocketBaseService {
  static final PocketBaseService _instance = PocketBaseService._internal();
  
  late final PocketBase _pb;
  final _storage = const FlutterSecureStorage();
  bool _isInitialized = false;
  
  // Singleton pattern
  factory PocketBaseService() {
    return _instance;
  }
  
  PocketBaseService._internal() {
    // Initialize PocketBase with your server URL
    // Use 10.0.2.2 instead of 127.0.0.1 for Android emulators
    _isInitialized = true; // Mark as initialized
    final host = Platform.isAndroid ? '10.0.2.2' : '127.0.0.1';
    _pb = PocketBase('http://$host:8090');
    _initAuth();
  }
  
  /// Initialize authentication from secure storage
  Future<void> _initAuth() async {
    try {
      // Try to load the auth store data from secure storage
      final authJson = await _storage.read(key: 'pb_auth');
      if (authJson != null) {
        // If we have stored auth data, restore it
        _pb.authStore.save(authJson, await _getToken());
        
        // Verify the token is still valid
        if (_pb.authStore.isValid) {
          // Try to refresh the auth if possible
          try {
            await _pb.collection('users').authRefresh();
          } catch (e) {
            // Clear the auth store if the refresh failed
            _pb.authStore.clear();
            await _storage.delete(key: 'pb_auth');
          }
        } else {
          // Clear the auth store if the token is invalid
          _pb.authStore.clear();
          await _storage.delete(key: 'pb_auth');
        }
      }
    } catch (e) {
      debugPrint('Error initializing auth: $e');
      // Clear auth on any error
      _pb.authStore.clear();
      await _storage.delete(key: 'pb_auth');
    }
    
    // Subscribe to auth changes to persist the state
    _pb.authStore.onChange.listen((e) async {
      if (_pb.authStore.isValid) {
        // Save the auth data to secure storage
        await _storage.write(
          key: 'pb_auth',
          value: _pb.authStore.token,
        );
        // Store model separately if needed
        if (_pb.authStore.model != null) {
          await _storage.write(
            key: 'pb_auth_model',
            value: _pb.authStore.model.toString(),
          );
        }
      } else {
        // Clear the auth data from secure storage
        await _storage.delete(key: 'pb_auth');
        await _storage.delete(key: 'pb_auth_model');
      }
    });
  }
  
  Future<String?> _getToken() async {
    return await _storage.read(key: 'pb_auth_token');
  }
  
  /// Check if user is authenticated
  bool get isAuthenticated => _pb.authStore.isValid;
  
  /// Get current user info
  RecordModel? get currentUser => _pb.authStore.model;

  /// Get the PocketBase instance
  PocketBase get pb => _pb;
  
  /// Login with email and password
  Future<RecordModel> login(String email, String password) async {
    final authData = await _pb.collection('users').authWithPassword(
      email,
      password,
    );
    
    if (authData.record == null) {
      throw Exception('Login failed: No user record returned');
    }
    
    return authData.record!;
  }
  
  /// Register a new user
  Future<RecordModel> register(String email, String password, String name) async {
    final userData = <String, dynamic>{
      'email': email,
      'password': password,
      'passwordConfirm': password,
      'name': name,
    };
    
    return await _pb.collection('users').create(body: userData);
  }
  
  /// Logout the current user
  Future<void> logout() async {
    _pb.authStore.clear();
  }

  Future<PocketBase> initialize() async {
    if (!_isInitialized) {
      final url = await determinePocketBaseUrl();
      _pb = PocketBase(url);
      _isInitialized = true;
    }
    return _pb;
  }

  PocketBase get instance {
    if (!_isInitialized) {
      throw Exception('PocketBase has not been initialized. Call initialize() first.');
    }
    return _pb;
  }

  Future<void> validateAPIAccess() async {
    if (!_isInitialized || !_pb.authStore.isValid) {
      return;
    }
    
    // List of collections to check
    final collections = [
      'songs',
      'albums',
      'artists',
      'genres',
      'user_history',
    ];
    
    for (final collection in collections) {
      try {
        await _pb.collection(collection).getList(page: 1, perPage: 1);
      } catch (e) {
        // Silently handle errors
      }
    }
    
    // Check user auth
    if (_pb.authStore.isValid) {
      try {
        await _pb.collection('users').authRefresh();
      } catch (e) {
        // Silently handle errors
      }
    }
  }
}

// Singleton instance
final pocketBaseService = PocketBaseService();

// Provider for PocketBase
final pocketBaseProvider = Provider<PocketBase>((ref) {
  return pocketBaseService.instance;
});

// Helper function to check if host is reachable
Future<bool> isHostReachable(String url) async {
  try {
    await PocketBase(url).health.check();
    return true;
  } catch (e) {
    return false;
  }
}

// Test and determine the best PocketBase URL
Future<String> determinePocketBaseUrl() async {
  final List<String> possibleUrls = [
    'http://10.0.2.2:8090',      // Standard Android emulator
    'http://127.0.0.1:8090',     // iOS simulator or local
  ];
  
  for (final url in possibleUrls) {
    if (await isHostReachable(url)) {
      return url;
    }
  }
  
  // Default to Android emulator address if nothing works
  return Platform.isAndroid ? 'http://10.0.2.2:8090' : 'http://127.0.0.1:8090';
} 