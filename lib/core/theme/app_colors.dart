import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Primary brand colours
  static const Color primary = Color(0xFF2E7D5B);
  static const Color primaryDark = Color(0xFF1F5A43);
  static const Color primaryLight = Color(0xFFDDF3E8);

  // Supporting colours
  static const Color secondary = Color(0xFFF4A261);
  static const Color accent = Color(0xFFE9C46A);

  // Food status colours
  static const Color fresh = Color(0xFF2E7D32);
  static const Color expiringSoon = Color(0xFFF9A825);
  static const Color urgent = Color(0xFFEF6C00);
  static const Color expired = Color(0xFFC62828);
  static const Color lowStock = Color(0xFF8E24AA);

  // Light theme
  static const Color lightBackground = Color(0xFFF7F9F7);
  static const Color lightSurface = Colors.white;
  static const Color lightTextPrimary = Color(0xFF1E2723);
  static const Color lightTextSecondary = Color(0xFF66736C);
  static const Color lightBorder = Color(0xFFDCE5E0);

  // Dark theme
  static const Color darkBackground = Color(0xFF101613);
  static const Color darkSurface = Color(0xFF1A231F);
  static const Color darkTextPrimary = Color(0xFFF2F6F4);
  static const Color darkTextSecondary = Color(0xFFAEBBB4);
  static const Color darkBorder = Color(0xFF34413B);

  // General
  static const Color error = Color(0xFFB3261E);
  static const Color success = Color(0xFF2E7D32);
  static const Color warning = Color(0xFFF9A825);
}
