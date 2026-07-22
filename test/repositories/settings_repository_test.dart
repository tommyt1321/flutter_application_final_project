import 'dart:io';

import 'package:flutter_application_final_project/models/app_settings.dart';
import 'package:flutter_application_final_project/repositories/settings_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive_ce.dart';

void main() {
  late Directory temporaryDirectory;
  late Box<AppSettings> settingsBox;
  late SettingsRepository repository;

  setUp(() async {
    temporaryDirectory = await Directory.systemTemp.createTemp(
      'pantrypal_settings_repository_test_',
    );

    Hive.init(temporaryDirectory.path);

    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(AppSettingsAdapter());
    }

    settingsBox = await Hive.openBox<AppSettings>(
      'settings_repository_test_box',
    );

    repository = SettingsRepository(settingsBox);
  });

  tearDown(() async {
    await settingsBox.close();

    await Hive.deleteBoxFromDisk('settings_repository_test_box');

    if (temporaryDirectory.existsSync()) {
      temporaryDirectory.deleteSync(recursive: true);
    }
  });

  test('initializes settings with system theme by default', () async {
    final settings = await repository.initialize();

    expect(settings.themeModeKey, 'system');

    expect(repository.getSettings().themeModeKey, 'system');
  });

  test('does not create duplicate settings during initialization', () async {
    await repository.initialize();
    await repository.initialize();

    expect(settingsBox.length, 1);
  });

  test('updates the saved theme mode to dark', () async {
    await repository.initialize();

    final updatedSettings = await repository.updateThemeMode('dark');

    expect(updatedSettings.themeModeKey, 'dark');

    expect(repository.getSettings().themeModeKey, 'dark');
  });

  test('updates the saved theme mode to light', () async {
    await repository.initialize();

    final updatedSettings = await repository.updateThemeMode('light');

    expect(updatedSettings.themeModeKey, 'light');
  });

  test(
    'preserves settings when a new repository instance is created',
    () async {
      await repository.initialize();
      await repository.updateThemeMode('dark');

      final secondRepository = SettingsRepository(settingsBox);

      expect(secondRepository.getSettings().themeModeKey, 'dark');
    },
  );

  test('rejects unsupported theme mode values', () async {
    await repository.initialize();

    await expectLater(
      repository.updateThemeMode('blue'),
      throwsA(isA<ArgumentError>()),
    );
  });
}
