import 'package:flutter/material.dart';

/// RedRhythm Typography System
/// 
/// Provides consistent, scalable, and accessible typography throughout the app.
/// Based on Material Design 3 principles with music app optimizations.
class AppTypography {
  AppTypography._();

  // Font Families
  static const String _primaryFont = 'Gotham';
  static const String _secondaryFont = 'DM Sans';

  // Base font size and scaling
  static const double _baseSize = 16.0;
  static const double _scaleRatio = 1.25; // Perfect fourth scale

  /// Display styles - For hero sections, splash screens
  static const TextStyle displayLarge = TextStyle(
    fontFamily: _primaryFont,
    fontSize: 40.0, // 2.5x base
    fontWeight: FontWeight.w900, // Black
    height: 1.1, // Tight line height for displays
    letterSpacing: -0.5,
    color: Colors.white,
  );

  static const TextStyle displayMedium = TextStyle(
    fontFamily: _primaryFont,
    fontSize: 32.0, // 2x base
    fontWeight: FontWeight.w700, // Bold
    height: 1.15,
    letterSpacing: -0.3,
    color: Colors.white,
  );

  static const TextStyle displaySmall = TextStyle(
    fontFamily: _primaryFont,
    fontSize: 28.0, // 1.75x base
    fontWeight: FontWeight.w700, // Bold
    height: 1.2,
    letterSpacing: -0.2,
    color: Colors.white,
  );

  /// Headline styles - For screen titles, section headers
  static const TextStyle headlineLarge = TextStyle(
    fontFamily: _primaryFont,
    fontSize: 24.0, // 1.5x base
    fontWeight: FontWeight.w700, // Bold - optimal readability
    height: 1.25,
    letterSpacing: 0.0,
    color: Colors.white,
  );

  static const TextStyle headlineMedium = TextStyle(
    fontFamily: _primaryFont,
    fontSize: 20.0, // 1.25x base
    fontWeight: FontWeight.w700, // Bold - optimal readability
    height: 1.3,
    letterSpacing: 0.0,
    color: Colors.white,
  );

  static const TextStyle headlineSmall = TextStyle(
    fontFamily: _primaryFont,
    fontSize: 18.0, // 1.125x base
    fontWeight: FontWeight.w700, // Bold - consistent readability
    height: 1.35,
    letterSpacing: 0.0,
    color: Colors.white,
  );

  /// Title styles - For cards, list items, modal titles
  static const TextStyle titleLarge = TextStyle(
    fontFamily: _primaryFont,
    fontSize: 18.0,
    fontWeight: FontWeight.w700, // Bold - optimal readability
    height: 1.4,
    letterSpacing: 0.0,
    color: Colors.white,
  );

  static const TextStyle titleMedium = TextStyle(
    fontFamily: _primaryFont,
    fontSize: 16.0, // Base size
    fontWeight: FontWeight.w700, // Bold - optimal readability
    height: 1.4,
    letterSpacing: 0.1,
    color: Colors.white,
  );

  static const TextStyle titleSmall = TextStyle(
    fontFamily: _primaryFont,
    fontSize: 14.0,
    fontWeight: FontWeight.w700, // Bold - consistent readability
    height: 1.4,
    letterSpacing: 0.1,
    color: Colors.white,
  );

  /// Body styles - For main content, descriptions
  static const TextStyle bodyLarge = TextStyle(
    fontFamily: _secondaryFont, // DM Sans for better readability
    fontSize: 16.0, // Base size
    fontWeight: FontWeight.w400, // Regular
    height: 1.5, // Comfortable reading
    letterSpacing: 0.1,
    color: Colors.white,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontFamily: _secondaryFont, // DM Sans for better readability
    fontSize: 14.0,
    fontWeight: FontWeight.w400, // Regular
    height: 1.5,
    letterSpacing: 0.2,
    color: Colors.white,
  );

  static const TextStyle bodySmall = TextStyle(
    fontFamily: _secondaryFont, // DM Sans for better readability
    fontSize: 12.0,
    fontWeight: FontWeight.w400, // Regular
    height: 1.5,
    letterSpacing: 0.3,
    color: Colors.white,
  );

  /// Label styles - For buttons, chips, captions
  static const TextStyle labelLarge = TextStyle(
    fontFamily: _primaryFont,
    fontSize: 16.0,
    fontWeight: FontWeight.w700, // Bold for buttons
    height: 1.2, // Tight for UI elements
    letterSpacing: 0.5,
    color: Colors.white,
  );

  static const TextStyle labelMedium = TextStyle(
    fontFamily: _primaryFont,
    fontSize: 14.0,
    fontWeight: FontWeight.w700, // Bold
    height: 1.3,
    letterSpacing: 0.4,
    color: Colors.white,
  );

  static const TextStyle labelSmall = TextStyle(
    fontFamily: _primaryFont,
    fontSize: 12.0,
    fontWeight: FontWeight.w700, // Bold
    height: 1.3,
    letterSpacing: 0.5,
    color: Colors.white,
  );

  /// Music-specific styles - Optimized for music app content
  
  /// Song title in lists, cards
  static const TextStyle songTitle = TextStyle(
    fontFamily: _primaryFont,
    fontSize: 16.0,
    fontWeight: FontWeight.w700, // Bold - better readability
    height: 1.3,
    letterSpacing: 0.0,
    color: Colors.white,
  );

  /// Artist name, album name
  static const TextStyle artistName = TextStyle(
    fontFamily: _primaryFont, // Gotham for consistency
    fontSize: 14.0,
    fontWeight: FontWeight.w700, // Bold - better readability
    height: 1.4,
    letterSpacing: 0.1,
    color: Color(0xFFB3B3B3), // Slightly muted
  );

  /// Duration, play count, metadata
  static const TextStyle metadata = TextStyle(
    fontFamily: _primaryFont, // Gotham for consistency
    fontSize: 12.0,
    fontWeight: FontWeight.w700, // Bold - better readability
    height: 1.3,
    letterSpacing: 0.2,
    color: Color(0xFF999999), // More muted
  );

  /// Player screen - large song title
  static const TextStyle playerSongTitle = TextStyle(
    fontFamily: _primaryFont,
    fontSize: 24.0,
    fontWeight: FontWeight.w700, // Bold for emphasis
    height: 1.2,
    letterSpacing: -0.1,
    color: Colors.white,
  );

  /// Player screen - artist name
  static const TextStyle playerArtistName = TextStyle(
    fontFamily: _secondaryFont,
    fontSize: 18.0,
    fontWeight: FontWeight.w400, // Regular
    height: 1.3,
    letterSpacing: 0.0,
    color: Color(0xFFB3B3B3),
  );

  /// Section headers (Your Library, Recently Played, etc.)
  static const TextStyle sectionHeader = TextStyle(
    fontFamily: _primaryFont,
    fontSize: 22.0,
    fontWeight: FontWeight.w700, // Bold
    height: 1.25,
    letterSpacing: -0.1,
    color: Colors.white,
  );

  /// Navigation labels
  static const TextStyle navigation = TextStyle(
    fontFamily: _primaryFont,
    fontSize: 12.0,
    fontWeight: FontWeight.w500, // Medium
    height: 1.2,
    letterSpacing: 0.3,
    color: Colors.white,
  );

  /// Error and validation messages
  static const TextStyle error = TextStyle(
    fontFamily: _secondaryFont,
    fontSize: 12.0,
    fontWeight: FontWeight.w500, // Medium for attention
    height: 1.4,
    letterSpacing: 0.2,
    color: Colors.red,
  );

  /// Success messages
  static const TextStyle success = TextStyle(
    fontFamily: _secondaryFont,
    fontSize: 14.0,
    fontWeight: FontWeight.w500, // Medium
    height: 1.4,
    letterSpacing: 0.1,
    color: Colors.green,
  );

  /// Helper methods for dynamic styling

  /// Get responsive font size based on screen width
  static double getResponsiveFontSize(BuildContext context, double baseSize) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth < 360) {
      return baseSize * 0.9; // Smaller screens
    } else if (screenWidth > 400) {
      return baseSize * 1.1; // Larger screens
    }
    return baseSize; // Default
  }

  /// Apply color variation to any TextStyle
  static TextStyle withColor(TextStyle style, Color color) {
    return style.copyWith(color: color);
  }

  /// Apply opacity to any TextStyle
  static TextStyle withOpacity(TextStyle style, double opacity) {
    return style.copyWith(color: style.color?.withValues(alpha: opacity));
  }

  /// Create disabled text style
  static TextStyle disabled(TextStyle style) {
    return style.copyWith(color: style.color?.withValues(alpha: 0.4));
  }

  /// Create selected/active text style (with accent color)
  static TextStyle active(TextStyle style, Color accentColor) {
    return style.copyWith(color: accentColor);
  }
}

/// Extension for easy access to typography styles
extension TypographyExtension on BuildContext {
  AppTypography get typography => throw UnsupportedError('Use AppTypography static methods directly');
} 