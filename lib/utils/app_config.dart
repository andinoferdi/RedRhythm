import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';

class AppConfig {
  // Current ngrok URL (will be loaded from config file)
  static String _currentNgrokUrl = '';
  
  // Development URLs
  static const String localComputerIP = '10.11.0.69';
  static const String androidEmulatorUrl = 'http://10.0.2.2:8090';
  static const String iOSSimulatorUrl = 'http://127.0.0.1:8090';
  static const String localhostUrl = 'http://localhost:8090';
  
  // App information
  static const String appName = 'RedRhythm';
  static const String appVersion = '1.0.0';
  
  // Development settings
  static const bool useNgrokAsPrimary = true;
  static const Duration connectionTimeout = Duration(seconds: 5);
  static const Duration shortTimeout = Duration(seconds: 2);
  
  // Get local network URL
  static String get localNetworkUrl => 'http://$localComputerIP:8090';
  
  // Load ngrok URL from config file
  static Future<void> loadNgrokConfig() async {
    try {
      final configString = await rootBundle.loadString('ngrok_config.json');
      final config = jsonDecode(configString);
      _currentNgrokUrl = config['ngrok_url'] ?? localNetworkUrl;
      debugPrint('✅ Loaded ngrok URL from config: $_currentNgrokUrl');
    } catch (e) {
      debugPrint('⚠️ Failed to load ngrok config, falling back to local network: $e');
      _currentNgrokUrl = localNetworkUrl;
    }
  }
  
  // Get current ngrok URL
  static String get ngrokUrl => _currentNgrokUrl;
  
  // Get all possible URLs in priority order
  static List<String> get possibleUrls => [
    if (useNgrokAsPrimary) ngrokUrl,
    localNetworkUrl,
    androidEmulatorUrl,
    iOSSimulatorUrl,
    localhostUrl,
  ];
  
  // Get default URL based on priority
  static String get defaultUrl => useNgrokAsPrimary ? ngrokUrl : localNetworkUrl;
  
  // Check if URL is ngrok
  static bool isNgrokUrl(String url) => url.contains('ngrok-free.app');
  
  // Get headers for URL
  static Map<String, String> getHeadersForUrl(String url) {
    final headers = {
      'Accept': 'application/json',
      'Origin': 'http://localhost',
    };
    
    // Add ngrok specific headers
    if (isNgrokUrl(url)) {
      headers['ngrok-skip-browser-warning'] = 'true';
      headers['User-Agent'] = '$appName Flutter App';
    }
    
    return headers;
  }
} 