import 'package:flutter/material.dart';
import '../../screens/auth/auth_gate.dart';
import '../../screens/auth/registry_screen.dart';
import '../../screens/storage/manage_storage_locations_screen.dart';
import '../../screens/categories/manage_categories_screen.dart';
import '../../screens/navigation/main_navigation_screen.dart';
import '../../screens/splash/splash_screen.dart';
import '../../screens/profile/appearance_screen.dart';
import 'app_routes.dart';

class RouteGenerator {
  RouteGenerator._();

  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.authGate:
        return MaterialPageRoute<void>(
          builder: (_) => const AuthGate(),
          settings: settings,
        );

      case AppRoutes.register:
        return MaterialPageRoute<void>(
          builder: (_) => const RegisterScreen(),
          settings: settings,
        );
      case AppRoutes.splash:
        return MaterialPageRoute<void>(
          builder: (_) => const SplashScreen(),
          settings: settings,
        );

      case AppRoutes.mainNavigation:
        return MaterialPageRoute<void>(
          builder: (_) => const MainNavigationScreen(),
          settings: settings,
        );

      case AppRoutes.manageCategories:
        return MaterialPageRoute<void>(
          builder: (_) => const ManageCategoriesScreen(),
          settings: settings,
        );

      case AppRoutes.manageStorageLocations:
        return MaterialPageRoute<void>(
          builder: (_) => const ManageStorageLocationsScreen(),
          settings: settings,
        );

      case AppRoutes.appearance:
        return MaterialPageRoute<void>(
          builder: (_) => const AppearanceScreen(),
          settings: settings,
        );

      default:
        return MaterialPageRoute<void>(
          builder: (_) => const _UnknownRouteScreen(),
          settings: settings,
        );
    }
  }
}

class _UnknownRouteScreen extends StatelessWidget {
  const _UnknownRouteScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Page Not Found')),
      body: const Center(child: Text('The requested page does not exist.')),
    );
  }
}
