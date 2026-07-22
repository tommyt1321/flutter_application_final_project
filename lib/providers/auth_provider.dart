import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../repositories/auth_repository.dart';

class AuthProvider extends ChangeNotifier {
  AuthProvider(this._repository) {
    _user = _repository.currentUser;

    _userSubscription = _repository.userChanges.listen(
      _handleUserChange,
      onError: (_) {
        _errorMessage = 'Unable to check the authentication status.';
        _isInitializing = false;
        notifyListeners();
      },
    );
  }

  final AuthRepository _repository;

  late final StreamSubscription<User?> _userSubscription;

  User? _user;
  bool _isInitializing = true;
  bool _isSubmitting = false;
  String? _errorMessage;

  User? get user => _user;

  bool get isInitializing => _isInitializing;

  bool get isSubmitting => _isSubmitting;

  String? get errorMessage => _errorMessage;

  bool get isAuthenticated => _user != null;

  String? get userId => _user?.uid;

  String get email => _user?.email ?? '';

  String get displayName {
    final name = _user?.displayName?.trim();

    if (name == null || name.isEmpty) {
      return 'PantryPal User';
    }

    return name;
  }

  Future<bool> register({
    required String displayName,
    required String email,
    required String password,
  }) async {
    final nameError = _validateDisplayName(displayName);

    if (nameError != null) {
      _errorMessage = nameError;
      notifyListeners();
      return false;
    }

    final emailError = _validateEmail(email);

    if (emailError != null) {
      _errorMessage = emailError;
      notifyListeners();
      return false;
    }

    final passwordError = _validatePassword(password);

    if (passwordError != null) {
      _errorMessage = passwordError;
      notifyListeners();
      return false;
    }

    _startSubmitting();

    try {
      final credential = await _repository.register(
        displayName: displayName,
        email: email,
        password: password,
      );

      _user = credential.user;
      notifyListeners();

      return true;
    } on FirebaseAuthException catch (error) {
      _errorMessage = _mapFirebaseError(error);
      return false;
    } on StateError catch (error) {
      _errorMessage = error.message;
      return false;
    } catch (_) {
      _errorMessage = 'Unable to create the account. Please try again.';
      return false;
    } finally {
      _finishSubmitting();
    }
  }

  Future<bool> signIn({required String email, required String password}) async {
    final emailError = _validateEmail(email);

    if (emailError != null) {
      _errorMessage = emailError;
      notifyListeners();
      return false;
    }

    if (password.isEmpty) {
      _errorMessage = 'Please enter your password.';
      notifyListeners();
      return false;
    }

    _startSubmitting();

    try {
      final credential = await _repository.signIn(
        email: email,
        password: password,
      );

      _user = credential.user;
      notifyListeners();

      return true;
    } on FirebaseAuthException catch (error) {
      _errorMessage = _mapFirebaseError(error);
      return false;
    } catch (_) {
      _errorMessage = 'Unable to sign in. Please try again.';
      return false;
    } finally {
      _finishSubmitting();
    }
  }

  Future<bool> signOut() async {
    _startSubmitting();

    try {
      await _repository.signOut();

      _user = null;
      notifyListeners();

      return true;
    } on FirebaseAuthException catch (error) {
      _errorMessage = _mapFirebaseError(error);
      return false;
    } catch (_) {
      _errorMessage = 'Unable to sign out. Please try again.';
      return false;
    } finally {
      _finishSubmitting();
    }
  }

  Future<bool> sendPasswordResetEmail(String email) async {
    final emailError = _validateEmail(email);

    if (emailError != null) {
      _errorMessage = emailError;
      notifyListeners();
      return false;
    }

    _startSubmitting();

    try {
      await _repository.sendPasswordResetEmail(email: email);

      return true;
    } on FirebaseAuthException catch (error) {
      _errorMessage = _mapFirebaseError(error);
      return false;
    } catch (_) {
      _errorMessage = 'Unable to send the password-reset email.';
      return false;
    } finally {
      _finishSubmitting();
    }
  }

  Future<bool> updateDisplayName(String displayName) async {
    final nameError = _validateDisplayName(displayName);

    if (nameError != null) {
      _errorMessage = nameError;
      notifyListeners();
      return false;
    }

    _startSubmitting();

    try {
      _user = await _repository.updateDisplayName(displayName);

      notifyListeners();

      return true;
    } on FirebaseAuthException catch (error) {
      _errorMessage = _mapFirebaseError(error);
      return false;
    } on StateError catch (error) {
      _errorMessage = error.message;
      return false;
    } catch (_) {
      _errorMessage = 'Unable to update the profile name.';
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

  void _handleUserChange(User? user) {
    _user = user;
    _isInitializing = false;
    notifyListeners();
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

  String? _validateDisplayName(String displayName) {
    final trimmedName = displayName.trim();

    if (trimmedName.length < 2) {
      return 'Your name must contain at least 2 characters.';
    }

    if (trimmedName.length > 30) {
      return 'Your name cannot exceed 30 characters.';
    }

    return null;
  }

  String? _validateEmail(String email) {
    final trimmedEmail = email.trim();

    if (trimmedEmail.isEmpty) {
      return 'Please enter your email address.';
    }

    final emailPattern = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');

    if (!emailPattern.hasMatch(trimmedEmail)) {
      return 'Please enter a valid email address.';
    }

    return null;
  }

  String? _validatePassword(String password) {
    if (password.length < 6) {
      return 'Your password must contain at least 6 characters.';
    }

    return null;
  }

  String _mapFirebaseError(FirebaseAuthException error) {
    switch (error.code) {
      case 'email-already-in-use':
        return 'An account already exists for this email address.';

      case 'invalid-email':
        return 'The email address is invalid.';

      case 'weak-password':
        return 'The password is too weak.';

      case 'invalid-credential':
      case 'user-not-found':
      case 'wrong-password':
        return 'The email address or password is incorrect.';

      case 'user-disabled':
        return 'This account has been disabled.';

      case 'operation-not-allowed':
        return 'Email and password authentication is not enabled.';

      case 'too-many-requests':
        return 'Too many attempts were made. Please try again later.';

      case 'network-request-failed':
        return 'A network error occurred. Check your connection.';

      case 'requires-recent-login':
        return 'Please sign in again before completing this action.';

      default:
        return error.message ?? 'An authentication error occurred.';
    }
  }

  @override
  void dispose() {
    _userSubscription.cancel();
    super.dispose();
  }
}
