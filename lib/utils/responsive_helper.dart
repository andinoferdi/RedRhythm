import 'package:flutter/material.dart';
import 'dart:io';

/// Utility class for responsive design and safe area handling
class ResponsiveHelper {
  ResponsiveHelper._();

  /// Get safe top padding that works consistently across devices
  static double getSafeTopPadding(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final topPadding = mediaQuery.padding.top;
    
    // Ensure minimum padding for devices without notch
    if (topPadding < 20) {
      return 24; // Minimum safe area for older devices
    }
    
    return topPadding;
  }

  /// Get safe bottom padding that works consistently across devices
  static double getSafeBottomPadding(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    final bottomPadding = mediaQuery.padding.bottom;
    
    // Ensure minimum padding for gesture navigation
    if (bottomPadding < 10) {
      return 16; // Minimum safe area for devices without home indicator
    }
    
    return bottomPadding;
  }

  /// Get header height that accommodates all device types
  static double getHeaderHeight(BuildContext context) {
    final safeTop = getSafeTopPadding(context);
    
    // Base header height + safe area
    return safeTop + 60;
  }

  /// Check if device has notch or punch hole
  static bool hasNotchOrPunchHole(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    return mediaQuery.padding.top > 24;
  }

  /// Get minimum touch target size based on platform
  static double getMinTouchTarget() {
    if (Platform.isIOS) {
      return 44.0; // iOS Human Interface Guidelines
    } else {
      return 48.0; // Material Design Guidelines
    }
  }

  /// Get responsive font size based on screen size
  static double getResponsiveFontSize(BuildContext context, double baseSize) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    // Scale font size based on screen width
    if (screenWidth < 360) {
      return baseSize * 0.9; // Smaller screens
    } else if (screenWidth > 400) {
      return baseSize * 1.1; // Larger screens
    }
    
    return baseSize; // Normal screens
  }

  /// Get responsive margin/padding based on screen size
  static double getResponsiveSpacing(BuildContext context, double baseSpacing) {
    final screenWidth = MediaQuery.of(context).size.width;
    
    if (screenWidth < 360) {
      return baseSpacing * 0.8;
    } else if (screenWidth > 400) {
      return baseSpacing * 1.2;
    }
    
    return baseSpacing;
  }

  /// Check if screen is considered small
  static bool isSmallScreen(BuildContext context) {
    return MediaQuery.of(context).size.width < 360;
  }

  /// Check if screen is considered large
  static bool isLargeScreen(BuildContext context) {
    return MediaQuery.of(context).size.width > 400;
  }

  /// Get app bar height with safe area
  static double getAppBarHeight(BuildContext context) {
    return kToolbarHeight + getSafeTopPadding(context);
  }

  /// Build safe container with proper padding for headers
  static Widget buildSafeHeader({
    required BuildContext context,
    required Widget child,
    Color? backgroundColor,
    List<Color>? gradientColors,
    double? height,
  }) {
    final safeTop = getSafeTopPadding(context);
    final effectiveHeight = height ?? 60.0;
    
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        gradient: gradientColors != null
            ? LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: gradientColors,
                stops: const [0.0, 0.7, 1.0],
              )
            : null,
      ),
      child: SafeArea(
        bottom: false,
        child: Container(
          height: effectiveHeight,
          child: child,
        ),
      ),
    );
  }

  /// Build responsive button with proper touch target
  static Widget buildTouchableButton({
    required Widget child,
    required VoidCallback onTap,
    double? width,
    double? height,
    EdgeInsets? margin,
    BorderRadius? borderRadius,
  }) {
    final minSize = getMinTouchTarget();
    
    return Container(
      width: width ?? minSize,
      height: height ?? minSize,
      margin: margin,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: borderRadius ?? BorderRadius.circular(minSize / 2),
          onTap: onTap,
          child: child,
        ),
      ),
    );
  }
} 