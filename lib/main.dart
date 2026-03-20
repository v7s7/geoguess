import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'firebase_options.dart';
import 'services/auth_service.dart';
import 'services/purchase_service.dart';

// ─── Startup Debug Log ───────────────────────────────────────────────────────
// TEMPORARY: tracks startup milestones. Remove before final App Store release.
// To view: Xcode → Window → Devices and Simulators → select device → open logs
void _log(String msg) {
  // ignore: avoid_print
  if (kDebugMode) print('[GeoGuess] $msg');
}

// ─── Global Error Handlers ───────────────────────────────────────────────────
void _setupErrorHandlers() {
  // Catches Flutter framework errors (bad widget builds, etc.)
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details); // still prints in debug
    _log('FlutterError: ${details.exceptionAsString()}');
  };

  // Catches errors outside the Flutter framework (async errors, isolates)
  PlatformDispatcher.instance.onError = (error, stack) {
    _log('PlatformDispatcher error: $error\n$stack');
    return true; // returning true suppresses the default crash
  };
}

// ─── Firebase Init ───────────────────────────────────────────────────────────
// Initialises Firebase with a hard 5-second timeout so the app always
// reaches runApp() even if Firebase hangs (mismatched config, no network, etc.)
Future<void> _initFirebaseSafe() async {
  try {
    _log('Firebase.initializeApp starting…');
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    ).timeout(
      const Duration(seconds: 5),
      onTimeout: () {
        _log('Firebase.initializeApp TIMED OUT — continuing without Firebase');
      },
    );
    _log('Firebase.initializeApp done');
  } catch (e) {
    // Mismatched App ID, duplicate-app, or any other Firebase error.
    // The app still runs — auth/Firestore features will be unavailable.
    _log('Firebase.initializeApp ERROR (non-fatal): $e');
  }
}

// ─── Entry Point ─────────────────────────────────────────────────────────────
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  _log('main() started');

  _setupErrorHandlers();

  Animate.restartOnHotReload = true;

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  _log('orientations locked');

  await _initFirebaseSafe();
  _log('calling runApp()');

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
        ChangeNotifierProvider(create: (_) => PurchaseService()),
        ChangeNotifierProvider(create: (_) => AuthService()),
      ],
      child: const GeoGuessApp(),
    ),
  );

  _log('runApp() returned');
}
