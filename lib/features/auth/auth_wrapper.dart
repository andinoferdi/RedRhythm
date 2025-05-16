import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../routes.dart';
import 'auth_controller.dart';
import 'auth_state.dart';

/// Widget that manages redirection based on auth state
class AuthWrapper extends ConsumerWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authControllerProvider);

    // Show loading indicator when checking auth status
    if (authState.status == AuthStatus.initial || 
        authState.status == AuthStatus.loading) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // If user is authenticated, navigate to home screen
    if (authState.status == AuthStatus.authenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacementNamed(AppRoutes.home);
      });
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    // If user is not authenticated, navigate to auth options screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Navigator.of(context).pushReplacementNamed(AppRoutes.authOptions);
    });
    return const Scaffold(
      body: Center(
        child: CircularProgressIndicator(),
      ),
    );
  }
} 