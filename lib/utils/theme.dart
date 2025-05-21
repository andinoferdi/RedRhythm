import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'constants.dart';

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

        // Typography
        fontFamily: 'Poppins',
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

        // Transitions
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          },
        ),
      );

  // Text theme
  static TextTheme get _textTheme => const TextTheme(
        displayLarge: TextStyle(
          fontSize: 32,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        displayMedium: TextStyle(
          fontSize: 28,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        displaySmall: TextStyle(
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        headlineMedium: TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
        titleLarge: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
        titleMedium: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
        bodyLarge: TextStyle(
          fontSize: 16,
          color: Colors.white,
        ),
        bodyMedium: TextStyle(
          fontSize: 14,
          color: Colors.white,
        ),
        labelLarge: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
      );

  // AppBar theme
  static AppBarTheme get _appBarTheme => const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
        titleTextStyle: TextStyle(
          fontFamily: 'Poppins',
          fontSize: 20,
          fontWeight: FontWeight.bold,
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
          textStyle: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: AppConstants.largeFontSize,
            fontWeight: FontWeight.w600,
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
          elevation: 0,
        ),
      );

  // Text button theme
  static TextButtonThemeData get _textButtonTheme => TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.primary,
          textStyle: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: AppConstants.mediumFontSize,
            fontWeight: FontWeight.bold,
          ),
        ),
      );

  // Input decoration theme
  static InputDecorationTheme get _inputDecorationTheme => InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF1E1E1E),
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
          borderSide: const BorderSide(color: Colors.red, width: 1),
        ),
        hintStyle: TextStyle(
          color: const Color.fromRGBO(255, 255, 255, 0.6),
          fontFamily: 'Poppins',
        ),
        prefixIconColor: const Color.fromRGBO(255, 255, 255, 0.6),
        suffixIconColor: const Color.fromRGBO(255, 255, 255, 0.6),
      );

  // Card theme
  static CardTheme get _cardTheme => CardTheme(
        color: const Color(0xFF1E1E1E),
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

  // Bottom navigation bar theme
  static BottomNavigationBarThemeData get _bottomNavBarTheme =>
      const BottomNavigationBarThemeData(
        backgroundColor: Colors.black,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: Colors.white,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
      );

  // Custom button styles
  static ButtonStyle get primaryButtonStyle => ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        minimumSize: const Size(double.infinity, AppConstants.buttonHeight),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.buttonRadius),
        ),
        textStyle: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: AppConstants.largeFontSize,
          fontWeight: FontWeight.w600,
        ),
      );

  static ButtonStyle get secondaryButtonStyle => ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        minimumSize: const Size(double.infinity, AppConstants.buttonHeight),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.buttonRadius),
        ),
        textStyle: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: AppConstants.largeFontSize,
          fontWeight: FontWeight.w600,
        ),
      );

  static ButtonStyle get outlineButtonStyle => OutlinedButton.styleFrom(
        foregroundColor: Colors.white,
        side: const BorderSide(color: Colors.white, width: 1),
        minimumSize: const Size(double.infinity, AppConstants.buttonHeight),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppConstants.buttonRadius),
        ),
        textStyle: const TextStyle(
          fontFamily: 'Poppins',
          fontSize: AppConstants.largeFontSize,
          fontWeight: FontWeight.w600,
        ),
      );

  // Custom text styles
  static TextStyle get headingStyle => const TextStyle(
        fontFamily: 'Poppins',
        fontSize: AppConstants.titleFontSize,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      );

  static TextStyle get subheadingStyle => const TextStyle(
        fontFamily: 'Poppins',
        fontSize: AppConstants.extraLargeFontSize,
        fontWeight: FontWeight.w600,
        color: Colors.white,
      );

  static TextStyle get bodyStyle => const TextStyle(
        fontFamily: 'Poppins',
        fontSize: AppConstants.mediumFontSize,
        color: Colors.white,
      );

  static TextStyle get captionStyle => const TextStyle(
        fontFamily: 'Poppins',
        fontSize: AppConstants.smallFontSize,
        color: Color.fromRGBO(255, 255, 255, 0.7),
      );

  static TextStyle get linkStyle => const TextStyle(
        fontFamily: 'Poppins',
        fontSize: AppConstants.mediumFontSize,
        fontWeight: FontWeight.bold,
        color: AppColors.primary,
      );
}
