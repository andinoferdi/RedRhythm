import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import 'routes/app_router.dart';
import 'services/pocketbase_service.dart';
import 'core/di/service_locator.dart';

// Global navigator key for accessing the navigator from anywhere
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Setup dependency injection
  await setupServiceLocator();
  
  // Initialize PocketBase connection
  await GetIt.I<PocketBaseService>().initialize();
  
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
    final router = appRouter;
    
    return MaterialApp.router(
      title: 'RedRhythm',
      debugShowCheckedModeBanner: false,
      routerDelegate: router.delegate(),
      routeInformationParser: router.defaultRouteParser(),
      builder: (context, child) {
        final mediaQuery = MediaQuery.of(context);
        final double scaleFactor = mediaQuery.textScaler.scale(1.0).clamp(0.8, 1.0);
        
        return MediaQuery(
          data: mediaQuery.copyWith(
            textScaler: TextScaler.linear(scaleFactor),
          ),
          child: child!,
        );
      },
      theme: ThemeData(
        primaryColor: const Color(0xFFE71E27),
        colorScheme: ColorScheme.dark(
          primary: const Color(0xFFE71E27),
          secondary: Colors.red.shade400,
          surfaceContainer: Colors.black,
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
            foregroundColor: const MaterialStatePropertyAll(Colors.white),
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
    );
  }
}
