import 'package:flutter/material.dart';

import '../dashboard/dashboard_screen.dart';
import '../expiry/use_first_screen.dart';
import '../inventory/inventory_screen.dart';
import '../notifications/notifications_screen.dart';
import '../profile/profile_screen.dart';
import '../shopping/shopping_screen.dart';
import '../../widgets/app_bottom_navigation.dart';

class MainNavigationScreen extends StatefulWidget {
  const MainNavigationScreen({super.key});

  @override
  State<MainNavigationScreen> createState() => _MainNavigationScreenState();
}

class _MainNavigationScreenState extends State<MainNavigationScreen> {
  int _selectedIndex = 0;

  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();

    _screens = [
      DashboardScreen(
        onOpenInventory: () {
          _changeScreen(1);
        },
        onOpenUseFirst: () {
          _changeScreen(2);
        },
        onOpenNotifications: _openNotifications,
      ),
      const InventoryScreen(),
      const UseFirstScreen(),
      const ShoppingScreen(),
      const ProfileScreen(),
    ];
  }

  void _changeScreen(int index) {
    if (_selectedIndex == index) {
      return;
    }

    setState(() {
      _selectedIndex = index;
    });
  }

  void _openNotifications() {
    Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) {
          return const NotificationsScreen();
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(index: _selectedIndex, children: _screens),
      bottomNavigationBar: AppBottomNavigation(
        selectedIndex: _selectedIndex,
        onDestinationSelected: _changeScreen,
      ),
    );
  }
}
