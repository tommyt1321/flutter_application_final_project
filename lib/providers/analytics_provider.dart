import 'dart:async';

import 'package:flutter/material.dart';

import '../models/analytics_summary.dart';
import '../models/food_activity.dart';
import '../repositories/analytics_repository.dart';
import '../repositories/food_activity_repository.dart';

enum AnalyticsPeriod { last7Days, last30Days, allTime }

class AnalyticsProvider extends ChangeNotifier {
  AnalyticsProvider(this._analyticsRepository, this._activityRepository);

  final AnalyticsRepository _analyticsRepository;
  final FoodActivityRepository _activityRepository;

  String? _userId;
  AnalyticsSummary? _currentSummary;
  AnalyticsPeriod _selectedPeriod = AnalyticsPeriod.last30Days;
  bool _isLoading = false;
  String? _errorMessage;

  AnalyticsSummary? get currentSummary => _currentSummary;

  AnalyticsPeriod get selectedPeriod => _selectedPeriod;

  bool get isLoading => _isLoading;

  String? get errorMessage => _errorMessage;

  /// Called from a `ChangeNotifierProxyProvider<AuthProvider, AnalyticsProvider>`,
  /// mirroring ShoppingItemProvider/FoodActivityProvider.
  void updateUserId(String? userId) {
    if (_userId == userId) {
      return;
    }

    _userId = userId;

    if (userId == null) {
      _currentSummary = null;
      _isLoading = false;
      _errorMessage = null;

      scheduleMicrotask(notifyListeners);
      return;
    }

    scheduleMicrotask(() {
      unawaited(refresh());
    });
  }

  /// Recomputes the summary for the currently selected period. Call this
  /// after any food activity is logged so the dashboard stays current.
  Future<void> refresh() async {
    final userId = _userId;

    if (userId == null) {
      _errorMessage = 'Please sign in to view analytics.';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final summary = _buildSummary(userId, _selectedPeriod);
      await _analyticsRepository.saveSummary(summary, userId: userId);

      if (_userId == userId) {
        _currentSummary = summary;
      }
    } catch (error) {
      if (_userId == userId) {
        _errorMessage = 'Unable to calculate analytics right now.';
      }
    } finally {
      if (_userId == userId) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  Future<void> changePeriod(AnalyticsPeriod period) async {
    if (_selectedPeriod == period) {
      return;
    }

    _selectedPeriod = period;
    await refresh();
  }

  AnalyticsSummary _buildSummary(String userId, AnalyticsPeriod period) {
    final now = DateTime.now();
    final start = switch (period) {
      AnalyticsPeriod.last7Days => now.subtract(const Duration(days: 7)),
      AnalyticsPeriod.last30Days => now.subtract(const Duration(days: 30)),
      AnalyticsPeriod.allTime => DateTime(2000),
    };

    final activities = _activityRepository.getActivitiesInRange(
      userId: userId,
      start: start,
      end: now,
    );

    double added = 0;
    double consumed = 0;
    double wasted = 0;
    double expired = 0;
    final wastedByItem = <String, double>{};

    for (final activity in activities) {
      switch (activity.activityType) {
        case ActivityType.added:
          added += activity.quantity;
          break;
        case ActivityType.consumed:
          consumed += activity.quantity;
          break;
        case ActivityType.wasted:
          wasted += activity.quantity;
          wastedByItem.update(
            activity.foodItemName,
            (value) => value + activity.quantity,
            ifAbsent: () => activity.quantity,
          );
          break;
        case ActivityType.expired:
          expired += activity.quantity;
          break;
      }
    }

    final wastePercentage = added == 0 ? 0.0 : (wasted / added).clamp(0.0, 1.0);

    String? mostWastedItemName;

    if (wastedByItem.isNotEmpty) {
      final sortedEntries = wastedByItem.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));

      mostWastedItemName = sortedEntries.first.key;
    }

    return AnalyticsSummary(
      id: 'analytics_summary_${userId}_${period.name}',
      ownerUserId: userId,
      periodStart: start,
      periodEnd: now,
      totalAdded: added,
      totalConsumed: consumed,
      totalWasted: wasted,
      totalExpired: expired,
      wastePercentage: wastePercentage,
      generatedAt: now,
      mostWastedItemName: mostWastedItemName,
    );
  }
}
