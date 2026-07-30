import 'dart:async';

import 'package:flutter/material.dart';

import '../models/food_activity.dart';
import '../repositories/food_activity_repository.dart';

class FoodActivityProvider extends ChangeNotifier {
  FoodActivityProvider(this._repository);

  final FoodActivityRepository _repository;

  String? _userId;
  List<FoodActivity> _activities = [];
  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _errorMessage;

  List<FoodActivity> get activities => List<FoodActivity>.unmodifiable(_activities);

  bool get isLoading => _isLoading;

  bool get isSubmitting => _isSubmitting;

  String? get errorMessage => _errorMessage;

  bool get hasActivities => _activities.isNotEmpty;

  int get activityCount => _activities.length;

  List<FoodActivity> activitiesByType(ActivityType type) {
    return _activities.where((activity) => activity.activityType == type).toList();
  }

  /// Called from a `ChangeNotifierProxyProvider<AuthProvider, FoodActivityProvider>`
  /// whenever the signed-in user changes, mirroring ShoppingItemProvider.
  void updateUserId(String? userId) {
    if (_userId == userId) {
      return;
    }

    _userId = userId;

    if (userId == null) {
      _activities = [];
      _isLoading = false;
      _errorMessage = null;

      scheduleMicrotask(notifyListeners);
      return;
    }

    scheduleMicrotask(() {
      unawaited(initialize());
    });
  }

  Future<void> initialize() async {
    final userId = _userId;

    if (userId == null) {
      _activities = [];
      _isLoading = false;
      _errorMessage = 'Please sign in to view food activity.';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _loadActivities(userId);
    } catch (error) {
      if (_userId == userId) {
        _errorMessage = _getReadableError(error);
      }
    } finally {
      if (_userId == userId) {
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  void reloadActivities() {
    final userId = _userId;

    if (userId == null) {
      return;
    }

    try {
      _errorMessage = null;
      _loadActivities(userId);
      notifyListeners();
    } catch (error) {
      _errorMessage = _getReadableError(error);
      notifyListeners();
    }
  }

  /// Logs a single food activity. This is the main entry point other
  /// modules call whenever something happens to a pantry item — e.g.
  /// the shopping->pantry conversion flow calls this with
  /// ActivityType.added right after creating the FoodItem.
  Future<bool> logActivity({
    required String foodItemId,
    required String foodItemName,
    required ActivityType activityType,
    required double quantity,
    required String unit,
    String? notes,
  }) async {
    final userId = _userId;

    if (userId == null) {
      _errorMessage = 'Please sign in before logging food activity.';
      notifyListeners();
      return false;
    }

    _startSubmitting();

    try {
      final activity = FoodActivity(
        id: 'food_activity_${DateTime.now().microsecondsSinceEpoch}',
        ownerUserId: userId,
        foodItemId: foodItemId,
        foodItemName: foodItemName,
        activityTypeIndex: activityType.index,
        quantity: quantity,
        unit: unit,
        timestamp: DateTime.now(),
        notes: notes,
      );

      await _repository.addActivity(activity, userId: userId);

      if (_userId == userId) {
        _loadActivities(userId);
      }

      return true;
    } catch (error, stackTrace) {
      debugPrint('Food activity log error: ${error.runtimeType} - $error');
      debugPrintStack(stackTrace: stackTrace);

      _errorMessage = _getReadableError(error);
      return false;
    } finally {
      _finishSubmitting();
    }
  }

  Future<bool> deleteActivity(String activityId) async {
    final userId = _userId;

    if (userId == null) {
      _errorMessage = 'Please sign in before deleting a food activity.';
      notifyListeners();
      return false;
    }

    _startSubmitting();

    try {
      await _repository.deleteActivity(activityId, userId: userId);

      if (_userId == userId) {
        _loadActivities(userId);
      }

      return true;
    } catch (error) {
      _errorMessage = _getReadableError(error);
      return false;
    } finally {
      _finishSubmitting();
    }
  }

  void clearError() {
    if (_errorMessage == null) {
      return;
    }

    _errorMessage = null;
    notifyListeners();
  }

  void _loadActivities(String userId) {
    _activities = _repository.getActivitiesForUser(userId);
  }

  void _startSubmitting() {
    _isSubmitting = true;
    _errorMessage = null;
    notifyListeners();
  }

  void _finishSubmitting() {
    _isSubmitting = false;
    notifyListeners();
  }

  String _getReadableError(Object error) {
    if (error is ArgumentError) {
      return error.message?.toString() ?? 'The activity information is invalid.';
    }

    if (error is StateError) {
      return error.message;
    }

    return 'Unable to complete the food-activity operation.';
  }
}
