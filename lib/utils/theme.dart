import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'constants.dart';
import 'custom_page_transitions.dart';
import 'typography.dart';
import 'font_usage_guide.dart';

class AppTheme {
  // Private constructor to prevent instantiation
  AppTheme._();

  // Main app theme
  static ThemeData get theme => ThemeData(
        // Base colors
        primaryColor: AppColors.primary,
        scaffoldBackgroundColor: AppColors.background,
        canvasColor: AppColors.background,

        // Color scheme
        colorScheme: const ColorScheme.dark(
          primary: AppColors.primary,
          secondary: AppColors.primary,
          surfaceContainer: AppColors.background,
          surface: Color(0xFF1E1E1E),
          onPrimary: Colors.white,
          onSecondary: Colors.white,
          onSurfaceVariant: Colors.white,
          onSurface: Colors.white,
        ),

        // Typography - menggunakan font Gotham
        fontFamily: 'Gotham',
        textTheme: _textTheme,

        // Component themes
        appBarTheme: _appBarTheme,
        elevatedButtonTheme: _elevatedButtonTheme,
        textButtonTheme: _textButtonTheme,
        inputDecorationTheme: _inputDecorationTheme,
        cardTheme: _cardTheme,
        iconTheme: _iconTheme,
        bottomNavigationBarTheme: _bottomNavBarTheme,

        // Material 3
        useMaterial3: true,

        // Transitions - Use consistent fade+scale transition across all platforms
        pageTransitionsTheme: PageTransitionsTheme(
          builders: {
            TargetPlatform.android: const FadeScalePageTransitionsBuilder(),
            TargetPlatform.iOS: const FadeScalePageTransitionsBuilder(),
            TargetPlatform.windows: const FadeScalePageTransitionsBuilder(),
            TargetPlatform.macOS: const FadeScalePageTransitionsBuilder(),
            TargetPlatform.linux: const FadeScalePageTransitionsBuilder(),
          },
        ),
      );

  // Text theme - Using the new AppTypography system
  static TextTheme get _textTheme => const TextTheme(
        displayLarge: AppTypography.displayLarge,
        displayMedium: AppTypography.displayMedium,
        displaySmall: AppTypography.displaySmall,
        headlineLarge: AppTypography.headlineLarge,
        headlineMedium: AppTypography.headlineMedium,
        headlineSmall: AppTypography.headlineSmall,
        titleLarge: AppTypography.titleLarge,
        titleMedium: AppTypography.titleMedium,
        titleSmall: AppTypography.titleSmall,
        bodyLarge: AppTypography.bodyLarge,
        bodyMedium: AppTypography.bodyMedium,
        bodySmall: AppTypography.bodySmall,
        labelLarge: AppTypography.labelLarge,
        labelMedium: AppTypography.labelMedium,
        labelSmall: AppTypography.labelSmall,
      );

  // AppBar theme
  static AppBarTheme get _appBarTheme => AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: FontUsageGuide.appBarTitle.copyWith(
          fontSize: 20,
          color: Colors.white,
        ),
      );

  // Elevated button theme
  static ElevatedButtonThemeData get _elevatedButtonTheme =>
      ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          minimumSize: const Size(double.infinity, AppConstants.buttonHeight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppConstants.buttonRadius),
          ),
          textStyle: FontUsageGuide.authButtonText.copyWith(
            fontSize: AppConstants.largeFontSize,
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
          elevation: 0,
        ),
      );

  // Text button theme
  static TextButtonThemeData get _textButtonTheme => TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: FontUsageGuide.modalButton.copyWith(
            fontSize: AppConstants.mediumFontSize,
          ),
        ),
      );

  // Input decoration theme
  static InputDecorationTheme get _inputDecorationTheme => InputDecorationTheme(
        filled: true,
        fillColor: AppColors.textField,
        contentPadding: const EdgeInsets.symmetric(
          vertical: 16,
          horizontal: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.textFieldRadius),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.textFieldRadius),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.textFieldRadius),
          borderSide: const BorderSide(color: AppColors.primary, width: 1),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppConstants.textFieldRadius),
          borderSide: const BorderSide(color: AppColors.error, width: 1),
        ),
        hintStyle: FontUsageGuide.searchPlaceholder.copyWith(
          color: AppColors.textDisabled,
        ),
        prefixIconColor: AppColors.textDisabled,
        suffixIconColor: AppColors.textDisabled,
      );

  // Card theme
  static CardTheme get _cardTheme => CardTheme(
        color: AppColors.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.cardRadius),
        ),
        margin: const EdgeInsets.all(0),
      );

  // Icon theme
  static IconThemeData get _iconTheme => const IconThemeData(
        color: Colors.white,
        size: AppConstants.mediumIconSize,
      );

  // Bottom navigation bar theme - dengan font Poppins
  static BottomNavigationBarThemeData get _bottomNavBarTheme =>
      BottomNavigationBarThemeData(
        backgroundColor: AppColors.navBackground,
        selectedItemColor: AppColors.navSelected,
        unselectedItemColor: AppColors.navUnselected, 
        showSelectedLabels: true,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: FontUsageGuide.navigationLabel.copyWith(
          fontSize: 12,
        ),
        unselectedLabelStyle: FontUsageGuide.navigationLabel.copyWith(
          fontSize: 12,
        ),
      );

  // Custom button styles
  static ButtonStyle get primaryButtonStyle => ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, AppConstants.buttonHeight),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.buttonRadius),
        ),
        textStyle: FontUsageGuide.authButtonText.copyWith(
          fontSize: AppConstants.largeFontSize,
        ),
      );

  static ButtonStyle get secondaryButtonStyle => ElevatedButton.styleFrom(
        backgroundColor: AppColors.white,
        foregroundColor: AppColors.black,
        minimumSize: const Size(double.infinity, AppConstants.buttonHeight),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.buttonRadius),
        ),
        textStyle: FontUsageGuide.authButtonText.copyWith(
          fontSize: AppConstants.largeFontSize,
        ),
      );

  static ButtonStyle get outlineButtonStyle => OutlinedButton.styleFrom(
        foregroundColor: AppColors.white,
        side: const BorderSide(color: AppColors.white, width: 1),
        minimumSize: const Size(double.infinity, AppConstants.buttonHeight),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.buttonRadius),
        ),
        textStyle: FontUsageGuide.authButtonText.copyWith(
          fontSize: AppConstants.largeFontSize,
        ),
      );

  // Custom text styles
  static TextStyle get headingStyle => FontUsageGuide.homeSectionHeader.copyWith(
        fontSize: AppConstants.titleFontSize,
        color: AppColors.text,
      );

  static TextStyle get subheadingStyle => FontUsageGuide.listSongTitle.copyWith(
        fontSize: AppConstants.extraLargeFontSize,
        color: AppColors.text,
      );

  static TextStyle get bodyStyle => FontUsageGuide.modalBody.copyWith(
        fontSize: AppConstants.mediumFontSize,
        color: AppColors.text,
      );

  static TextStyle get captionStyle => FontUsageGuide.metadata.copyWith(
        fontSize: AppConstants.smallFontSize,
        color: AppColors.textSecondary,
      );

  static TextStyle get linkStyle => FontUsageGuide.linkText.copyWith(
        fontSize: AppConstants.mediumFontSize,
        color: AppColors.primary,
      );
}



