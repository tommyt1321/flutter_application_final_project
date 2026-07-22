import 'dart:io';

import 'package:flutter_application_final_project/models/storage_location.dart';
import 'package:flutter_application_final_project/repositories/storage_location_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive_ce.dart';

void main() {
  late Directory temporaryDirectory;
  late Box<StorageLocation> storageLocationBox;
  late StorageLocationRepository repository;

  setUp(() async {
    temporaryDirectory = await Directory.systemTemp.createTemp(
      'pantrypal_storage_location_test_',
    );

    Hive.init(temporaryDirectory.path);

    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(StorageLocationAdapter());
    }

    storageLocationBox = await Hive.openBox<StorageLocation>(
      'storage_location_test_box',
    );

    repository = StorageLocationRepository(storageLocationBox);
  });

  tearDown(() async {
    await storageLocationBox.close();

    await Hive.deleteBoxFromDisk('storage_location_test_box');

    if (temporaryDirectory.existsSync()) {
      temporaryDirectory.deleteSync(recursive: true);
    }
  });

  test('seeds five default storage locations', () async {
    await repository.seedDefaultLocations();

    final locations = repository.getAllLocations();

    expect(locations.length, 5);

    expect(locations.any((location) => location.name == 'Pantry'), isTrue);

    expect(
      locations.any((location) => location.name == 'Refrigerator'),
      isTrue,
    );
  });

  test('does not duplicate default locations when seeded twice', () async {
    await repository.seedDefaultLocations();
    await repository.seedDefaultLocations();

    expect(repository.getAllLocations().length, 5);
  });

  test('adds a custom storage location', () async {
    final location = StorageLocation(
      id: 'custom_dining_room',
      name: 'Dining Room',
      iconKey: 'other',
      isDefault: false,
      createdAt: DateTime.now(),
    );

    await repository.addLocation(location);

    expect(
      repository.getLocationById('custom_dining_room')?.name,
      'Dining Room',
    );
  });

  test('rejects duplicate storage location names', () async {
    await repository.seedDefaultLocations();

    final duplicateLocation = StorageLocation(
      id: 'custom_pantry',
      name: 'pantry',
      iconKey: 'other',
      isDefault: false,
      createdAt: DateTime.now(),
    );

    await expectLater(
      repository.addLocation(duplicateLocation),
      throwsA(isA<StateError>()),
    );
  });

  test('updates a custom storage location', () async {
    final location = StorageLocation(
      id: 'custom_dining_room',
      name: 'Dining Room',
      iconKey: 'other',
      isDefault: false,
      createdAt: DateTime.now(),
    );

    await repository.addLocation(location);

    await repository.updateLocation(
      location.copyWith(name: 'Dining Cabinet', iconKey: 'cabinet'),
    );

    final updatedLocation = repository.getLocationById('custom_dining_room');

    expect(updatedLocation?.name, 'Dining Cabinet');

    expect(updatedLocation?.iconKey, 'cabinet');
  });

  test('prevents editing a default storage location', () async {
    await repository.seedDefaultLocations();

    final pantry = repository.getLocationById('location_pantry');

    expect(pantry, isNotNull);

    await expectLater(
      repository.updateLocation(pantry!.copyWith(name: 'Main Pantry')),
      throwsA(isA<StateError>()),
    );
  });

  test('prevents deletion of a default storage location', () async {
    await repository.seedDefaultLocations();

    await expectLater(
      repository.deleteLocation('location_pantry'),
      throwsA(isA<StateError>()),
    );
  });

  test('deletes a custom storage location', () async {
    final location = StorageLocation(
      id: 'custom_dining_room',
      name: 'Dining Room',
      iconKey: 'other',
      isDefault: false,
      createdAt: DateTime.now(),
    );

    await repository.addLocation(location);

    await repository.deleteLocation(location.id);

    expect(repository.getLocationById(location.id), isNull);
  });
}
