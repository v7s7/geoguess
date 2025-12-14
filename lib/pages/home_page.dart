import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geoguess_flags/l10n/app_localizations.dart';
import '../app.dart';
import '../models/country.dart';
import '../models/game_config.dart';
import '../services/country_api.dart';
import '../services/mistakes_provider.dart';
import 'play_setup_page.dart';
import 'game_page.dart';
import 'learn_page.dart'; // Ensure this import exists

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Country> _allCountries = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _preloadData();
  }

  Future<void> _preloadData() async {
    try {
      final countries = await CountryApi().fetchCountries();
      if (mounted) {
        setState(() {
          _allCountries = countries;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _startReview(BuildContext context, MistakesProvider mistakesProv) {
    final l10n = AppLocalizations.of(context)!;
    
    final reviewList = _allCountries
        .where((c) => mistakesProv.mistakenCca2s.contains(c.cca2))
        .toList();

    if (reviewList.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.noMistakes)),
      );
      return;
    }

    final config = GameConfig(
      mode: GameMode.quiz,
      questionCount: reviewList.length,
      choicesCount: 4,
      timerSeconds: null,
      isReviewMode: true,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GamePage(countries: reviewList, config: config),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final localeProv = Provider.of<LocaleProvider>(context);
    final mistakesProv = Provider.of<MistakesProvider>(context);

    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.flag_circle, size: 100, color: Colors.indigo),
              const SizedBox(height: 24),
              Text(
                l10n.appTitle,
                style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.indigo,
                    ),
              ),
              const SizedBox(height: 48),

              // 1. Learn Button (Blue) - NEW
              SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.blue.shade600,
                  ),
                  onPressed: _isLoading 
                    ? null 
                    : () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => LearnPage(countries: _allCountries)),
                      );
                    },
                  icon: const Icon(Icons.school),
                  label: Text(l10n.learn),
                ),
              ),
              const SizedBox(height: 16),
              
              // 2. Play Button
              SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton.icon(
                  onPressed: _isLoading 
                    ? null 
                    : () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const PlaySetupPage()),
                      );
                    },
                  icon: const Icon(Icons.play_arrow),
                  label: Text(l10n.play),
                ),
              ),
              
              const SizedBox(height: 16),

              // 3. Review Mistakes Button (Orange)
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange.shade50,
                    foregroundColor: Colors.orange.shade900,
                  ),
                  onPressed: (mistakesProv.hasMistakes && !_isLoading)
                      ? () => _startReview(context, mistakesProv)
                      : null,
                  icon: const Icon(Icons.refresh),
                  label: Text("${l10n.reviewMistakes} (${mistakesProv.mistakenCca2s.length})"),
                ),
              ),

              const SizedBox(height: 16),
              
              // 4. Language Switch
              Card(
                child: ListTile(
                  leading: const Icon(Icons.language),
                  title: Text(l10n.language),
                  trailing: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: localeProv.locale.languageCode,
                      items: const [
                        DropdownMenuItem(value: 'en', child: Text('English')),
                        DropdownMenuItem(value: 'ar', child: Text('العربية')),
                      ],
                      onChanged: (val) {
                        if (val != null) localeProv.setLocale(Locale(val));
                      },
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}