import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:geoguess_flags/l10n/app_localizations.dart';
import '../app.dart';
import '../models/country.dart';
import '../models/game_config.dart';
import '../services/auth_service.dart';
import '../services/country_api.dart';
import '../services/mistakes_provider.dart';
import '../services/purchase_service.dart';
import '../theme/app_theme.dart';
import 'play_setup_page.dart';
import 'game_page.dart';
import 'learn_page.dart';
import 'paywall_page.dart';
import 'speed_mode_page.dart';
import 'continent_battle_page.dart';
import 'leaderboard_page.dart';
import 'achievements_page.dart';
import 'profile_page.dart';
import 'auth/login_page.dart';
import 'online/multiplayer_lobby_page.dart';

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
    } catch (_) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _startReview(BuildContext context, MistakesProvider mp) {
    final l10n = AppLocalizations.of(context)!;
    final list = _allCountries.where((c) => mp.mistakenCca2s.contains(c.cca2)).toList();
    if (list.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(l10n.noMistakes),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ));
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GamePage(
          countries: list,
          config: GameConfig(
            mode: GameMode.quiz,
            questionCount: list.length,
            choicesCount: 4,
            isReviewMode: true,
          ),
        ),
      ),
    );
  }

  void _requireAuth(BuildContext context, Widget Function() builder) {
    final auth = context.read<AuthService>();
    if (!auth.isSignedIn) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginPage()));
      return;
    }
    Navigator.push(context, MaterialPageRoute(builder: (_) => builder()));
  }

  void _openProfile(BuildContext context) {
    final auth = context.read<AuthService>();
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => auth.isSignedIn ? const ProfilePage() : const LoginPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final localeProv = Provider.of<LocaleProvider>(context);
    final mp = Provider.of<MistakesProvider>(context);
    final ps = Provider.of<PurchaseService>(context);
    final auth = Provider.of<AuthService>(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: CustomScrollView(
        slivers: [
          // ── Gradient hero header ──────────────────────────────
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                gradient: AppColors.gradientHero,
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
              ),
              child: SafeArea(
                bottom: false,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
                  child: Column(
                    children: [
                      // Top bar
                      Row(
                        children: [
                          const Icon(Icons.public_rounded, color: Colors.white, size: 24),
                          const SizedBox(width: 8),
                          const Text(
                            'GeoGuess',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.3,
                            ),
                          ),
                          const Spacer(),
                          // Language switcher
                          DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              value: localeProv.locale.languageCode,
                              dropdownColor: const Color(0xFF312E81),
                              borderRadius: BorderRadius.circular(12),
                              icon: const SizedBox.shrink(),
                              isDense: true,
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                              items: const [
                                DropdownMenuItem(value: 'en', child: Text('EN')),
                                DropdownMenuItem(value: 'ar', child: Text('ع')),
                              ],
                              onChanged: (val) {
                                if (val != null) localeProv.setLocale(Locale(val));
                              },
                            ),
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () => _openProfile(context),
                            child: CircleAvatar(
                              radius: 18,
                              backgroundColor: Colors.white.withOpacity(0.15),
                              child: auth.isSignedIn
                                  ? Text(
                                      (auth.displayName?.isNotEmpty == true
                                              ? auth.displayName![0]
                                              : '?')
                                          .toUpperCase(),
                                      style: const TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                    )
                                  : const Icon(Icons.person_outline_rounded,
                                      color: Colors.white70, size: 18),
                            ),
                          ),
                        ],
                      ).animate().fadeIn(duration: 300.ms),

                      const SizedBox(height: 28),

                      // Hero flag + title
                      const Text('🚩', style: TextStyle(fontSize: 64))
                          .animate()
                          .scale(begin: const Offset(0.5, 0.5), duration: 500.ms, curve: Curves.elasticOut),

                      const SizedBox(height: 12),
                      Text(
                        _isLoading ? '...' : l10n.whatCountry,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.75),
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ).animate().fadeIn(delay: 150.ms),

                      const SizedBox(height: 6),
                      Text(
                        '${_allCountries.isEmpty ? '...' : _allCountries.length}+ flags',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.45),
                          fontSize: 12,
                        ),
                      ).animate().fadeIn(delay: 200.ms),

                      const SizedBox(height: 28),

                      // ── Big PLAY button ──────────────────────
                      _BigPlayButton(
                        label: l10n.play,
                        enabled: !_isLoading,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const PlaySetupPage()),
                        ),
                      ).animate().fadeIn(delay: 250.ms).slideY(begin: 0.2, end: 0, delay: 250.ms),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // ── Mode cards ───────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    l10n.gameModes,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.black54,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _ModeCard(
                        icon: Icons.bolt_rounded,
                        label: l10n.speedMode,
                        color: const Color(0xFFEF4444),
                        enabled: !_isLoading,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SpeedModePage(countries: _allCountries),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      _ModeCard(
                        icon: Icons.map_rounded,
                        label: l10n.battleMode,
                        color: AppColors.secondary,
                        enabled: !_isLoading,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => ContinentBattlePage(countries: _allCountries),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      _ModeCard(
                        icon: Icons.auto_stories_rounded,
                        label: l10n.learn,
                        color: AppColors.accent,
                        enabled: !_isLoading,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => LearnPage(countries: _allCountries),
                          ),
                        ),
                      ),
                    ],
                  ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1, end: 0, delay: 300.ms),
                ],
              ),
            ),
          ),

          // ── Review mistakes (if any) ─────────────────────────
          if (mp.hasMistakes && !_isLoading)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: _ReviewBanner(
                  count: mp.mistakenCca2s.length,
                  onTap: () => _startReview(context, mp),
                ).animate().fadeIn(delay: 350.ms).slideY(begin: 0.1, end: 0, delay: 350.ms),
              ),
            ),

          // ── Social row (auth-gated) ─────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Row(
                children: [
                  Expanded(
                    child: _SocialButton(
                      icon: Icons.leaderboard_rounded,
                      label: l10n.leaderboard,
                      color: AppColors.gold,
                      onTap: () => _requireAuth(context, () => const LeaderboardPage()),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _SocialButton(
                      icon: Icons.military_tech_rounded,
                      label: l10n.achievements,
                      color: const Color(0xFF14B8A6),
                      onTap: () => _requireAuth(context, () => const AchievementsPage()),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _SocialButton(
                      icon: Icons.wifi_rounded,
                      label: l10n.online,
                      color: const Color(0xFF10B981),
                      onTap: () => _requireAuth(
                        context,
                        () => MultiplayerLobbyPage(countries: _allCountries),
                      ),
                    ),
                  ),
                ],
              ).animate().fadeIn(delay: 380.ms).slideY(begin: 0.1, end: 0, delay: 380.ms),
            ),
          ),

          // ── Premium banner ──────────────────────────────────
          if (!ps.isPremium)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: _PremiumBanner(
                  onTap: () async {
                    await Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const PaywallPage()),
                    );
                  },
                ).animate().fadeIn(delay: 420.ms).slideY(begin: 0.1, end: 0, delay: 420.ms),
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
    );
  }
}

// ─── Big Play Button ──────────────────────────────────────────────────────────

class _BigPlayButton extends StatelessWidget {
  final String label;
  final bool enabled;
  final VoidCallback onTap;
  const _BigPlayButton({required this.label, required this.enabled, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: 200.ms,
        height: 64,
        decoration: BoxDecoration(
          color: enabled ? Colors.white : Colors.white38,
          borderRadius: BorderRadius.circular(20),
          boxShadow: enabled
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.play_arrow_rounded,
              color: enabled ? AppColors.primary : Colors.white54,
              size: 30,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: enabled ? AppColors.primary : Colors.white54,
                fontSize: 22,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Mode Card ────────────────────────────────────────────────────────────────

class _ModeCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool enabled;
  final VoidCallback onTap;
  const _ModeCard({
    required this.icon,
    required this.label,
    required this.color,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: enabled ? onTap : null,
        child: Container(
          height: 82,
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: color.withOpacity(0.12),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: enabled ? Colors.black87 : Colors.grey,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Social Button ────────────────────────────────────────────────────────────

class _SocialButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _SocialButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade100),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: Colors.black87,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Review Banner ────────────────────────────────────────────────────────────

class _ReviewBanner extends StatelessWidget {
  final int count;
  final VoidCallback onTap;
  const _ReviewBanner({required this.count, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.warning.withOpacity(0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.warning.withOpacity(0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.refresh_rounded, color: AppColors.warning, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '${AppLocalizations.of(context)!.reviewMistakes} ($count)',
                style: const TextStyle(
                  color: AppColors.warning,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded,
                color: AppColors.warning, size: 13),
          ],
        ),
      ),
    );
  }
}

// ─── Premium Banner ───────────────────────────────────────────────────────────

class _PremiumBanner extends StatelessWidget {
  final VoidCallback onTap;
  const _PremiumBanner({required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1A2E),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            const Icon(Icons.workspace_premium, color: AppColors.gold, size: 26),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.of(context)!.unlockAllFlags,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    AppLocalizations.of(context)!.oneTimePurchase,
                    style: const TextStyle(color: Colors.white38, fontSize: 11),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded,
                color: AppColors.gold, size: 13),
          ],
        ),
      ),
    );
  }
}
