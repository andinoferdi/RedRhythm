import 'package:flutter/material.dart';
import 'package:pocketbase/pocketbase.dart';

/// Utility functions for handling images
class ImageHelpers {
  /// Private constructor to prevent instantiation
  ImageHelpers._();
  
  /// Generate a full avatar URL from a user record
  /// Returns null if no avatar is available
  static String? getAvatarUrl(RecordModel? user, String? baseUrl) {
    if (user == null) return null;
    if (baseUrl == null) return null;
    
    // Check if user has an avatar field with data
    final avatar = user.data['avatar'];
    if (avatar == null || avatar is! String || avatar.isEmpty) return null;
    
    // Check if it's already a full URL
    if (avatar.startsWith('http')) return avatar;
    
    // Format: {baseUrl}/api/files/{collectionId}/{recordId}/{fileName}
    return '$baseUrl/api/files/${user.collectionId}/${user.id}/$avatar';
  }

  /// Validate if a URL is a valid image URL
  static bool isValidImageUrl(String? url) {
    if (url == null || url.trim().isEmpty) return false;
    
    try {
      final uri = Uri.parse(url);
      
      // Check if it's a valid HTTP/HTTPS URL
      if (!uri.hasScheme || (!uri.scheme.startsWith('http'))) {
        return false;
      }
      
      // Check if it has a valid host
      if (!uri.hasAuthority || uri.host.isEmpty) {
        return false;
      }
      
      // Check if path looks like a file path
      if (uri.path.isEmpty || !uri.path.contains('/')) {
        return false;
      }
      
      return true;
    } catch (e) {
      return false;
    }
  }
  
  /// Get a safe image URL, returns empty string if invalid
  static String getSafeImageUrl(String? url) {
    return isValidImageUrl(url) ? url! : '';
  }
}

/// Extension methods for RecordModel
extension RecordModelExtensions on RecordModel {
  /// Get the avatar URL for this user record
  /// Returns null if no avatar is available or baseUrl is null
  String? getAvatarUrl(String? baseUrl) {
    return ImageHelpers.getAvatarUrl(this, baseUrl);
  }
  
  /// Get the user's name from the record
  /// Returns a default value if not found
  String getName([String defaultValue = 'User']) {
    return data['name']?.toString() ?? defaultValue;
  }
  
  /// Get the user's email from the record
  /// Returns a default value if not found
  String getEmail([String defaultValue = '']) {
    return data['email']?.toString() ?? defaultValue;
  }
}
