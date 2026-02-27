import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'user_service.dart';

class AuthService extends ChangeNotifier {
  FirebaseAuth? _auth;

  User? get currentUser {
    try { return _auth?.currentUser; } catch (_) { return null; }
  }
  bool get isSignedIn => currentUser != null;
  String? get uid => currentUser?.uid;
  String? get displayName => currentUser?.displayName;

  Stream<User?> get authStateChanges =>
      _auth?.authStateChanges() ?? const Stream.empty();

  AuthService() {
    try {
      _auth = FirebaseAuth.instance;
      _auth!.authStateChanges().listen((_) => notifyListeners());
    } catch (_) {
      // Firebase not initialized — app runs without auth features
    }
  }

  Future<String?> signUp({
    required String email,
    required String password,
    required String username,
  }) async {
    if (_auth == null) return 'Firebase is not configured yet.';
    try {
      final cred = await _auth!.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      await cred.user?.updateDisplayName(username.trim());
      await UserService().createProfile(
        uid: cred.user!.uid,
        username: username.trim(),
        email: email.trim(),
      );
      notifyListeners();
      return null; // null = success
    } on FirebaseAuthException catch (e) {
      return _authError(e.code);
    } catch (e) {
      return 'An error occurred. Please try again.';
    }
  }

  Future<String?> signIn({
    required String email,
    required String password,
  }) async {
    if (_auth == null) return 'Firebase is not configured yet.';
    try {
      await _auth!.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      notifyListeners();
      return null;
    } on FirebaseAuthException catch (e) {
      return _authError(e.code);
    } catch (e) {
      return 'An error occurred. Please try again.';
    }
  }

  Future<void> signOut() async {
    try { await _auth?.signOut(); } catch (_) {}
    notifyListeners();
  }

  String _authError(String code) {
    switch (code) {
      case 'email-already-in-use':
        return 'This email is already registered.';
      case 'invalid-email':
        return 'Please enter a valid email address.';
      case 'weak-password':
        return 'Password must be at least 6 characters.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Invalid email or password.';
      case 'too-many-requests':
        return 'Too many attempts. Please try again later.';
      default:
        return 'Authentication failed. Please try again.';
    }
  }
}
