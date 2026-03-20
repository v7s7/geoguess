import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geoguess_flags/l10n/app_localizations.dart';
import 'theme/app_theme.dart';
import 'pages/home_page.dart';
import 'services/auth_service.dart';
import 'services/mistakes_provider.dart';

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
            // Show a plain background while the localization delegate loads
            // (usually only one frame on first cold launch). This prevents the
            // HomePage from crashing if AppLocalizations.of(context) is null.
            home: const _AppStartup(),
          );
        },
      ),
    );
  }
}

// Guards the first frame: only renders HomePage once localizations are ready.
// On every platform this resolves within 1-2 frames — effectively invisible.
class _AppStartup extends StatelessWidget {
  const _AppStartup();

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    if (l10n == null) {
      // Localizations not yet loaded — show background colour only.
      // This prevents the null-bang (!) in HomePage from crashing in release.
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: SizedBox.shrink(),
      );
    }
    return const HomePage();
  }
}
