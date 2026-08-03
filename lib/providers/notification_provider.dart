import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/food_item.dart';

class NotificationProvider extends ChangeNotifier {
  static const double lowStockThreshold = 2;

  final Set<String> _clearedNotifications = {};

  Set<String> get clearedNotifications =>
      Set.unmodifiable(_clearedNotifications);

  Future<void> loadClearedNotifications() async {
    final prefs = await SharedPreferences.getInstance();

    _clearedNotifications.clear();

    _clearedNotifications.addAll(
      prefs.getStringList('cleared_notifications') ?? [],
    );

    notifyListeners();
  }

  Future<void> clearNotifications(List<String> ids) async {
    final prefs = await SharedPreferences.getInstance();

    _clearedNotifications.addAll(ids);

    await prefs.setStringList(
      'cleared_notifications',
      _clearedNotifications.toList(),
    );

    notifyListeners();
  }

  bool isCleared(String id) {
    return _clearedNotifications.contains(id);
  }

  int getNotificationCount(List<FoodItem> items) {
    return items.where((item) {
      final hasNotification =
          _isExpired(item) ||
          _isExpiringSoon(item) ||
          _isLowStock(item);

      return hasNotification &&
          !_clearedNotifications.contains(
            item.id.toString(),
          );
    }).length;
  }

  bool _isExpired(FoodItem item) {
    if (item.statusEnum != FoodItemStatus.available) {
      return false;
    }

    final expiryDate = item.expiryDate;

    if (expiryDate == null) {
      return false;
    }

    final today = _dateOnly(DateTime.now());

    return _dateOnly(expiryDate).isBefore(today);
  }

  bool _isExpiringSoon(FoodItem item) {
    if (item.statusEnum != FoodItemStatus.available) {
      return false;
    }

    final expiryDate = item.expiryDate;

    if (expiryDate == null) {
      return false;
    }

    final today = _dateOnly(DateTime.now());

    final finalDate = today.add(
      const Duration(days: 7),
    );

    final expiry = _dateOnly(expiryDate);

    return !expiry.isBefore(today) &&
        !expiry.isAfter(finalDate);
  }

  bool _isLowStock(FoodItem item) {
    return item.statusEnum == FoodItemStatus.available &&
        item.quantity <= lowStockThreshold;
  }

  DateTime _dateOnly(DateTime date) {
    return DateTime(
      date.year,
      date.month,
      date.day,
    );
  }
}