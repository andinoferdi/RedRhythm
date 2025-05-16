import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'routes.dart';
import 'features/auth/auth_wrapper.dart';

// Global navigator key for accessing the navigator from anywhere
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'RedRhythm',
      debugShowCheckedModeBanner: false,
      navigatorKey: navigatorKey,
      builder: (context, child) {
        final mediaQuery = MediaQuery.of(context);
        final constrainedTextScaleFactor = 
            mediaQuery.textScaleFactor.clamp(0.8, 1.0);
        
        return MediaQuery(
          data: mediaQuery.copyWith(
            textScaleFactor: constrainedTextScaleFactor,
          ),
          child: child!,
        );
      },
      theme: ThemeData(
        primaryColor: const Color(0xFFE71E27),
        colorScheme: ColorScheme.dark(
          primary: const Color(0xFFE71E27),
          secondary: Colors.red.shade400,
          background: Colors.black,
          surface: const Color(0xFF121212),
        ),
        fontFamily: 'Poppins',
        useMaterial3: true,
        scaffoldBackgroundColor: Colors.black,
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          },
        ),
        textButtonTheme: TextButtonThemeData(
          style: ButtonStyle(
            foregroundColor: MaterialStateProperty.all(Colors.white),
          ),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFFE71E27),
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
            ),
          ),
        ),
      ),
      home: const AuthWrapper(),
      onGenerateRoute: AppRoutes.onGenerateRoute,
    );
  }
}
