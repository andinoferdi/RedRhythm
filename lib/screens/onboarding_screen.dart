import 'package:flutter/material.dart';
import 'package:auto_route/auto_route.dart';
import '../routes/app_router.dart';

@RoutePage()
class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE71E27),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    bottom:
                        -10, // Added negative bottom value to push image further down
                    left: 0,
                    right: 0,
                    child: Image.asset(
                      'assets/images/person_with_headphones.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              child: Column(
                children: [
                  RichText(
                    textAlign: TextAlign.center,
                    text: const TextSpan(
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 24,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                      children: [
                        TextSpan(text: 'From the '),
                        TextSpan(
                          text: 'latest',
                          style: TextStyle(color: Color(0xFFE71E27)),
                        ),
                        TextSpan(text: ' to the\n'),
                        TextSpan(
                          text: 'greatest',
                          style: TextStyle(color: Color(0xFFE71E27)),
                        ),
                        TextSpan(text: ' hits, play your\nfavorite tracks on '),
                      ],
                    ),
                  ),
                  Image.asset(
                    'assets/images/red_rhythm_text.png',
                    width: 180,
                  ),
                  const Text(
                    'now!',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 24,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 30),
                  Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 6,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE71E27),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Container(
                          height: 6,
                          decoration: BoxDecoration(
                            color: const Color.fromRGBO(255, 255, 255, 0.4),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () {
                        context.router.replace(const AuthOptionsRoute());
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFFE71E27),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(30),
                        ),
                      ),
                      child: const Text(
                        'Get Started',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
