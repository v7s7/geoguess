import 'package:flutter/material.dart';
import 'package:geoguess_flags/l10n/app_localizations.dart';

class Country {
  final String nameEn;
  final String nameAr;
  final String cca2;
  final String region; // "Africa", "Europe", etc.
  final String capital;

  Country({
    required this.nameEn,
    required this.nameAr,
    required this.cca2,
    required this.region,
    required this.capital,
  });

  factory Country.fromJson(Map<String, dynamic> json) {
    String ar = json['name']['common'] ?? 'Unknown';
    if (json['translations'] != null &&
        json['translations']['ara'] != null &&
        json['translations']['ara']['common'] != null) {
      ar = json['translations']['ara']['common'];
    }

    String cap = 'N/A';
    if (json['capital'] != null && (json['capital'] as List).isNotEmpty) {
      cap = (json['capital'] as List).first;
    }

    return Country(
      nameEn: json['name']['common'] ?? 'Unknown',
      nameAr: ar,
      cca2: json['cca2'] ?? '',
      region: json['region'] ?? 'Other',
      capital: cap,
    );
  }

  String get flagUrl => 'https://flagcdn.com/w320/${cca2.toLowerCase()}.png';

  String localizedName(BuildContext context) {
    final locale = Localizations.localeOf(context);
    return locale.languageCode == 'ar' ? nameAr : nameEn;
  }

  // NEW: Helper to translate regions
  String localizedRegion(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    // Map API region string to Arb getter
    switch (region) {
      case 'Africa': return l10n.africa;
      case 'Americas': return l10n.americas;
      case 'Asia': return l10n.asia;
      case 'Europe': return l10n.europe;
      case 'Oceania': return l10n.oceania;
      case 'Antarctic': return l10n.antarctic;
      default: return region; // Fallback to English if unknown
    }
  }
}