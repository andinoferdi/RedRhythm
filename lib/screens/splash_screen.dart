import 'package:flutter/material.dart';
import 'package:auto_route/auto_route.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import '../routes/app_router.dart';
import '../features/auth/auth_controller.dart';

@RoutePage()
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 2), () {
      _checkAuthAndNavigate();
    });
  }
  
  void _checkAuthAndNavigate() {
    final authState = ref.read(authControllerProvider);
    
    // If user is already authenticated, navigate to home
    if (authState.isAuthenticated) {
      context.router.replace(const HomeRoute());
    } else {
      // Otherwise go to onboarding
      context.router.replace(const OnboardingRoute());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              'assets/images/wave_icon.png',
              width: 180,
              height: 180,
            ),
            const SizedBox(height: 30),
            Image.asset(
              'assets/images/red_rhythm_text.png',
              width: 240,
            ),
          ],
        ),
      ),
    );
  }
}
