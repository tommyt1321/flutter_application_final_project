import 'package:hive_ce/hive_ce.dart';

import '../models/storage_location.dart';

class StorageLocationRepository {
  StorageLocationRepository(this._box);

  final Box<StorageLocation> _box;

  List<StorageLocation> getLocationsForUser(String userId) {
    final locations = _box.values.where((location) {
      return location.isDefault || location.ownerUserId == userId;
    }).toList();

    locations.sort((first, second) {
      if (first.isDefault != second.isDefault) {
        return first.isDefault ? -1 : 1;
      }

      return first.name.toLowerCase().compareTo(second.name.toLowerCase());
    });

    return List<StorageLocation>.unmodifiable(locations);
  }

  StorageLocation? getLocationById({
    required String id,
    required String userId,
  }) {
    final location = _box.get(id);

    if (location == null) {
      return null;
    }

    if (location.isDefault || location.ownerUserId == userId) {
      return location;
    }

    return null;
  }

  Future<void> seedDefaultLocations() async {
    final now = DateTime.now();

    final defaultLocations = [
      StorageLocation(
        id: 'location_pantry',
        name: 'Pantry',
        iconKey: 'pantry',
        isDefault: true,
        createdAt: now,
      ),
      StorageLocation(
        id: 'location_refrigerator',
        name: 'Refrigerator',
        iconKey: 'refrigerator',
        isDefault: true,
        createdAt: now,
      ),
      StorageLocation(
        id: 'location_freezer',
        name: 'Freezer',
        iconKey: 'freezer',
        isDefault: true,
        createdAt: now,
      ),
      StorageLocation(
        id: 'location_kitchen_cabinet',
        name: 'Kitchen Cabinet',
        iconKey: 'cabinet',
        isDefault: true,
        createdAt: now,
      ),
      StorageLocation(
        id: 'location_countertop',
        name: 'Countertop',
        iconKey: 'countertop',
        isDefault: true,
        createdAt: now,
      ),
    ];

    for (final location in defaultLocations) {
      if (!_box.containsKey(location.id)) {
        await _box.put(location.id, location);
      }
    }
  }

  /// Assigns custom locations created before Firebase Authentication
  /// was added to the first signed-in user.
  Future<void> migrateLegacyCustomLocations(String userId) async {
    final locations = _box.values.toList(growable: false);

    for (final location in locations) {
      if (!location.isDefault && location.ownerUserId == null) {
        await _box.put(location.id, location.copyWith(ownerUserId: userId));
      }
    }
  }

  Future<void> addLocation(
    StorageLocation location, {
    required String userId,
  }) async {
    final trimmedName = location.name.trim();

    if (trimmedName.isEmpty) {
      throw ArgumentError('Storage location name cannot be empty.');
    }

    if (_locationNameExists(trimmedName, userId: userId)) {
      throw StateError('A storage location with this name already exists.');
    }

    await _box.put(
      location.id,
      location.copyWith(
        name: trimmedName,
        isDefault: false,
        ownerUserId: userId,
      ),
    );
  }

  Future<void> updateLocation(
    StorageLocation location, {
    required String userId,
  }) async {
    final existingLocation = _box.get(location.id);

    if (existingLocation == null) {
      throw StateError('The selected storage location does not exist.');
    }

    if (existingLocation.isDefault) {
      throw StateError('Default storage locations cannot be edited.');
    }

    if (existingLocation.ownerUserId != userId) {
      throw StateError(
        'You do not have permission to edit this storage location.',
      );
    }

    final trimmedName = location.name.trim();

    if (trimmedName.isEmpty) {
      throw ArgumentError('Storage location name cannot be empty.');
    }

    if (_locationNameExists(
      trimmedName,
      userId: userId,
      excludingId: location.id,
    )) {
      throw StateError('A storage location with this name already exists.');
    }

    await _box.put(
      location.id,
      location.copyWith(
        name: trimmedName,
        isDefault: false,
        ownerUserId: userId,
      ),
    );
  }

  Future<void> deleteLocation(
    String locationId, {
    required String userId,
  }) async {
    final location = _box.get(locationId);

    if (location == null) {
      throw StateError('The selected storage location does not exist.');
    }

    if (location.isDefault) {
      throw StateError('Default storage locations cannot be deleted.');
    }

    if (location.ownerUserId != userId) {
      throw StateError(
        'You do not have permission to delete this storage location.',
      );
    }

    await _box.delete(locationId);
  }

  bool _locationNameExists(
    String name, {
    required String userId,
    String? excludingId,
  }) {
    final normalizedName = name.trim().toLowerCase();

    return _box.values.any((location) {
      final isVisibleToUser =
          location.isDefault || location.ownerUserId == userId;

      return isVisibleToUser &&
          location.id != excludingId &&
          location.name.trim().toLowerCase() == normalizedName;
    });
  }
}
