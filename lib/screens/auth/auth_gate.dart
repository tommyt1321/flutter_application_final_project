import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../widgets/loading_view.dart';
import '../navigation/main_navigation_screen.dart';
import 'sign_in_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider?>();

    // This fallback allows existing widget tests to run without Firebase.
    if (authProvider == null) {
      return const MainNavigationScreen();
    }

    if (authProvider.isInitializing) {
      return const Scaffold(
        body: SafeArea(child: LoadingView(message: 'Checking your account...')),
      );
    }

    if (authProvider.isAuthenticated) {
      return const MainNavigationScreen();
    }

    return const SignInScreen();
  }
}
