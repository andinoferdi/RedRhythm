

class AppConfig {
  // Development URLs for emulator only
  static const String androidEmulatorUrl = 'http://10.0.2.2:8090';
  static const String iOSSimulatorUrl = 'http://127.0.0.1:8090';
  static const String localhostUrl = 'http://localhost:8090';
  
  // App information
  static const String appName = 'RedRhythm';
  static const String appVersion = '1.0.0';
  
  // Development settings
  static const Duration connectionTimeout = Duration(seconds: 5);
  static const Duration shortTimeout = Duration(seconds: 2);
  
  // Get all possible URLs in priority order (localhost first)
  static List<String> get possibleUrls => [
    iOSSimulatorUrl,     // Primary for localhost (127.0.0.1)
    androidEmulatorUrl,  // For Android emulator
    localhostUrl,        // Fallback
  ];
  
  // Get default URL (localhost)
  static String get defaultUrl => iOSSimulatorUrl;
  
  // Get headers for URL
  static Map<String, String> getHeadersForUrl(String url) {
    return {
      'Accept': 'application/json',
      'Origin': 'http://localhost',
    };
  }
}
