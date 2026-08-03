import 'package:hive_ce/hive_ce.dart';

import '../models/food_activity.dart';

class FoodActivityRepository {
  FoodActivityRepository(this._box);

  final Box<FoodActivity> _box;

  List<FoodActivity> getActivitiesForUser(String userId) {
    final activities = _box.values
        .where((activity) => activity.ownerUserId == userId)
        .toList();

    activities.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    return List<FoodActivity>.unmodifiable(activities);
  }

  List<FoodActivity> getActivitiesInRange({
    required String userId,
    required DateTime start,
    required DateTime end,
  }) {
    return getActivitiesForUser(userId).where((activity) {
      return !activity.timestamp.isBefore(start) &&
          !activity.timestamp.isAfter(end);
    }).toList();
  }

  Future<void> addActivity(FoodActivity activity, {required String userId}) async {
    _validateActivity(activity);

    if (_box.containsKey(activity.id)) {
      throw StateError('A food activity with this ID already exists.');
    }

    final savedActivity = activity.copyWith(
      ownerUserId: userId,
      foodItemName: activity.foodItemName.trim(),
      unit: activity.unit.trim(),
      notes: _normalizeNotes(activity.notes),
      clearNotes: _normalizeNotes(activity.notes) == null,
    );

    await _box.put(savedActivity.id, savedActivity);
  }

  Future<void> deleteActivity(String activityId, {required String userId}) async {
    final activity = _box.get(activityId);

    if (activity == null) {
      throw StateError('The selected food activity does not exist.');
    }

    if (activity.ownerUserId != userId) {
      throw StateError(
        'You do not have permission to delete this food activity.',
      );
    }

    await _box.delete(activityId);
  }

  void _validateActivity(FoodActivity activity) {
    final trimmedName = activity.foodItemName.trim();
    final trimmedUnit = activity.unit.trim();

    if (trimmedName.isEmpty) {
      throw ArgumentError('Food item name cannot be empty.');
    }

    if (activity.quantity <= 0) {
      throw ArgumentError('Quantity must be greater than zero.');
    }

    if (trimmedUnit.isEmpty) {
      throw ArgumentError('Please provide a unit.');
    }

    final notes = activity.notes?.trim();

    if (notes != null && notes.length > 200) {
      throw ArgumentError('Notes cannot exceed 200 characters.');
    }
  }

  String? _normalizeNotes(String? notes) {
    final trimmedNotes = notes?.trim();

    if (trimmedNotes == null || trimmedNotes.isEmpty) {
      return null;
    }

    return trimmedNotes;
  }
}
