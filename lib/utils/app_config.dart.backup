

class AppConfig {
  // Development URLs for different environments
  static const String androidEmulatorUrl = 'http://10.0.2.2:8090';
  static const String iOSSimulatorUrl = 'http://127.0.0.1:8090';
  static const String localhostUrl = 'http://localhost:8090';
  
  // ========================================
  // PHYSICAL DEVICE CONFIGURATION
  // ========================================
  // Ganti IP address ini dengan IP laptop Anda di jaringan lokal
  // Jalankan script start_server.bat atau start_server.ps1 untuk melihat IP yang benar
  // Contoh: '192.168.1.100:8090', '192.168.43.1:8090', '10.0.0.5:8090'
  static const String physicalDeviceUrl = 'http://192.168.1.8:8090';
  
  // PRODUCTION URL (jika ada server production)
  static const String productionUrl = 'https://your-production-server.com';
  
  // App information
  static const String appName = 'RedRhythm';
  static const String appVersion = '1.0.0';
  
  // Development settings
  static const Duration connectionTimeout = Duration(seconds: 10);
  static const Duration shortTimeout = Duration(seconds: 5);
  
  // Environment detection
  static bool get isPhysicalDevice {
    // Simple detection - bisa di improve dengan platform detection
    return !isRunningOnEmulator;
  }
  
  static bool get isRunningOnEmulator {
    // Detect if running on emulator/simulator
    // This is a simple check, real implementation might need platform-specific code
    return physicalDeviceUrl.contains('10.0.2.2') || 
           physicalDeviceUrl.contains('127.0.0.1') ||
           physicalDeviceUrl.contains('localhost');
  }
  
  // Get all possible URLs in priority order
  static List<String> get possibleUrls => [
    physicalDeviceUrl,   // Primary for physical devices
    androidEmulatorUrl,  // Android emulator (10.0.2.2)
    iOSSimulatorUrl,     // iOS simulator (127.0.0.1)
    localhostUrl,        // Fallback
  ];
  
  // Get default URL based on environment
  static String get defaultUrl {
    // Prioritize physical device URL for better real device experience
    return physicalDeviceUrl;
  }
  
  // Get headers for URL
  static Map<String, String> getHeadersForUrl(String url) {
    return {
      'Accept': 'application/json',
      'Origin': 'http://localhost',
    };
  }
}



