import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'constants.dart';

class AppTextStyles {
  // Prevent instantiation
  AppTextStyles._();

  // Display styles - for large headings
  static const TextStyle displayLarge = TextStyle(
    fontFamily: 'Gotham',
    fontSize: AppConstants.titleFontSize,
    fontWeight: FontWeight.w700,
    color: AppColors.text,
  );

  static const TextStyle displayMedium = TextStyle(
    fontFamily: 'Gotham',
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: AppColors.text,
  );

  static const TextStyle displaySmall = TextStyle(
    fontFamily: 'Gotham',
    fontSize: AppConstants.extraLargeFontSize,
    fontWeight: FontWeight.w700,
    color: AppColors.text,
  );

  // Headline styles - for section headings
  static const TextStyle headlineLarge = TextStyle(
    fontFamily: 'Gotham',
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: AppColors.text,
  );

  static const TextStyle headlineMedium = TextStyle(
    fontFamily: 'Gotham',
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: AppColors.text,
  );

  static const TextStyle headlineSmall = TextStyle(
    fontFamily: 'Gotham',
    fontSize: AppConstants.largeFontSize,
    fontWeight: FontWeight.w700,
    color: AppColors.text,
  );

  // Title styles - for card titles and important text
  static const TextStyle titleLarge = TextStyle(
    fontFamily: 'Gotham',
    fontSize: AppConstants.largeFontSize,
    fontWeight: FontWeight.w700,
    color: AppColors.text,
  );

  static const TextStyle titleMedium = TextStyle(
    fontFamily: 'Gotham',
    fontSize: AppConstants.mediumFontSize,
    fontWeight: FontWeight.w700,
    color: AppColors.text,
  );

  static const TextStyle titleSmall = TextStyle(
    fontFamily: 'Gotham',
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: AppColors.text,
  );

  // Body styles - for main content
  static const TextStyle bodyLarge = TextStyle(
    fontFamily: 'Gotham',
    fontSize: AppConstants.mediumFontSize,
    fontWeight: FontWeight.w400,
    color: AppColors.text,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontFamily: 'Gotham',
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.text,
  );

  static const TextStyle bodySmall = TextStyle(
    fontFamily: 'Gotham',
    fontSize: AppConstants.smallFontSize,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );

  // Label styles - for buttons and labels
  static const TextStyle labelLarge = TextStyle(
    fontFamily: 'Gotham',
    fontSize: AppConstants.mediumFontSize,
    fontWeight: FontWeight.w700,
    color: AppColors.text,
  );

  static const TextStyle labelMedium = TextStyle(
    fontFamily: 'Gotham',
    fontSize: 14,
    fontWeight: FontWeight.w700,
    color: AppColors.text,
  );

  static const TextStyle labelSmall = TextStyle(
    fontFamily: 'Gotham',
    fontSize: AppConstants.smallFontSize,
    fontWeight: FontWeight.w700,
    color: AppColors.textSecondary,
  );

  // Special purpose styles
  static const TextStyle button = TextStyle(
    fontFamily: 'Gotham',
    fontSize: AppConstants.largeFontSize,
    fontWeight: FontWeight.w700,
    color: AppColors.textOnPrimary,
  );

  static const TextStyle buttonSecondary = TextStyle(
    fontFamily: 'Gotham',
    fontSize: AppConstants.mediumFontSize,
    fontWeight: FontWeight.w700,
    color: AppColors.primary,
  );

  static const TextStyle caption = TextStyle(
    fontFamily: 'Gotham',
    fontSize: AppConstants.smallFontSize,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );

  static const TextStyle link = TextStyle(
    fontFamily: 'Gotham',
    fontSize: AppConstants.mediumFontSize,
    fontWeight: FontWeight.w700,
    color: AppColors.primary,
    decoration: TextDecoration.underline,
    decorationColor: AppColors.primary,
  );

  static const TextStyle error = TextStyle(
    fontFamily: 'Gotham',
    fontSize: AppConstants.mediumFontSize,
    fontWeight: FontWeight.w400,
    color: AppColors.error,
  );

  static const TextStyle success = TextStyle(
    fontFamily: 'Gotham',
    fontSize: AppConstants.mediumFontSize,
    fontWeight: FontWeight.w400,
    color: AppColors.success,
  );

  // Navigation styles
  static const TextStyle navLabel = TextStyle(
    fontFamily: 'Gotham',
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.navUnselected,
  );

  static const TextStyle navLabelSelected = TextStyle(
    fontFamily: 'Gotham',
    fontSize: 12,
    fontWeight: FontWeight.w700,
    color: AppColors.navSelected,
  );

  // App bar styles
  static const TextStyle appBarTitle = TextStyle(
    fontFamily: 'Gotham',
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: AppColors.text,
  );

  // Input field styles
  static const TextStyle inputText = TextStyle(
    fontFamily: 'Gotham',
    fontSize: AppConstants.mediumFontSize,
    fontWeight: FontWeight.w400,
    color: AppColors.text,
  );

  static const TextStyle inputHint = TextStyle(
    fontFamily: 'Gotham',
    fontSize: AppConstants.mediumFontSize,
    fontWeight: FontWeight.w400,
    color: AppColors.textDisabled,
  );

  static const TextStyle inputLabel = TextStyle(
    fontFamily: 'Gotham',
    fontSize: AppConstants.mediumFontSize,
    fontWeight: FontWeight.w700,
    color: AppColors.text,
  );

  // Helper method to get DM Sans with custom properties
  static TextStyle dmSans({
    double? fontSize,
    FontWeight? fontWeight,
    Color? color,
    double? letterSpacing,
    double? height,
    TextDecoration? decoration,
    Color? decorationColor,
  }) {
    return TextStyle(
      fontFamily: 'Gotham',
      fontSize: fontSize,
      fontWeight: fontWeight,
      color: color,
      letterSpacing: letterSpacing,
      height: height,
      decoration: decoration,
      decorationColor: decorationColor,
    );
  }
}



