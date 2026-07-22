import 'package:flutter/material.dart';

import '../models/storage_location.dart';
import '../repositories/storage_location_repository.dart';

class StorageLocationProvider extends ChangeNotifier {
  StorageLocationProvider(this._repository);

  final StorageLocationRepository _repository;

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

  Future<void> initialize() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _repository.seedDefaultLocations();
      _loadLocations();
    } catch (error) {
      _errorMessage = _getReadableError(error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void reloadLocations() {
    try {
      _errorMessage = null;
      _loadLocations();
      notifyListeners();
    } catch (error) {
      _errorMessage = _getReadableError(error);
      notifyListeners();
    }
  }

  StorageLocation? getLocationById(String id) {
    return _repository.getLocationById(id);
  }

  Future<bool> addLocation({
    required String name,
    required String iconKey,
  }) async {
    _startSubmitting();

    try {
      final location = StorageLocation(
        id: 'custom_location_${DateTime.now().microsecondsSinceEpoch}',
        name: name,
        iconKey: iconKey,
        isDefault: false,
        createdAt: DateTime.now(),
      );

      await _repository.addLocation(location);

      _loadLocations();

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
    _startSubmitting();

    try {
      final updatedLocation = location.copyWith(name: name, iconKey: iconKey);

      await _repository.updateLocation(updatedLocation);

      _loadLocations();

      return true;
    } catch (error) {
      _errorMessage = _getReadableError(error);

      return false;
    } finally {
      _finishSubmitting();
    }
  }

  Future<bool> deleteLocation(String locationId) async {
    _startSubmitting();

    try {
      await _repository.deleteLocation(locationId);

      _loadLocations();

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

  void _loadLocations() {
    _locations = _repository.getAllLocations();
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
