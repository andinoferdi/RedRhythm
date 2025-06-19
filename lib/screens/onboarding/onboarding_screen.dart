import 'package:flutter/material.dart';
import 'package:auto_route/auto_route.dart';
import '../../routes/app_router.dart';
import '../../utils/app_colors.dart';
import '../../utils/font_usage_guide.dart';

@RoutePage()
class OnboardingScreen extends StatelessWidget {
  const OnboardingScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.primary,
      body: Column(
        children: [
          Expanded(
            child: SafeArea(
              bottom: false, // Remove bottom safe area to allow black card to extend to bottom
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
          ),
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(24, 24, 24, MediaQuery.of(context).padding.bottom + 24), // Add bottom padding for safe area
            decoration: const BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(30),
                topRight: Radius.circular(30),
              ),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: FontUsageGuide.authWelcomeTitle,
                    children: [
                      const TextSpan(text: 'From the '),
                      TextSpan(
                        text: 'latest',
                        style: FontUsageGuide.authWelcomeTitle.copyWith(color: AppColors.primary),
                      ),
                      const TextSpan(text: ' to the\n'),
                      TextSpan(
                        text: 'greatest',
                        style: FontUsageGuide.authWelcomeTitle.copyWith(color: AppColors.primary),
                      ),
                      const TextSpan(text: ' hits, play your\nfavorite tracks on '),
                    ],
                  ),
                ),
                Image.asset(
                  'assets/images/red_rhythm_text.png',
                  width: 180,
                ),
                Text(
                  'now!',
                  style: FontUsageGuide.authWelcomeTitle,
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
                      backgroundColor: AppColors.primary,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(30),
                      ),
                    ),
                    child: Text(
                      'Get Started',
                      style: FontUsageGuide.authButtonText,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}



