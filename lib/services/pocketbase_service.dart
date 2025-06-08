import 'package:flutter/foundation.dart';
import 'package:pocketbase/pocketbase.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:io' show Platform;
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math' show min;
import 'dart:io';

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
    // Initialize with a default URL, will be updated when determinePocketBaseUrl is called
    _pb = PocketBase('http://10.0.2.2:8090');
    _initAuth();
  }
  
  /// Initialize authentication from secure storage
  Future<void> _initAuth() async {
    try {
      print('PocketBase: Initializing auth from storage...');
      // Check if we should remember the user
      final rememberStr = await _storage.read(key: 'remember_me');
      _shouldRemember = rememberStr == 'true';
      print('PocketBase: Remember me preference: $_shouldRemember');
      
      // If we shouldn't remember, don't load any auth data
      if (!_shouldRemember) {
        print('PocketBase: Remember me disabled, clearing stored auth');
        await _storage.delete(key: 'pb_auth');
        await _storage.delete(key: 'pb_auth_token');
        await _storage.delete(key: 'pb_auth_model');
        return;
      }
      
      // Try to load the auth store data from secure storage
      final authJson = await _storage.read(key: 'pb_auth');
      final authToken = await _storage.read(key: 'pb_auth_token');
      print('PocketBase: Stored auth token found: ${authToken != null}');
      
      if (authJson != null && authToken != null) {
        print('PocketBase: Restoring auth from storage...');
        // If we have stored auth data, restore it
        try {
          // Try to parse the stored model data
          final modelJson = await _storage.read(key: 'pb_auth_model');
          dynamic modelData;
          if (modelJson != null) {
            modelData = jsonDecode(modelJson);
          }
          
          _pb.authStore.save(authToken, modelData);
          print('PocketBase: Auth restored successfully - Token: ${authToken.substring(0, 10)}...');
        } catch (e) {
          print('PocketBase: Error restoring auth: $e');
          // If restore fails, clear the stored data
          await _clearStoredAuth();
          return;
        }
        
        // Verify the token is still valid
        if (_pb.authStore.isValid) {
          print('PocketBase: Auth token appears valid, attempting refresh...');
          // Try to refresh the auth if possible
          try {
            await _pb.collection('users').authRefresh();
            print('PocketBase: Auth token refreshed successfully');
          } catch (e) {
            print('PocketBase: Auth refresh failed: $e');
            // Clear the auth store if the refresh failed
            _pb.authStore.clear();
            await _clearStoredAuth();
          }
        } else {
          print('PocketBase: Auth token invalid, clearing stored auth');
          // Clear the auth store if the token is invalid
          _pb.authStore.clear();
          await _clearStoredAuth();
        }
      } else {
        print('PocketBase: No stored auth data found');
      }
    } catch (e) {
      print('PocketBase: Error initializing auth: $e');
      // Clear auth on any error
      _pb.authStore.clear();
      await _clearStoredAuth();
    }
    
    // Subscribe to auth changes to persist the state
    _pb.authStore.onChange.listen((e) async {
      if (_pb.authStore.isValid && _shouldRemember) {
        print('PocketBase: Auth changed, saving to storage...');
        // Only save if remember me is enabled
        await _saveAuthToStorage();
      } else if (!_pb.authStore.isValid) {
        print('PocketBase: Auth cleared, removing from storage...');
        // Always clear auth data when logging out
        await _clearStoredAuth();
      }
    });
  }
  
  /// Save auth data to secure storage
  Future<void> _saveAuthToStorage() async {
    try {
      print('PocketBase: Saving auth data to secure storage...');
      
      if (_pb.authStore.token.isEmpty) {
        print('PocketBase: No token to save');
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
          print('PocketBase: Auth data saved successfully - Token: ${_pb.authStore.token.substring(0, 10)}...');
        } catch (e) {
          print('PocketBase: Error encoding auth model: $e');
          // Save without model if encoding fails
          print('PocketBase: Auth token saved without model data');
        }
      } else {
        print('PocketBase: Auth token saved without model data');
      }
    } catch (e) {
      print('PocketBase: Error saving auth data: $e');
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
      final url = await determinePocketBaseUrl();
      // Store current auth state before changing URL
      final wasAuthenticated = _pb.authStore.isValid;
      final currentToken = _pb.authStore.token;
      final currentModel = _pb.authStore.model;
      
      // Update the base URL
      _pb.baseUrl = url;
      
      // Restore auth state if it was valid
      if (wasAuthenticated && currentToken.isNotEmpty) {
        print('PocketBase: Restoring auth state after URL change');
        _pb.authStore.save(currentToken, currentModel);
      }
      
      _isInitialized = true;
      // Only initialize auth if we don't have valid auth already
      if (!_pb.authStore.isValid) {
        await _initAuth();
      }
    }
  }

  // Test and determine the best PocketBase URL
  Future<String> determinePocketBaseUrl() async {
    print("Determining PocketBase URL...");
    
    // Get the computer's IP address on the local network
    const String localComputerIP = '10.11.0.69'; // Your computer's actual IP address
    
    final List<String> possibleUrls = [];
    
    if (Platform.isAndroid) {
      if (!kIsWeb) {
        // For physical Android devices, try the local network IP first
        possibleUrls.add('http://$localComputerIP:8090');
        // For Android emulator
        possibleUrls.add('http://10.0.2.2:8090');
      }
    } else if (Platform.isIOS) {
      if (!kIsWeb) {
        // For physical iOS devices, try the local network IP first
        possibleUrls.add('http://$localComputerIP:8090');
        // For iOS simulator
        possibleUrls.add('http://127.0.0.1:8090');
      }
    }
    
    // Add localhost as fallback
    possibleUrls.add('http://localhost:8090');
    
    for (final url in possibleUrls) {
      print("Trying URL: $url");
      try {
        // First try a basic HEAD request
        try {
          print("Attempting HEAD request to $url");
          final headResponse = await http.head(Uri.parse(url)).timeout(
            const Duration(seconds: 2),
            onTimeout: () {
              print("HEAD request timeout for $url");
              return http.Response('Timeout', 408);
            },
          );
          print("HEAD request status: ${headResponse.statusCode}");
        } catch (e) {
          print("HEAD request failed: $e");
        }
        
        // Then try the health check
        print("Checking connection to $url/api/health");
        final response = await http.get(
          Uri.parse('$url/api/health'),
          headers: {
            'Accept': 'application/json',
            'Origin': 'http://localhost',
          },
        ).timeout(
          const Duration(seconds: 5),
          onTimeout: () {
            print("Health check timeout after 5 seconds");
            return http.Response('Timeout', 408);
          },
        );
        
        print("Response status: ${response.statusCode}");
        print("Response headers: ${response.headers}");
        
        if (response.statusCode < 400) {
          print("Successfully connected to $url");
          print("Response body: ${response.body}");
          return url;
        } else {
          print("Failed with status ${response.statusCode}");
          if (response.body.isNotEmpty) {
            print("Error body: ${response.body}");
          }
        }
      } catch (e) {
        print("Connection error: $e");
        if (e is SocketException) {
          print("Socket details - Address: ${e.address}, Port: ${e.port}");
        }
      }
    }
    
    // If all attempts fail, return the most likely URL based on platform
    print("All URLs failed, using default for platform");
    if (Platform.isAndroid) {
      return 'http://$localComputerIP:8090'; // Return local network IP for physical devices
    } else if (Platform.isIOS) {
      return 'http://127.0.0.1:8090';
    }
    return 'http://localhost:8090';
  }

  // Helper function to check if host is reachable
  Future<bool> isHostReachable(String url) async {
    try {
      print("Memeriksa koneksi ke $url");
      final response = await http.get(Uri.parse(url)).timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          print("Timeout saat menghubungi $url");
          return http.Response('Timeout', 408);
        },
      );
      final isSuccess = response.statusCode < 400;
      print("Respons dari $url: ${response.statusCode} (${isSuccess ? 'Sukses' : 'Gagal'})");
      if (isSuccess) {
        print("Respons body: ${response.body.substring(0, min(100, response.body.length))}...");
      }
      return isSuccess;
    } catch (e) {
      print("Error saat menghubungi $url: $e");
      return false;
    }
  }
}

// Global instance for convenience
final pocketbaseService = PocketBaseService(); 