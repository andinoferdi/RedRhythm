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
      // Check if we should remember the user
      final rememberStr = await _storage.read(key: 'remember_me');
      _shouldRemember = rememberStr == 'true';
      
      // If we shouldn't remember, don't load any auth data
      if (!_shouldRemember) {
        await _storage.delete(key: 'pb_auth');
        await _storage.delete(key: 'pb_auth_token');
        await _storage.delete(key: 'pb_auth_model');
        return;
      }
      
      // Try to load the auth store data from secure storage
      final authJson = await _storage.read(key: 'pb_auth');
      final authToken = await _storage.read(key: 'pb_auth_token');
      
      if (authJson != null && authToken != null) {
        // If we have stored auth data, restore it
        _pb.authStore.save(authToken, authJson);
        
        // Try to load the model as well
        final modelJson = await _storage.read(key: 'pb_auth_model');
        if (modelJson != null) {
          try {
            // Try to parse and set the model
            final modelData = jsonDecode(modelJson);
            if (modelData is Map<String, dynamic>) {
              // We can't directly set the model, we'll rely on auth refresh
              // to populate the model correctly
            }
          } catch (e) {
            debugPrint('Error parsing auth model: $e');
          }
        }
        
        // Verify the token is still valid
        if (_pb.authStore.isValid) {
          // Try to refresh the auth if possible
          try {
            await _pb.collection('users').authRefresh();
          } catch (e) {
            // Clear the auth store if the refresh failed
            _pb.authStore.clear();
            await _clearStoredAuth();
          }
        } else {
          // Clear the auth store if the token is invalid
          _pb.authStore.clear();
          await _clearStoredAuth();
        }
      }
    } catch (e) {
      debugPrint('Error initializing auth: $e');
      // Clear auth on any error
      _pb.authStore.clear();
      await _clearStoredAuth();
    }
    
    // Subscribe to auth changes to persist the state
    _pb.authStore.onChange.listen((e) async {
      if (_pb.authStore.isValid && _shouldRemember) {
        // Only save if remember me is enabled
        await _saveAuthToStorage();
      } else if (!_pb.authStore.isValid) {
        // Always clear auth data when logging out
        await _clearStoredAuth();
      }
    });
  }
  
  /// Save auth data to secure storage
  Future<void> _saveAuthToStorage() async {
    try {
      // Save the token
      await _storage.write(
        key: 'pb_auth_token',
        value: _pb.authStore.token,
      );
      
      // Save the auth data
      await _storage.write(
        key: 'pb_auth',
        value: _pb.authStore.token, // Use token as cookie data
      );
      
      // Store model separately if needed
      if (_pb.authStore.model != null) {
        try {
          final recordModel = _pb.authStore.model as RecordModel;
          await _storage.write(
            key: 'pb_auth_model',
            value: jsonEncode(recordModel.data),
          );
        } catch (e) {
          debugPrint('Error encoding auth model: $e');
        }
      }
    } catch (e) {
      debugPrint('Error saving auth data: $e');
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
  }

  Future<void> initialize() async {
    if (!_isInitialized) {
      final url = await determinePocketBaseUrl();
      // Update the base URL instead of creating a new instance
      _pb.authStore.clear(); // Clear auth before changing URL
      _pb.baseUrl = url;
      _isInitialized = true;
      // Re-initialize auth after changing the URL
      await _initAuth();
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