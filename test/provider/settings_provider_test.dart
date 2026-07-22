import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_application_final_project/models/app_settings.dart';
import 'package:flutter_application_final_project/providers/settings_provider.dart';
import 'package:flutter_application_final_project/repositories/settings_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive_ce.dart';

void main() {
  late Directory temporaryDirectory;
  late Box<AppSettings> settingsBox;
  late SettingsRepository repository;
  late SettingsProvider provider;

  setUp(() async {
    temporaryDirectory = await Directory.systemTemp.createTemp(
      'pantrypal_settings_provider_test_',
    );

    Hive.init(temporaryDirectory.path);

    if (!Hive.isAdapterRegistered(2)) {
      Hive.registerAdapter(AppSettingsAdapter());
    }

    settingsBox = await Hive.openBox<AppSettings>('settings_provider_test_box');

    repository = SettingsRepository(settingsBox);
    provider = SettingsProvider(repository);
  });

  tearDown(() async {
    provider.dispose();

    await settingsBox.close();

    await Hive.deleteBoxFromDisk('settings_provider_test_box');

    if (temporaryDirectory.existsSync()) {
      temporaryDirectory.deleteSync(recursive: true);
    }
  });

  test('uses system theme after initialization', () async {
    await provider.initialize();

    expect(provider.themeMode, ThemeMode.system);

    expect(provider.themeModeLabel, 'System default');

    expect(provider.isLoading, isFalse);

    expect(provider.errorMessage, isNull);
  });

  test('changes the theme mode to dark', () async {
    await provider.initialize();

    final success = await provider.setThemeMode(ThemeMode.dark);

    expect(success, isTrue);
    expect(provider.themeMode, ThemeMode.dark);
    expect(provider.themeModeLabel, 'Dark');
    expect(provider.isSaving, isFalse);
    expect(provider.errorMessage, isNull);
  });

  test('changes the theme mode to light', () async {
    await provider.initialize();

    final success = await provider.setThemeMode(ThemeMode.light);

    expect(success, isTrue);
    expect(provider.themeMode, ThemeMode.light);
    expect(provider.themeModeLabel, 'Light');
  });

  test('stores the selected theme in Hive', () async {
    await provider.initialize();

    await provider.setThemeMode(ThemeMode.dark);

    final storedSettings = repository.getSettings();

    expect(storedSettings.themeModeKey, 'dark');
  });

  test('loads a previously saved theme', () async {
    await repository.initialize();
    await repository.updateThemeMode('dark');

    final newProvider = SettingsProvider(repository);

    await newProvider.initialize();

    expect(newProvider.themeMode, ThemeMode.dark);

    newProvider.dispose();
  });

  test('returns true when selecting the current theme again', () async {
    await provider.initialize();

    final success = await provider.setThemeMode(ThemeMode.system);

    expect(success, isTrue);
    expect(provider.themeMode, ThemeMode.system);
    expect(provider.isSaving, isFalse);
  });
}
