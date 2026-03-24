import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../startup_logger.dart';
import 'user_service.dart';

class AuthService extends ChangeNotifier {
  FirebaseAuth? _auth;
  StreamSubscription<User?>? _authSubscription;
  bool _isInitialized = false;
  String? _startupError;

  User? get currentUser {
    try { return _auth?.currentUser; } catch (_) { return null; }
  }
  bool get isSignedIn => currentUser != null;
  bool get isInitialized => _isInitialized;
  bool get isAvailable => _auth != null;
  String? get uid => currentUser?.uid;
  String? get displayName => currentUser?.displayName;
  String? get startupError => _startupError;

  Stream<User?> get authStateChanges =>
      _auth?.authStateChanges() ?? const Stream.empty();

  AuthService();

  Future<void> initialize() async {
    if (_isInitialized) return;

    startupLog('before auth/session restore');
    try {
      _auth = FirebaseAuth.instance;

      // iOS Safari (and iOS Chrome, which also uses WebKit) restricts
      // IndexedDB in Private Browsing — quota is 0 and writes throw
      // QuotaExceededError.  Firebase Auth defaults to LOCAL persistence
      // (IndexedDB), so we gracefully fall back: LOCAL → SESSION → NONE.
      if (kIsWeb) {
        try {
          await _auth!.setPersistence(Persistence.LOCAL);
        } catch (_) {
          try {
            await _auth!.setPersistence(Persistence.SESSION);
            startupLog('auth: LOCAL persistence unavailable, using SESSION');
          } catch (_) {
            // In-memory only — user won't stay logged in across page loads,
            // but auth calls will still work (e.g. iOS Private Browsing).
            startupLog('auth: SESSION persistence unavailable, using NONE');
          }
        }
      }

      _authSubscription = _auth!.authStateChanges().listen((_) => notifyListeners());
      _startupError = null;
      startupLog('after auth/session restore');
    } catch (e, stack) {
      _auth = null;
      _startupError = e.toString();
      startupLog('auth/session restore failed: $e');
      debugPrintStack(stackTrace: stack, label: '[GeoGuess][startup]');
    } finally {
      _isInitialized = true;
      notifyListeners();
    }
  }

  void markUnavailable([String? reason]) {
    if (_isInitialized) return;
    _startupError = reason;
    _isInitialized = true;
    startupLog('auth/session restore skipped: ${reason ?? 'Firebase unavailable'}');
    notifyListeners();
  }

  Future<String?> signUp({
    required String email,
    required String password,
    required String username,
  }) async {
    if (_auth == null) {
      // Surface the real startup failure so it is visible on mobile where
      // the browser console is not accessible.
      final reason = _startupError ?? 'Firebase unavailable';
      return 'Authentication unavailable. ($reason)';
    }
    try {
      final cred = await _auth!.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      // Auth succeeded — update display name + Firestore profile.
      // Profile creation errors must NOT fail the sign-up (user already exists in Auth).
      try {
        await cred.user?.updateDisplayName(username.trim());
        await UserService().createProfile(
          uid: cred.user!.uid,
          username: username.trim(),
          email: email.trim(),
        );
      } catch (_) {
        // Profile creation failed (e.g. Firestore permission). Auth account was
        // still created — return success so the user is not stuck in a loop where
        // every retry says "email already in use".
      }
      notifyListeners();
      return null; // null = success
    } on FirebaseAuthException catch (e) {
      return _authError(e.code, e.message);
    } catch (e) {
      // Non-Firebase exception (e.g. JS interop error on iOS WebKit).
      // Return the raw message so it is visible on mobile without a console.
      return 'Error: $e';
    }
  }

  Future<String?> signIn({
    required String email,
    required String password,
  }) async {
    if (_auth == null) {
      final reason = _startupError ?? 'Firebase unavailable';
      return 'Authentication unavailable. ($reason)';
    }
    try {
      await _auth!.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      notifyListeners();
      return null;
    } on FirebaseAuthException catch (e) {
      return _authError(e.code, e.message);
    } catch (e) {
      return 'Error: $e';
    }
  }

  Future<void> signOut() async {
    try { await _auth?.signOut(); } catch (_) {}
    notifyListeners();
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

  String _authError(String code, [String? message]) {
    switch (code) {
      case 'email-already-in-use':
        return 'This email is already registered. Please sign in instead.';
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
      case 'network-request-failed':
        // Common on iOS Safari when the device blocks cross-origin XHR to
        // identitytoolkit.googleapis.com (content blockers, VPN, or poor
        // network).  Surfacing this code helps distinguish it from other errors.
        return 'Network error (auth/network-request-failed). '
            'Check your connection and that no content blocker is active.';
      default:
        // Show the raw code so iOS-specific errors are visible on mobile
        // without needing a console.  Can be replaced with a generic message
        // once the root cause is identified.
        return 'Authentication failed. (code: $code${message != null ? ', $message' : ''})';
    }
  }
}
