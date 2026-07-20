import 'package:device_preview/device_preview.dart';
import 'package:flutter/material.dart';

import 'core/constants/app_strings.dart';
import 'core/routes/app_routes.dart';
import 'core/routes/route_generator.dart';
import 'core/theme/app_theme.dart';

class PantryPalApp extends StatelessWidget {
  const PantryPalApp({this.enableDevicePreview = false, super.key});

  final bool enableDevicePreview;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppStrings.appName,
      debugShowCheckedModeBanner: false,

      locale: enableDevicePreview ? DevicePreview.locale(context) : null,

      builder: enableDevicePreview ? DevicePreview.appBuilder : null,

      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: ThemeMode.light,

      initialRoute: AppRoutes.splash,
      onGenerateRoute: RouteGenerator.generateRoute,
    );
  }
}
