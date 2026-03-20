import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geoguess_flags/l10n/app_localizations.dart';
import 'firebase_options.dart';
import 'theme/app_theme.dart';
import 'pages/home_page.dart';
import 'services/auth_service.dart';
import 'services/mistakes_provider.dart';
import 'startup_logger.dart';

// --- LocaleProvider ---
class LocaleProvider extends ChangeNotifier {
  Locale _locale = const Locale('en');

  Locale get locale => _locale;

  LocaleProvider() {
    _loadLocale();
  }

  void setLocale(Locale loc) async {
    _locale = loc;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language_code', loc.languageCode);
  }

  Future<void> _loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString('language_code');
    if (code != null) {
      _locale = Locale(code);
      notifyListeners();
    }
  }
}

// --- Main App Widget ---
class GeoGuessApp extends StatelessWidget {
  const GeoGuessApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => MistakesProvider(),
      child: Consumer<LocaleProvider>(
        builder: (context, localeProv, child) {
          return MaterialApp(
            title: 'GeoGuess Flags',
            debugShowCheckedModeBanner: false,
            theme: AppTheme.themeData(localeProv.locale),
            locale: localeProv.locale,
            localizationsDelegates: const [
              AppLocalizations.delegate,
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            supportedLocales: const [
              Locale('en'),
              Locale('ar'),
            ],
            home: const _StartupGate(),
          );
        },
      ),
    );
  }
}

class _StartupGate extends StatefulWidget {
  const _StartupGate();

  @override
  State<_StartupGate> createState() => _StartupGateState();
}

class _StartupGateState extends State<_StartupGate> {
  bool _startupComplete = false;
  String _status = 'Preparing app…';
  String? _startupWarning;

  @override
  void initState() {
    super.initState();
    unawaited(_bootstrap());
  }

  Future<void> _bootstrap() async {
    startupLog('startup widget shown');

    await _initializeFirebase();
    if (!mounted) return;

    final auth = context.read<AuthService>();
    if (_startupWarning == null) {
      await auth.initialize();
    } else {
      auth.markUnavailable(_startupWarning);
    }
    if (!mounted) return;

    startupLog('navigating to home');
    setState(() {
      _startupComplete = true;
    });
  }

  Future<void> _initializeFirebase() async {
    setState(() {
      _status = 'Starting services…';
    });

    startupLog('before Firebase init');
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(
          options: DefaultFirebaseOptions.currentPlatform,
        ).timeout(const Duration(seconds: 5));
      }
      startupLog('after Firebase init');
    } on TimeoutException {
      _startupWarning = 'Firebase startup timed out. Continuing without online services.';
      startupLog('Firebase init timed out; continuing without online services');
    } catch (e, stack) {
      _startupWarning = 'Firebase startup failed. Continuing without online services.';
      startupLog('Firebase init failed: $e');
      debugPrintStack(stackTrace: stack, label: '[GeoGuess][startup]');
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    if (!_startupComplete || l10n == null) {
      return _StartupScreen(
        status: l10n == null ? 'Loading interface…' : _status,
      );
    }

    return const HomePage();
  }
}

class _StartupScreen extends StatelessWidget {
  final String status;

  const _StartupScreen({required this.status});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0D1B2E),
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    gradient: AppColors.gradientHero,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.18),
                        blurRadius: 22,
                        offset: const Offset(0, 12),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: const Text(
                    '🚩',
                    style: TextStyle(fontSize: 42),
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'GeoGuess Flags',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  status,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 15,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),
                const SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.6,
                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
