import 'package:flutter/material.dart';

import '../models/app_settings.dart';
import '../repositories/settings_repository.dart';

class SettingsProvider extends ChangeNotifier {
  SettingsProvider(this._repository);

  final SettingsRepository _repository;

  AppSettings _settings = const AppSettings();
  bool _isLoading = false;
  bool _isSaving = false;
  String? _errorMessage;

  AppSettings get settings => _settings;

  bool get isLoading => _isLoading;

  bool get isSaving => _isSaving;

  String? get errorMessage => _errorMessage;

  ThemeMode get themeMode {
    switch (_settings.themeModeKey) {
      case 'light':
        return ThemeMode.light;

      case 'dark':
        return ThemeMode.dark;

      case 'system':
      default:
        return ThemeMode.system;
    }
  }

  String get themeModeLabel {
    switch (themeMode) {
      case ThemeMode.light:
        return 'Light';

      case ThemeMode.dark:
        return 'Dark';

      case ThemeMode.system:
        return 'System default';
    }
  }

  Future<void> initialize() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _settings = await _repository.initialize();
    } catch (_) {
      _errorMessage = 'Unable to load the application settings.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> setThemeMode(ThemeMode mode) async {
    if (mode == themeMode) {
      return true;
    }

    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final key = _themeModeToKey(mode);

      _settings = await _repository.updateThemeMode(key);

      return true;
    } catch (error) {
      if (error is ArgumentError) {
        _errorMessage = error.message?.toString();
      } else {
        _errorMessage = 'Unable to update the appearance setting.';
      }

      return false;
    } finally {
      _isSaving = false;
      notifyListeners();
    }
  }

  void clearError() {
    if (_errorMessage == null) {
      return;
    }

    _errorMessage = null;
    notifyListeners();
  }

  String _themeModeToKey(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';

      case ThemeMode.dark:
        return 'dark';

      case ThemeMode.system:
        return 'system';
    }
  }
}
