import 'package:firebase_auth/firebase_auth.dart';

class AuthRepository {
  AuthRepository(this._firebaseAuth);

  final FirebaseAuth _firebaseAuth;

  User? get currentUser => _firebaseAuth.currentUser;

  Stream<User?> get userChanges {
    return _firebaseAuth.userChanges();
  }

  Future<UserCredential> register({
    required String displayName,
    required String email,
    required String password,
  }) async {
    final credential = await _firebaseAuth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );

    final user = credential.user;

    if (user == null) {
      throw StateError(
        'The account was created, but the user could not be loaded.',
      );
    }

    await user.updateDisplayName(displayName.trim());

    await user.reload();

    return credential;
  }

  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) {
    return _firebaseAuth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<void> signOut() {
    return _firebaseAuth.signOut();
  }

  Future<void> sendPasswordResetEmail({required String email}) {
    return _firebaseAuth.sendPasswordResetEmail(email: email.trim());
  }

  Future<User?> updateDisplayName(String displayName) async {
    final user = _firebaseAuth.currentUser;

    if (user == null) {
      throw StateError('No authenticated user is available.');
    }

    await user.updateDisplayName(displayName.trim());

    await user.reload();

    return _firebaseAuth.currentUser;
  }
}
