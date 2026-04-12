import 'dart:async';
import 'dart:ui';

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
import 'startup_logger.dart';
import 'theme/app_theme.dart';

// ─── Global Error Handlers ───────────────────────────────────────────────────
void _setupErrorHandlers() {
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    startupLog('FlutterError: ${details.exceptionAsString()}');
  };

  PlatformDispatcher.instance.onError = (error, stack) {
    startupLog('PlatformDispatcher error: $error');
    debugPrintStack(stackTrace: stack, label: '[GeoGuess][startup]');
    return false;
  };
}

Future<void> _lockOrientation() async {
  try {
    startupLog('before orientation lock');
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]).timeout(const Duration(seconds: 2));
    startupLog('after orientation lock');
  } on TimeoutException {
    startupLog('orientation lock timed out; continuing');
  } catch (e, stack) {
    startupLog('orientation lock failed: $e');
    debugPrintStack(stackTrace: stack, label: '[GeoGuess][startup]');
  }
}

// ─── Firebase Pre-init ───────────────────────────────────────────────────────
/// Initialises Firebase BEFORE runApp so that native iOS plugins (StoreKit,
/// FirebaseAuth) never race against an uninitialised Firebase instance.
/// This is the canonical Flutter+Firebase pattern and is the primary fix for
/// the black-screen issue that occurs on iOS native builds.
Future<void> _preInitFirebase() async {
  if (Firebase.apps.isNotEmpty) return; // already done (e.g. hot-restart)
  try {
    if (kIsWeb) {
      // Web JS modules may not be loaded yet on the very first frame.
      await Future<void>.delayed(const Duration(milliseconds: 200));
    }
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    ).timeout(const Duration(seconds: 10));
    startupLog('Firebase pre-initialised successfully');
  } on TimeoutException {
    startupLog('Firebase pre-init timed out; will retry in StartupGate');
  } catch (e) {
    startupLog('Firebase pre-init failed: $e; will retry in StartupGate');
  }
}

// ─── Entry Point ─────────────────────────────────────────────────────────────
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  startupLog('app entered main');

  _setupErrorHandlers();

  // CRITICAL: initialise Firebase before runApp to avoid iOS black screen.
  // Without this, native plugins race against an uninitialised Firebase SDK
  // which on iOS causes the first frame to never be committed to Metal.
  await _preInitFirebase();

  Animate.restartOnHotReload = true;
  startupLog('before runApp');

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => LocaleProvider()),
        ChangeNotifierProvider(create: (_) => ThemeProvider()),
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => PurchaseService()),
      ],
      child: const GeoGuessApp(),
    ),
  );
  startupLog('after runApp');

  unawaited(_lockOrientation());
}
