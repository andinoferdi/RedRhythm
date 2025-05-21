// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// AutoRouterGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

part of 'app_router.dart';

abstract class _$AppRouter extends RootStackRouter {
  // ignore: unused_element
  _$AppRouter({super.navigatorKey});

  @override
  final Map<String, PageFactory> pagesMap = {
    AuthOptionsRoute.name: (routeData) {
      return AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const AuthOptionsScreen(),
      );
    },
    AuthWrapperRoute.name: (routeData) {
      return AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const AuthWrapper(),
      );
    },
    ExploreRoute.name: (routeData) {
      return AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const ExploreScreen(),
      );
    },
    HomeRoute.name: (routeData) {
      return AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const HomeScreen(),
      );
    },
    LibraryRoute.name: (routeData) {
      return AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const LibraryScreen(),
      );
    },
    LoginRoute.name: (routeData) {
      return AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const LoginScreen(),
      );
    },
    MusicPlayerRoute.name: (routeData) {
      final args = routeData.argsAs<MusicPlayerRouteArgs>(
          orElse: () => const MusicPlayerRouteArgs());
      return AutoRoutePage<dynamic>(
        routeData: routeData,
        child: MusicPlayerScreen(
          song: args.song,
          key: args.key,
        ),
      );
    },
    OnboardingRoute.name: (routeData) {
      return AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const OnboardingScreen(),
      );
    },
    PlaylistRoute.name: (routeData) {
      return AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const PlaylistScreen(),
      );
    },
    RegisterRoute.name: (routeData) {
      return AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const RegisterScreen(),
      );
    },
    SplashRoute.name: (routeData) {
      return AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const SplashScreen(),
      );
    },
    StatsRoute.name: (routeData) {
      return AutoRoutePage<dynamic>(
        routeData: routeData,
        child: const StatsScreen(),
      );
    },
  };
}

/// generated route for
/// [AuthOptionsScreen]
class AuthOptionsRoute extends PageRouteInfo<void> {
  const AuthOptionsRoute({List<PageRouteInfo>? children})
      : super(
          AuthOptionsRoute.name,
          initialChildren: children,
        );

  static const String name = 'AuthOptionsRoute';

  static const PageInfo<void> page = PageInfo<void>(name);
}

/// generated route for
/// [AuthWrapper]
class AuthWrapperRoute extends PageRouteInfo<void> {
  const AuthWrapperRoute({List<PageRouteInfo>? children})
      : super(
          AuthWrapperRoute.name,
          initialChildren: children,
        );

  static const String name = 'AuthWrapperRoute';

  static const PageInfo<void> page = PageInfo<void>(name);
}

/// generated route for
/// [ExploreScreen]
class ExploreRoute extends PageRouteInfo<void> {
  const ExploreRoute({List<PageRouteInfo>? children})
      : super(
          ExploreRoute.name,
          initialChildren: children,
        );

  static const String name = 'ExploreRoute';

  static const PageInfo<void> page = PageInfo<void>(name);
}

/// generated route for
/// [HomeScreen]
class HomeRoute extends PageRouteInfo<void> {
  const HomeRoute({List<PageRouteInfo>? children})
      : super(
          HomeRoute.name,
          initialChildren: children,
        );

  static const String name = 'HomeRoute';

  static const PageInfo<void> page = PageInfo<void>(name);
}

/// generated route for
/// [LibraryScreen]
class LibraryRoute extends PageRouteInfo<void> {
  const LibraryRoute({List<PageRouteInfo>? children})
      : super(
          LibraryRoute.name,
          initialChildren: children,
        );

  static const String name = 'LibraryRoute';

  static const PageInfo<void> page = PageInfo<void>(name);
}

/// generated route for
/// [LoginScreen]
class LoginRoute extends PageRouteInfo<void> {
  const LoginRoute({List<PageRouteInfo>? children})
      : super(
          LoginRoute.name,
          initialChildren: children,
        );

  static const String name = 'LoginRoute';

  static const PageInfo<void> page = PageInfo<void>(name);
}

/// generated route for
/// [MusicPlayerScreen]
class MusicPlayerRoute extends PageRouteInfo<MusicPlayerRouteArgs> {
  MusicPlayerRoute({
    Song? song,
    Key? key,
    List<PageRouteInfo>? children,
  }) : super(
          MusicPlayerRoute.name,
          args: MusicPlayerRouteArgs(
            song: song,
            key: key,
          ),
          initialChildren: children,
        );

  static const String name = 'MusicPlayerRoute';

  static const PageInfo<MusicPlayerRouteArgs> page =
      PageInfo<MusicPlayerRouteArgs>(name);
}

class MusicPlayerRouteArgs {
  const MusicPlayerRouteArgs({
    this.song,
    this.key,
  });

  final Song? song;

  final Key? key;

  @override
  String toString() {
    return 'MusicPlayerRouteArgs{song: $song, key: $key}';
  }
}

/// generated route for
/// [OnboardingScreen]
class OnboardingRoute extends PageRouteInfo<void> {
  const OnboardingRoute({List<PageRouteInfo>? children})
      : super(
          OnboardingRoute.name,
          initialChildren: children,
        );

  static const String name = 'OnboardingRoute';

  static const PageInfo<void> page = PageInfo<void>(name);
}

/// generated route for
/// [PlaylistScreen]
class PlaylistRoute extends PageRouteInfo<void> {
  const PlaylistRoute({List<PageRouteInfo>? children})
      : super(
          PlaylistRoute.name,
          initialChildren: children,
        );

  static const String name = 'PlaylistRoute';

  static const PageInfo<void> page = PageInfo<void>(name);
}

/// generated route for
/// [RegisterScreen]
class RegisterRoute extends PageRouteInfo<void> {
  const RegisterRoute({List<PageRouteInfo>? children})
      : super(
          RegisterRoute.name,
          initialChildren: children,
        );

  static const String name = 'RegisterRoute';

  static const PageInfo<void> page = PageInfo<void>(name);
}

/// generated route for
/// [SplashScreen]
class SplashRoute extends PageRouteInfo<void> {
  const SplashRoute({List<PageRouteInfo>? children})
      : super(
          SplashRoute.name,
          initialChildren: children,
        );

  static const String name = 'SplashRoute';

  static const PageInfo<void> page = PageInfo<void>(name);
}

/// generated route for
/// [StatsScreen]
class StatsRoute extends PageRouteInfo<void> {
  const StatsRoute({List<PageRouteInfo>? children})
      : super(
          StatsRoute.name,
          initialChildren: children,
        );

  static const String name = 'StatsRoute';

  static const PageInfo<void> page = PageInfo<void>(name);
}
