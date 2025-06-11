import 'package:flutter/foundation.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../utils/app_config.dart';


/// Service class for PocketBase API interactions
class PocketBaseService {
  static final PocketBaseService _instance = PocketBaseService._internal();
  late final PocketBase _pb;
  final _storage = const FlutterSecureStorage();
  bool _isInitialized = false;
  bool _shouldRemember = false;
  
  factory PocketBaseService() {
    return _instance;
  }
  
  PocketBaseService._internal() {
    // Initialize with default URL from AppConfig
    _pb = PocketBase(AppConfig.defaultUrl);
    _initAuth();
  }
  
  /// Initialize authentication from secure storage
  Future<void> _initAuth() async {
    try {
      debugPrint('PocketBase: Initializing auth from storage...');
      // Check if we should remember the user
      final rememberStr = await _storage.read(key: 'remember_me');
      _shouldRemember = rememberStr == 'true';
      debugPrint('PocketBase: Remember me preference: $_shouldRemember');
      
      // If we shouldn't remember, don't load any auth data
      if (!_shouldRemember) {
        debugPrint('PocketBase: Remember me disabled, clearing stored auth');
        await _storage.delete(key: 'pb_auth');
        await _storage.delete(key: 'pb_auth_token');
        await _storage.delete(key: 'pb_auth_model');
        return;
      }
      
      // Try to load the auth store data from secure storage
      final authJson = await _storage.read(key: 'pb_auth');
      final authToken = await _storage.read(key: 'pb_auth_token');
      debugPrint('PocketBase: Stored auth token found: ${authToken != null}');
      
      if (authJson != null && authToken != null) {
        debugPrint('PocketBase: Restoring auth from storage...');
        // If we have stored auth data, restore it
        try {
          // Try to parse the stored model data
          final modelJson = await _storage.read(key: 'pb_auth_model');
          dynamic modelData;
          if (modelJson != null) {
            modelData = jsonDecode(modelJson);
          }
          
          _pb.authStore.save(authToken, modelData);
          debugPrint('PocketBase: Auth restored successfully - Token: ${authToken.substring(0, 10)}...');
          
          // Verify the token is still valid ONLY if base URL is properly set
          if (_pb.authStore.isValid && _pb.baseUrl.isNotEmpty && !_pb.baseUrl.contains('localhost')) {
            debugPrint('PocketBase: Auth token appears valid, attempting refresh...');
            // Try to refresh the auth if possible
            try {
              await _pb.collection('users').authRefresh();
              debugPrint('PocketBase: Auth token refreshed successfully');
            } catch (e) {
              debugPrint('PocketBase: Auth refresh failed: $e');
              // Don't clear auth on network errors, let controller handle it
              if (!e.toString().contains('Connection') && 
                  !e.toString().contains('SocketException') &&
                  !e.toString().contains('NetworkException')) {
                debugPrint('PocketBase: Clearing auth due to non-network error');
                _pb.authStore.clear();
                await _clearStoredAuth();
              } else {
                debugPrint('PocketBase: Keeping auth for network retry');
              }
            }
          } else if (!_pb.baseUrl.isNotEmpty || _pb.baseUrl.contains('localhost')) {
            debugPrint('PocketBase: Base URL not ready, skipping auth refresh');
          } else {
            debugPrint('PocketBase: Auth token invalid, clearing stored auth');
            // Clear the auth store if the token is invalid
            _pb.authStore.clear();
            await _clearStoredAuth();
          }
        } catch (e) {
          debugPrint('PocketBase: Error restoring auth: $e');
          // If restore fails, clear the stored data
          await _clearStoredAuth();
          return;
        }
      } else {
        debugPrint('PocketBase: No stored auth data found');
      }
    } catch (e) {
      debugPrint('PocketBase: Error initializing auth: $e');
      // Clear auth on any error that's not network related
      if (!e.toString().contains('Connection') && 
          !e.toString().contains('SocketException') &&
          !e.toString().contains('NetworkException')) {
        _pb.authStore.clear();
        await _clearStoredAuth();
      }
    }
    
    // Subscribe to auth changes to persist the state
    _pb.authStore.onChange.listen((e) async {
      if (_pb.authStore.isValid && _shouldRemember) {
        debugPrint('PocketBase: Auth changed, saving to storage...');
        // Only save if remember me is enabled
        await _saveAuthToStorage();
      } else if (!_pb.authStore.isValid) {
        debugPrint('PocketBase: Auth cleared, removing from storage...');
        // Always clear auth data when logging out
        await _clearStoredAuth();
      }
    });
  }
  
  /// Save auth data to secure storage
  Future<void> _saveAuthToStorage() async {
    try {
      debugPrint('PocketBase: Saving auth data to secure storage...');
      
      if (_pb.authStore.token.isEmpty) {
        debugPrint('PocketBase: No token to save');
        return;
      }
      
      // Save the token
      await _storage.write(
        key: 'pb_auth_token',
        value: _pb.authStore.token,
      );
      
      // Save the auth data (using token for now)
      await _storage.write(
        key: 'pb_auth',
        value: _pb.authStore.token,
      );
      
      // Store model data if available
      if (_pb.authStore.model != null) {
        try {
          final recordModel = _pb.authStore.model as RecordModel;
          await _storage.write(
            key: 'pb_auth_model',
            value: jsonEncode(recordModel.toJson()),
          );
          debugPrint('PocketBase: Auth data saved successfully - Token: ${_pb.authStore.token.substring(0, 10)}...');
        } catch (e) {
          debugPrint('PocketBase: Error encoding auth model: $e');
          // Save without model if encoding fails
          debugPrint('PocketBase: Auth token saved without model data');
        }
      } else {
        debugPrint('PocketBase: Auth token saved without model data');
      }
    } catch (e) {
      debugPrint('PocketBase: Error saving auth data: $e');
    }
  }
  
  /// Clear stored auth data
  Future<void> _clearStoredAuth() async {
    await _storage.delete(key: 'pb_auth');
    await _storage.delete(key: 'pb_auth_token');
    await _storage.delete(key: 'pb_auth_model');
  }
  
  /// Set remember me preference
  Future<void> setRememberMe(bool value) async {
    _shouldRemember = value;
    await _storage.write(key: 'remember_me', value: value.toString());
    
    // If we're turning off remember me, clear stored auth
    if (!value) {
      await _clearStoredAuth();
    } else if (_pb.authStore.isValid) {
      // If turning on remember me and already logged in, save auth
      await _saveAuthToStorage();
    }
  }
  
  /// Retry auth refresh if we have stored credentials but auth failed during init
  Future<bool> retryAuthRefresh() async {
    try {
      if (_pb.authStore.isValid && _pb.baseUrl.isNotEmpty) {
        debugPrint('PocketBase: Retrying auth refresh...');
        await _pb.collection('users').authRefresh();
        debugPrint('PocketBase: Auth refresh retry successful');
        return true;
      }
    } catch (e) {
      debugPrint('PocketBase: Auth refresh retry failed: $e');
      // Clear auth if refresh definitely fails
      if (!e.toString().contains('Connection') && 
          !e.toString().contains('SocketException') &&
          !e.toString().contains('NetworkException')) {
        _pb.authStore.clear();
        await _clearStoredAuth();
      }
    }
    return false;
  }
  
  /// Get current remember me preference
  Future<bool> getRememberMe() async {
    final value = await _storage.read(key: 'remember_me');
    return value == 'true';
  }
  
  
  /// Check if user is authenticated
  bool get isAuthenticated => _pb.authStore.isValid;
  
  /// Get current user info
  RecordModel? get currentUser => _pb.authStore.model;

  /// Get the PocketBase instance
  PocketBase get pb => _pb;
  
  /// Login with email and password
  Future<RecordModel> login(String email, String password, {bool rememberMe = false}) async {
    // Set remember me preference before logging in
    await setRememberMe(rememberMe);
    
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
    await _clearStoredAuth();
    _shouldRemember = false;
  }

  Future<void> initialize() async {
    if (!_isInitialized) {
      debugPrint('PocketBase: Starting initialization...');
      
      // Use emulator URL directly
      final url = await determinePocketBaseUrl();
      
      debugPrint('PocketBase: Setting base URL to: $url');
      // Set the base URL BEFORE any auth operations
      _pb.baseUrl = url;
      
      _isInitialized = true;
      
      // Now initialize auth with the correct URL
      debugPrint('PocketBase: Initializing auth with correct URL...');
      await _initAuth();
    }
  }

  // Test and determine the best PocketBase URL
  Future<String> determinePocketBaseUrl() async {
    debugPrint("PocketBase: Determining URL for emulator...");
    
    // Get possible URLs from AppConfig (prioritizes emulator URLs)
    final List<String> possibleUrls = List.from(AppConfig.possibleUrls);
    
    for (final url in possibleUrls) {
      try {
        // Quick health check
        final response = await http.get(
          Uri.parse('$url/api/health'),
          headers: AppConfig.getHeadersForUrl(url),
        ).timeout(
          AppConfig.connectionTimeout,
          onTimeout: () => http.Response('Timeout', 408),
        );
        
        if (response.statusCode == 200) {
          debugPrint("PocketBase: Connected to $url");
          return url;
        }
      } catch (e) {
        // Silently continue to next URL
      }
    }
    
    // If all attempts fail, return default emulator URL
    debugPrint("PocketBase: Using default emulator URL");
    return AppConfig.defaultUrl;
  }


}

// Global instance for convenience
final pocketbaseService = PocketBaseService();
