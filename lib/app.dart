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
  final Future<void> firebaseFuture;

  const GeoGuessApp({super.key, required this.firebaseFuture});

  @override
  Widget build(BuildContext context) {
    // MistakesProvider added here; LocaleProvider + PurchaseService + AuthService come from main.dart
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
            home: FutureBuilder<void>(
              future: firebaseFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  );
                }
                return const HomePage();
              },
            ),
          );
        },
      ),
    );
  }
}
