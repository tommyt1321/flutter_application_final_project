import 'package:hive_ce/hive_ce.dart';

import '../models/app_settings.dart';

class SettingsRepository {
  SettingsRepository(this._box);

  static const String _settingsKey = 'user_preferences';

  static const Set<String> _supportedThemeModes = {'system', 'light', 'dark'};

  final Box<AppSettings> _box;

  AppSettings getSettings() {
    return _box.get(_settingsKey) ?? const AppSettings();
  }

  Future<AppSettings> initialize() async {
    final existingSettings = _box.get(_settingsKey);

    if (existingSettings != null) {
      return existingSettings;
    }

    const defaultSettings = AppSettings();

    await _box.put(_settingsKey, defaultSettings);

    return defaultSettings;
  }

  Future<AppSettings> updateThemeMode(String themeModeKey) async {
    if (!_supportedThemeModes.contains(themeModeKey)) {
      throw ArgumentError('Unsupported theme mode: $themeModeKey');
    }

    final updatedSettings = getSettings().copyWith(themeModeKey: themeModeKey);

    await _box.put(_settingsKey, updatedSettings);

    return updatedSettings;
  }
}
