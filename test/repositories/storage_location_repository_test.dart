import 'dart:io';

import 'package:flutter_application_final_project/models/storage_location.dart';
import 'package:flutter_application_final_project/repositories/storage_location_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive_ce.dart';

void main() {
  const userOne = 'firebase_user_one';
  const userTwo = 'firebase_user_two';
  const boxName = 'storage_location_test_box';

  late Directory temporaryDirectory;
  late Box<StorageLocation> locationBox;
  late StorageLocationRepository repository;

  setUp(() async {
    temporaryDirectory = await Directory.systemTemp.createTemp(
      'pantrypal_storage_location_test_',
    );

    Hive.init(temporaryDirectory.path);

    if (!Hive.isAdapterRegistered(1)) {
      Hive.registerAdapter(StorageLocationAdapter());
    }

    locationBox = await Hive.openBox<StorageLocation>(boxName);

    repository = StorageLocationRepository(locationBox);
  });

  tearDown(() async {
    if (locationBox.isOpen) {
      await locationBox.close();
    }

    await Hive.deleteBoxFromDisk(boxName);

    if (temporaryDirectory.existsSync()) {
      temporaryDirectory.deleteSync(recursive: true);
    }
  });

  test('seeds five shared default storage locations', () async {
    await repository.seedDefaultLocations();

    final locations = repository.getLocationsForUser(userOne);

    expect(locations.length, 5);

    expect(locations.every((location) => location.isDefault), isTrue);

    expect(locations.every((location) => location.ownerUserId == null), isTrue);
  });

  test('does not duplicate default locations when seeded twice', () async {
    await repository.seedDefaultLocations();
    await repository.seedDefaultLocations();

    final locations = repository.getLocationsForUser(userOne);

    expect(locations.length, 5);
  });

  test('adds a custom location for one user', () async {
    final location = StorageLocation(
      id: 'custom_kitchen_fridge',
      name: 'Kitchen Fridge',
      iconKey: 'refrigerator',
      isDefault: false,
      createdAt: DateTime.now(),
    );

    await repository.addLocation(location, userId: userOne);

    final savedLocation = repository.getLocationById(
      id: location.id,
      userId: userOne,
    );

    expect(savedLocation?.name, 'Kitchen Fridge');

    expect(savedLocation?.ownerUserId, userOne);

    expect(savedLocation?.isDefault, isFalse);
  });

  test('does not show another users custom location', () async {
    await repository.seedDefaultLocations();

    final location = StorageLocation(
      id: 'custom_kitchen_fridge',
      name: 'Kitchen Fridge',
      iconKey: 'refrigerator',
      isDefault: false,
      createdAt: DateTime.now(),
    );

    await repository.addLocation(location, userId: userOne);

    final userOneLocations = repository.getLocationsForUser(userOne);

    final userTwoLocations = repository.getLocationsForUser(userTwo);

    expect(userOneLocations.any((item) => item.id == location.id), isTrue);

    expect(userTwoLocations.any((item) => item.id == location.id), isFalse);

    expect(
      repository.getLocationById(id: location.id, userId: userTwo),
      isNull,
    );
  });

  test('allows different users to use the same custom location name', () async {
    await repository.addLocation(
      StorageLocation(
        id: 'user_one_kitchen_fridge',
        name: 'Kitchen Fridge',
        iconKey: 'refrigerator',
        isDefault: false,
        createdAt: DateTime.now(),
      ),
      userId: userOne,
    );

    await repository.addLocation(
      StorageLocation(
        id: 'user_two_kitchen_fridge',
        name: 'Kitchen Fridge',
        iconKey: 'refrigerator',
        isDefault: false,
        createdAt: DateTime.now(),
      ),
      userId: userTwo,
    );

    final userOneMatches = repository
        .getLocationsForUser(userOne)
        .where((location) => location.name == 'Kitchen Fridge')
        .length;

    final userTwoMatches = repository
        .getLocationsForUser(userTwo)
        .where((location) => location.name == 'Kitchen Fridge')
        .length;

    expect(userOneMatches, 1);
    expect(userTwoMatches, 1);
  });

  test('prevents duplicate visible location names for one user', () async {
    await repository.addLocation(
      StorageLocation(
        id: 'first_fridge',
        name: 'Kitchen Fridge',
        iconKey: 'refrigerator',
        isDefault: false,
        createdAt: DateTime.now(),
      ),
      userId: userOne,
    );

    await expectLater(
      repository.addLocation(
        StorageLocation(
          id: 'second_fridge',
          name: 'kitchen fridge',
          iconKey: 'refrigerator',
          isDefault: false,
          createdAt: DateTime.now(),
        ),
        userId: userOne,
      ),
      throwsA(isA<StateError>()),
    );
  });

  test('updates a custom location belonging to the user', () async {
    final location = StorageLocation(
      id: 'custom_fridge',
      name: 'Small Fridge',
      iconKey: 'refrigerator',
      isDefault: false,
      createdAt: DateTime.now(),
    );

    await repository.addLocation(location, userId: userOne);

    await repository.updateLocation(
      location.copyWith(name: 'Large Fridge', iconKey: 'freezer'),
      userId: userOne,
    );

    final updatedLocation = repository.getLocationById(
      id: location.id,
      userId: userOne,
    );

    expect(updatedLocation?.name, 'Large Fridge');

    expect(updatedLocation?.iconKey, 'freezer');

    expect(updatedLocation?.ownerUserId, userOne);
  });

  test('prevents a user editing another users location', () async {
    final location = StorageLocation(
      id: 'custom_fridge',
      name: 'Kitchen Fridge',
      iconKey: 'refrigerator',
      isDefault: false,
      createdAt: DateTime.now(),
    );

    await repository.addLocation(location, userId: userOne);

    await expectLater(
      repository.updateLocation(
        location.copyWith(name: 'Changed Fridge'),
        userId: userTwo,
      ),
      throwsA(isA<StateError>()),
    );
  });

  test('deletes a custom location belonging to the user', () async {
    final location = StorageLocation(
      id: 'custom_fridge',
      name: 'Kitchen Fridge',
      iconKey: 'refrigerator',
      isDefault: false,
      createdAt: DateTime.now(),
    );

    await repository.addLocation(location, userId: userOne);

    await repository.deleteLocation(location.id, userId: userOne);

    expect(
      repository.getLocationById(id: location.id, userId: userOne),
      isNull,
    );
  });

  test('prevents a user deleting another users location', () async {
    final location = StorageLocation(
      id: 'custom_fridge',
      name: 'Kitchen Fridge',
      iconKey: 'refrigerator',
      isDefault: false,
      createdAt: DateTime.now(),
    );

    await repository.addLocation(location, userId: userOne);

    await expectLater(
      repository.deleteLocation(location.id, userId: userTwo),
      throwsA(isA<StateError>()),
    );
  });

  test('migrates a legacy custom location to the current user', () async {
    final legacyLocation = StorageLocation(
      id: 'legacy_location',
      name: 'Legacy Cupboard',
      iconKey: 'cabinet',
      isDefault: false,
      createdAt: DateTime.now(),
    );

    await locationBox.put(legacyLocation.id, legacyLocation);

    await repository.migrateLegacyCustomLocations(userOne);

    final migratedLocation = locationBox.get(legacyLocation.id);

    expect(migratedLocation?.ownerUserId, userOne);
  });

  test('prevents editing a default location', () async {
    await repository.seedDefaultLocations();

    final pantry = repository.getLocationById(
      id: 'location_pantry',
      userId: userOne,
    );

    expect(pantry, isNotNull);

    await expectLater(
      repository.updateLocation(
        pantry!.copyWith(name: 'Updated Pantry'),
        userId: userOne,
      ),
      throwsA(isA<StateError>()),
    );
  });

  test('prevents deletion of a default location', () async {
    await repository.seedDefaultLocations();

    await expectLater(
      repository.deleteLocation('location_pantry', userId: userOne),
      throwsA(isA<StateError>()),
    );
  });
}
