import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:get_it/get_it.dart';
import 'package:audio_session/audio_session.dart';
import 'routes/app_router.dart';
import 'services/pocketbase_service.dart';
import 'core/di/service_locator.dart';
import 'controllers/auth_controller.dart';
import 'utils/theme.dart';
import 'dart:async';
import 'dart:ui' as ui;

// Global navigator key for accessing the navigator from anywhere
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

// Global app router instance using the navigator key
final appRouter = AppRouter(navigatorKey: navigatorKey);

void main() async {
  // Handle async errors that are not caught by Flutter
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    
    // Initialize audio session for better audio focus handling
    try {
      final session = await AudioSession.instance;
      await session.configure(const AudioSessionConfiguration(
        avAudioSessionCategory: AVAudioSessionCategory.playback,
        avAudioSessionCategoryOptions: AVAudioSessionCategoryOptions.mixWithOthers,
        avAudioSessionMode: AVAudioSessionMode.defaultMode,
        avAudioSessionRouteSharingPolicy: AVAudioSessionRouteSharingPolicy.defaultPolicy,
        avAudioSessionSetActiveOptions: AVAudioSessionSetActiveOptions.none,
        androidAudioAttributes: AndroidAudioAttributes(
          contentType: AndroidAudioContentType.music,
          flags: AndroidAudioFlags.audibilityEnforced,
          usage: AndroidAudioUsage.media,
        ),
        androidAudioFocusGainType: AndroidAudioFocusGainType.gain,
        androidWillPauseWhenDucked: false,
      ));
      debugPrint('✅ Audio session configured successfully');
    } catch (e) {
      debugPrint('⚠️ Error configuring audio session: $e');
    }
    
    // Set up global error handling to prevent crashes
    FlutterError.onError = (FlutterErrorDetails details) {
      FlutterError.dumpErrorToConsole(details);
      // Log error but don't crash the app
      debugPrint('Flutter Error: ${details.exception}');
      debugPrint('Stack trace: ${details.stack}');
    };

    // Handle errors outside of Flutter framework
    ui.PlatformDispatcher.instance.onError = (error, stack) {
      debugPrint('Platform Error: $error');
      debugPrint('Stack trace: $stack');
      return true; // Indicate that the error was handled
    };
    
    // Setup dependency injection
    await setupServiceLocator();
    
    // Initialize PocketBase connection (this will also restore saved auth)
    await GetIt.I<PocketBaseService>().initialize();
    
    // Auto-update song durations on app startup (optional)
    // _autoUpdateDurationsOnStartup();
    
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
  }, (error, stack) {
    // Handle any async errors that escape the app
    debugPrint('Async Error: $error');
    debugPrint('Stack trace: $stack');
  });
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    super.didChangeAppLifecycleState(state);
    
    switch (state) {
      case AppLifecycleState.resumed:
        // App kembali aktif dari background
        _checkAuthOnResume();
        break;
      case AppLifecycleState.paused:
        // App masuk ke background
        break;
      case AppLifecycleState.inactive:
        // App inactive (misalnya ada notifikasi masuk)
        break;
      case AppLifecycleState.detached:
        // App akan ditutup
        break;
      case AppLifecycleState.hidden:
        // App tersembunyi
        break;
    }
  }

  void _checkAuthOnResume() async {
    try {
      // Re-check authentication status when app resumes
      final authController = ref.read(authControllerProvider.notifier);
      await authController.reinitializeAuth();
    } catch (e) {
      // Silently handle auth reinitialization errors
    }
  }

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
      theme: AppTheme.theme,
    );
  }
}



