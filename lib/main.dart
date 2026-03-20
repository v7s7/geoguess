import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'app.dart';
import 'services/auth_service.dart';
import 'services/purchase_service.dart';
import 'startup_logger.dart';

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

// ─── Entry Point ─────────────────────────────────────────────────────────────
void main() {
  WidgetsFlutterBinding.ensureInitialized();
  startupLog('app entered main');

  _setupErrorHandlers();

  Animate.restartOnHotReload = true;
  startupLog('before runApp');

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
  startupLog('after runApp');

  unawaited(_lockOrientation());
}
