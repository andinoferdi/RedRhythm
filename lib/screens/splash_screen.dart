import 'package:flutter/material.dart';
import 'package:auto_route/auto_route.dart';
import 'dart:async';
import '../routes/app_router.dart';

@RoutePage()
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    Timer(const Duration(seconds: 2), () {
      context.router.replace(const OnboardingRoute());
    });
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
