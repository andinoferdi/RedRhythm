import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:palette_generator/palette_generator.dart';

class ColorExtractor {
  static final Map<String, DominantColors> _colorCache = {};
  
  /// Extract dominant colors from image URL
  static Future<DominantColors> extractColorsFromUrl(String imageUrl) async {
    // Check cache first
    if (_colorCache.containsKey(imageUrl)) {
      return _colorCache[imageUrl]!;
    }
    
    try {
      // Download image
      final response = await http.get(Uri.parse(imageUrl));
      if (response.statusCode != 200) {
        return getDefaultColors();
      }
      
      // Create image from bytes
      final Uint8List bytes = response.bodyBytes;
      final ui.Codec codec = await ui.instantiateImageCodec(bytes);
      final ui.FrameInfo frameInfo = await codec.getNextFrame();
      final ui.Image image = frameInfo.image;
      
      // Generate palette
      final PaletteGenerator paletteGenerator = await PaletteGenerator.fromImage(
        image,
        maximumColorCount: 20,
      );
      
      // Extract colors
      final dominantColors = _extractDominantColors(paletteGenerator);
      
      // Cache the result
      _colorCache[imageUrl] = dominantColors;
      
      return dominantColors;
    } catch (e) {
      debugPrint('Error extracting colors from image: $e');
      return getDefaultColors();
    }
  }
  
  /// Extract dominant colors from PaletteGenerator
  static DominantColors _extractDominantColors(PaletteGenerator palette) {
    // Primary color (most dominant)
    Color primary = palette.dominantColor?.color ?? 
                   palette.vibrantColor?.color ?? 
                   palette.darkVibrantColor?.color ?? 
                   const Color(0xFFE53E3E);
    
    // Secondary color (complementary or muted)
    Color secondary = palette.mutedColor?.color ?? 
                     palette.lightVibrantColor?.color ?? 
                     primary.withValues(alpha: 0.7);
    
    // Background colors
    Color backgroundStart = palette.darkMutedColor?.color ?? 
                           primary.withValues(alpha: 0.8);
    Color backgroundEnd = palette.darkVibrantColor?.color ?? 
                         primary.withValues(alpha: 0.3);
    
    // Text colors
    Color textPrimary = getContrastingTextColor(primary);
    Color textSecondary = textPrimary.withValues(alpha: 0.7);
    
    // Accent color for highlights
    Color accent = palette.lightVibrantColor?.color ?? 
                  palette.vibrantColor?.color ?? 
                  primary.withValues(alpha: 0.9);
    
    return DominantColors(
      primary: primary,
      secondary: secondary,
      backgroundStart: backgroundStart,
      backgroundEnd: backgroundEnd,
      textPrimary: textPrimary,
      textSecondary: textSecondary,
      accent: accent,
    );
  }
  
  /// Get contrasting text color (white or black) based on background
  static Color getContrastingTextColor(Color backgroundColor) {
    // Calculate luminance
    final luminance = backgroundColor.computeLuminance();
    
    // Return white for dark backgrounds, black for light backgrounds
    return luminance > 0.5 ? Colors.black87 : Colors.white;
  }
  
  /// Get default colors when extraction fails
  static DominantColors getDefaultColors() {
    return const DominantColors(
      primary: Color(0xFFE53E3E),
      secondary: Color(0xFFD53F8C),
      backgroundStart: Color(0xFF2D1B69),
      backgroundEnd: Color(0xFF1A1A1A),
      textPrimary: Colors.white,
      textSecondary: Color(0xFFB3B3B3),
      accent: Color(0xFFFF6B6B),
    );
  }
  
  /// Clear color cache
  static void clearCache() {
    _colorCache.clear();
  }
  
  /// Clear specific color from cache
  static void clearColorFromCache(String imageUrl) {
    _colorCache.remove(imageUrl);
  }
}

/// Data class to hold extracted dominant colors
class DominantColors {
  final Color primary;
  final Color secondary;
  final Color backgroundStart;
  final Color backgroundEnd;
  final Color textPrimary;
  final Color textSecondary;
  final Color accent;
  
  const DominantColors({
    required this.primary,
    required this.secondary,
    required this.backgroundStart,
    required this.backgroundEnd,
    required this.textPrimary,
    required this.textSecondary,
    required this.accent,
  });
  
  /// Create gradient for backgrounds
  LinearGradient get backgroundGradient => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [backgroundStart, backgroundEnd],
  );
  
  /// Create gradient for cards/containers
  LinearGradient get cardGradient => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      primary.withValues(alpha: 0.8),
      secondary.withValues(alpha: 0.6),
      primary.withValues(alpha: 0.4),
    ],
  );
  
  /// Create gradient for lyrics container
  LinearGradient get lyricsGradient => LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, secondary, primary.withValues(alpha: 0.8)],
  );
  
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DominantColors &&
          runtimeType == other.runtimeType &&
          primary == other.primary &&
          secondary == other.secondary &&
          backgroundStart == other.backgroundStart &&
          backgroundEnd == other.backgroundEnd &&
          textPrimary == other.textPrimary &&
          textSecondary == other.textSecondary &&
          accent == other.accent;

  @override
  int get hashCode =>
      primary.hashCode ^
      secondary.hashCode ^
      backgroundStart.hashCode ^
      backgroundEnd.hashCode ^
      textPrimary.hashCode ^
      textSecondary.hashCode ^
      accent.hashCode;
} 