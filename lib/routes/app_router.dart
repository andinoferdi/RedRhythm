import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import '../models/song.dart';
import '../screens/splash_screen.dart';
import '../screens/onboarding_screen.dart';
import '../screens/auth_options_screen.dart';
import '../screens/login_screen.dart';
import '../screens/register_screen.dart';
import '../screens/home_screen.dart';
import '../screens/explore_screen.dart';
import '../screens/library/library_screen.dart';
import '../screens/stats_screen.dart';
import '../screens/music_player_screen.dart';
import '../screens/playlist_screen.dart';
import '../features/auth/auth_wrapper.dart';

part 'app_router.gr.dart';

@AutoRouterConfig()
class AppRouter extends _$AppRouter {
  @override
  List<AutoRoute> get routes => [
    AutoRoute(page: SplashRoute.page, initial: true),
    AutoRoute(page: OnboardingRoute.page),
    AutoRoute(page: AuthOptionsRoute.page),
    AutoRoute(page: LoginRoute.page),
    AutoRoute(page: RegisterRoute.page),
    AutoRoute(page: HomeRoute.page),
    AutoRoute(page: ExploreRoute.page),
    AutoRoute(page: LibraryRoute.page),
    AutoRoute(page: StatsRoute.page),
    AutoRoute(page: MusicPlayerRoute.page, fullscreenDialog: true),
    AutoRoute(page: PlaylistRoute.page),
    AutoRoute(page: AuthWrapperRoute.page),
  ];
}

// For convenience, this can be used to access the router from anywhere
final appRouter = AppRouter();

// Constants for named routes
class AppRoutes {
  static const String splash = '/';
  static const String onboarding = '/onboarding';
  static const String authOptions = '/auth-options';
  static const String login = '/login';
  static const String register = '/register';
  static const String home = '/home';
} 