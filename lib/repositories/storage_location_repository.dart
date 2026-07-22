import 'package:hive_ce/hive_ce.dart';

import '../models/storage_location.dart';

class StorageLocationRepository {
  StorageLocationRepository(this._box);

  final Box<StorageLocation> _box;

  List<StorageLocation> getAllLocations() {
    final locations = _box.values.toList();

    locations.sort((first, second) {
      if (first.isDefault != second.isDefault) {
        return first.isDefault ? -1 : 1;
      }

      return first.name.toLowerCase().compareTo(second.name.toLowerCase());
    });

    return List<StorageLocation>.unmodifiable(locations);
  }

  StorageLocation? getLocationById(String id) {
    return _box.get(id);
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

  Future<void> addLocation(StorageLocation location) async {
    final trimmedName = location.name.trim();

    if (trimmedName.isEmpty) {
      throw ArgumentError('Storage location name cannot be empty.');
    }

    if (_locationNameExists(trimmedName)) {
      throw StateError('A storage location with this name already exists.');
    }

    await _box.put(
      location.id,
      location.copyWith(name: trimmedName, isDefault: false),
    );
  }

  Future<void> updateLocation(StorageLocation location) async {
    final existingLocation = _box.get(location.id);

    if (existingLocation == null) {
      throw StateError('The selected storage location does not exist.');
    }

    if (existingLocation.isDefault) {
      throw StateError('Default storage locations cannot be edited.');
    }

    final trimmedName = location.name.trim();

    if (trimmedName.isEmpty) {
      throw ArgumentError('Storage location name cannot be empty.');
    }

    if (_locationNameExists(trimmedName, excludingId: location.id)) {
      throw StateError('A storage location with this name already exists.');
    }

    await _box.put(
      location.id,
      location.copyWith(name: trimmedName, isDefault: false),
    );
  }

  Future<void> deleteLocation(String locationId) async {
    final location = _box.get(locationId);

    if (location == null) {
      throw StateError('The selected storage location does not exist.');
    }

    if (location.isDefault) {
      throw StateError('Default storage locations cannot be deleted.');
    }

    await _box.delete(locationId);
  }

  bool _locationNameExists(String name, {String? excludingId}) {
    final normalizedName = name.trim().toLowerCase();

    return _box.values.any((location) {
      return location.id != excludingId &&
          location.name.trim().toLowerCase() == normalizedName;
    });
  }
}
