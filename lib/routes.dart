import 'package:flutter/material.dart';
import 'screens/splash_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/auth_options_screen.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/home_screen.dart';
import 'screens/explore_screen.dart';
import 'screens/library_screen.dart';
import 'screens/stats_screen.dart';

class AppRoutes {
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String authOptions = '/auth-options';
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';
  static const String explore = '/explore';
  static const String library = '/library';
  static const String stats = '/stats';

  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return FadePageRoute(
          builder: (_) => const SplashScreen(),
          settings: settings,
        );
      case onboarding:
        return FadePageRoute(
          builder: (_) => const OnboardingScreen(),
          settings: settings,
        );
      case authOptions:
        return FadePageRoute(
          builder: (_) => const AuthOptionsScreen(),
          settings: settings,
        );
      case login:
        return FadePageRoute(
          builder: (_) => const LoginScreen(),
          settings: settings,
        );
      case register:
        return FadePageRoute(
          builder: (_) => const RegisterScreen(),
          settings: settings,
        );
      case home:
        return FadePageRoute(
          builder: (_) => const HomeScreen(),
          settings: settings,
        );
      case explore:
        return FadePageRoute(
          builder: (_) => const ExploreScreen(),
          settings: settings,
        );
      case library:
        return FadePageRoute(
          builder: (_) => const LibraryScreen(),
          settings: settings,
        );
      case stats:
        return FadePageRoute(
          builder: (_) => const StatsScreen(),
          settings: settings,
        );
      default:
        return FadePageRoute(
          builder: (_) => const SplashScreen(),
          settings: settings,
        );
    }
  }

  static Map<String, WidgetBuilder> get routes => {
        splash: (context) => const SplashScreen(),
        onboarding: (context) => const OnboardingScreen(),
        authOptions: (context) => const AuthOptionsScreen(),
        login: (context) => const LoginScreen(),
        register: (context) => const RegisterScreen(),
        home: (context) => const HomeScreen(),
        explore: (context) => const ExploreScreen(),
        library: (context) => const LibraryScreen(),
        stats: (context) => const StatsScreen(),
      };
}

class FadePageRoute<T> extends PageRoute<T> {
  FadePageRoute({
    required this.builder,
    required RouteSettings settings,
    this.duration = const Duration(milliseconds: 300),
  }) : super(settings: settings, fullscreenDialog: false);

  final WidgetBuilder builder;
  final Duration duration;

  @override
  bool get opaque => false;

  @override
  bool get barrierDismissible => false;

  @override
  Color? get barrierColor => null;

  @override
  String? get barrierLabel => null;

  @override
  bool get maintainState => true;

  @override
  Duration get transitionDuration => duration;

  @override
  Widget buildPage(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
  ) {
    return builder(context);
  }

  @override
  Widget buildTransitions(
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    return FadeTransition(
      opacity: animation,
      child: Container(
        color: Colors.black,
        child: child,
      ),
    );
  }
}
