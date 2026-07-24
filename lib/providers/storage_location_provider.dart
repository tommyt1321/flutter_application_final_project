import 'dart:async';

import 'package:flutter/material.dart';

import '../models/storage_location.dart';
import '../repositories/storage_location_repository.dart';

class StorageLocationProvider extends ChangeNotifier {
  StorageLocationProvider(this._repository);

  final StorageLocationRepository _repository;

  String? _userId;
  List<StorageLocation> _locations = [];
  bool _isLoading = false;
  bool _isSubmitting = false;
  String? _errorMessage;

  List<StorageLocation> get locations =>
      List<StorageLocation>.unmodifiable(_locations);

  bool get isLoading => _isLoading;

  bool get isSubmitting => _isSubmitting;

  String? get errorMessage => _errorMessage;

  bool get hasLocations => _locations.isNotEmpty;

  int get locationCount => _locations.length;

  void updateUserId(String? userId) {
    if (_userId == userId) {
      return;
    }

    _userId = userId;

    if (userId == null) {
      _locations = [];
      _isLoading = false;
      _isSubmitting = false;
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
      _locations = [];
      _isLoading = false;
      _errorMessage = 'Please sign in to view storage locations.';
      notifyListeners();
      return;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.seedDefaultLocations();

      await _repository.migrateLegacyCustomLocations(userId);

      if (_userId != userId) {
        return;
      }

      _loadLocations(userId);
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

  void reloadLocations() {
    final userId = _userId;

    if (userId == null) {
      return;
    }

    try {
      _errorMessage = null;
      _loadLocations(userId);
      notifyListeners();
    } catch (error) {
      _errorMessage = _getReadableError(error);
      notifyListeners();
    }
  }

  StorageLocation? getLocationById(String id) {
    final userId = _userId;

    if (userId == null) {
      return null;
    }

    return _repository.getLocationById(id: id, userId: userId);
  }

  Future<bool> addLocation({
    required String name,
    required String iconKey,
  }) async {
    final userId = _userId;

    if (userId == null) {
      _errorMessage = 'Please sign in before adding a storage location.';
      notifyListeners();
      return false;
    }

    _startSubmitting();

    try {
      final location = StorageLocation(
        id:
            'custom_location_'
            '${DateTime.now().microsecondsSinceEpoch}',
        name: name,
        iconKey: iconKey,
        isDefault: false,
        createdAt: DateTime.now(),
        ownerUserId: userId,
      );

      await _repository.addLocation(location, userId: userId);

      if (_userId == userId) {
        _loadLocations(userId);
      }

      return true;
    } catch (error) {
      _errorMessage = _getReadableError(error);
      return false;
    } finally {
      _finishSubmitting();
    }
  }

  Future<bool> updateLocation({
    required StorageLocation location,
    required String name,
    required String iconKey,
  }) async {
    final userId = _userId;

    if (userId == null) {
      _errorMessage = 'Please sign in before editing a storage location.';
      notifyListeners();
      return false;
    }

    _startSubmitting();

    try {
      final updatedLocation = location.copyWith(name: name, iconKey: iconKey);

      await _repository.updateLocation(updatedLocation, userId: userId);

      if (_userId == userId) {
        _loadLocations(userId);
      }

      return true;
    } catch (error) {
      _errorMessage = _getReadableError(error);
      return false;
    } finally {
      _finishSubmitting();
    }
  }

  Future<bool> deleteLocation(String locationId) async {
    final userId = _userId;

    if (userId == null) {
      _errorMessage = 'Please sign in before deleting a storage location.';
      notifyListeners();
      return false;
    }

    _startSubmitting();

    try {
      await _repository.deleteLocation(locationId, userId: userId);

      if (_userId == userId) {
        _loadLocations(userId);
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

  void _loadLocations(String userId) {
    _locations = _repository.getLocationsForUser(userId);
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
      return error.message?.toString() ??
          'The storage location information is invalid.';
    }

    if (error is StateError) {
      return error.message;
    }

    return 'Unable to complete the storage location operation.';
  }
}
