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
  bool _moreExpanded = false;

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

  void _startReview(BuildContext context, MistakesProvider mp) {
    final l10n = AppLocalizations.of(context)!;
    final reviewList =
        _allCountries.where((c) => mp.mistakenCca2s.contains(c.cca2)).toList();
    if (reviewList.isEmpty) {
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
          countries: reviewList,
          config: GameConfig(
            mode: GameMode.quiz,
            questionCount: reviewList.length,
            choicesCount: 4,
            isReviewMode: true,
          ),
        ),
      ),
    );
  }

  void _openLoginOrProfile(BuildContext context) {
    final auth = context.read<AuthService>();
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) =>
            auth.isSignedIn ? const ProfilePage() : const LoginPage(),
      ),
    );
  }

  void _requireAuth(BuildContext context, Widget Function() builder) {
    final auth = context.read<AuthService>();
    if (!auth.isSignedIn) {
      Navigator.push(
          context, MaterialPageRoute(builder: (_) => const LoginPage()));
      return;
    }
    Navigator.push(context, MaterialPageRoute(builder: (_) => builder()));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final localeProv = Provider.of<LocaleProvider>(context);
    final mp = Provider.of<MistakesProvider>(context);
    final ps = Provider.of<PurchaseService>(context);
    final auth = Provider.of<AuthService>(context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // ── Top bar ──────────────────────────────────────────
            Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              child: Row(
                children: [
                  // App icon
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      gradient: AppColors.gradientPrimary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.public_rounded,
                        color: Colors.white, size: 22),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'GeoGuess',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                  const Spacer(),
                  // Language switcher
                  DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      value: localeProv.locale.languageCode,
                      borderRadius: BorderRadius.circular(12),
                      icon: const Icon(Icons.language_rounded,
                          size: 18, color: AppColors.primary),
                      isDense: true,
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
                  // Profile avatar
                  GestureDetector(
                    onTap: () => _openLoginOrProfile(context),
                    child: CircleAvatar(
                      radius: 18,
                      backgroundColor: AppColors.primary.withOpacity(0.1),
                      child: auth.isSignedIn
                          ? Text(
                              (auth.displayName?.isNotEmpty == true
                                      ? auth.displayName![0]
                                      : '?')
                                  .toUpperCase(),
                              style: const TextStyle(
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14),
                            )
                          : const Icon(Icons.person_outline_rounded,
                              color: AppColors.primary, size: 18),
                    ),
                  ),
                ],
              ),
            ).animate().fadeIn(duration: 300.ms),

            // ── Scrollable body ───────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Hero text
                    const SizedBox(height: 12),
                    Text(
                      '🚩',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 56),
                    ).animate().scale(
                          begin: const Offset(0.7, 0.7),
                          duration: 400.ms,
                          curve: Curves.elasticOut,
                        ),
                    const SizedBox(height: 8),
                    Text(
                      _isLoading ? '...' : l10n.whatCountry,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
                        color: Colors.grey.shade500,
                        fontWeight: FontWeight.w500,
                      ),
                    ).animate().fadeIn(delay: 100.ms),

                    const SizedBox(height: 28),

                    // ── Primary: Play button ──────────────────────
                    _PlayButton(
                      label: l10n.play,
                      enabled: !_isLoading,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const PlaySetupPage()),
                      ),
                    ).animate().fadeIn(delay: 150.ms).slideY(
                          begin: 0.15,
                          end: 0,
                          curve: Curves.easeOut,
                          delay: 150.ms,
                        ),

                    const SizedBox(height: 10),

                    // ── Secondary row: Learn + Review ─────────────
                    Row(
                      children: [
                        Expanded(
                          child: _SecondaryButton(
                            icon: Icons.auto_stories_rounded,
                            label: l10n.learn,
                            enabled: !_isLoading,
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (_) =>
                                      LearnPage(countries: _allCountries)),
                            ),
                          ),
                        ),
                        if (mp.hasMistakes && !_isLoading) ...[
                          const SizedBox(width: 10),
                          Expanded(
                            child: _SecondaryButton(
                              icon: Icons.refresh_rounded,
                              label:
                                  '${l10n.reviewMistakes} (${mp.mistakenCca2s.length})',
                              enabled: true,
                              color: AppColors.warning,
                              onTap: () => _startReview(context, mp),
                            ),
                          ),
                        ],
                      ],
                    )
                        .animate()
                        .fadeIn(delay: 220.ms)
                        .slideY(begin: 0.15, end: 0, delay: 220.ms),

                    const SizedBox(height: 24),

                    // ── Expandable: More Modes ────────────────────
                    _MoreModesSection(
                      expanded: _moreExpanded,
                      enabled: !_isLoading,
                      onToggle: () =>
                          setState(() => _moreExpanded = !_moreExpanded),
                      items: [
                        _ModeItem(
                          icon: Icons.bolt_rounded,
                          label: 'Speed Mode',
                          color: const Color(0xFFEF4444),
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) =>
                                  SpeedModePage(countries: _allCountries),
                            ),
                          ),
                        ),
                        _ModeItem(
                          icon: Icons.wifi_rounded,
                          label: 'Online Match',
                          color: const Color(0xFF10B981),
                          onTap: () => _requireAuth(
                            context,
                            () => MultiplayerLobbyPage(
                                countries: _allCountries),
                          ),
                        ),
                        _ModeItem(
                          icon: Icons.map_rounded,
                          label: 'Continent Battle',
                          color: AppColors.secondary,
                          onTap: () => Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => ContinentBattlePage(
                                  countries: _allCountries),
                            ),
                          ),
                        ),
                        _ModeItem(
                          icon: Icons.leaderboard_rounded,
                          label: 'Leaderboard',
                          color: AppColors.gold,
                          onTap: () => _requireAuth(
                            context,
                            () => const LeaderboardPage(),
                          ),
                        ),
                        _ModeItem(
                          icon: Icons.military_tech_rounded,
                          label: 'Achievements',
                          color: const Color(0xFF14B8A6),
                          onTap: () => _requireAuth(
                            context,
                            () => const AchievementsPage(),
                          ),
                        ),
                      ],
                    )
                        .animate()
                        .fadeIn(delay: 290.ms)
                        .slideY(begin: 0.1, end: 0, delay: 290.ms),

                    const SizedBox(height: 20),

                    // ── Premium banner ────────────────────────────
                    if (!ps.isPremium)
                      _PremiumBanner(
                        onTap: () async {
                          await Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const PaywallPage()),
                          );
                        },
                      )
                          .animate()
                          .fadeIn(delay: 350.ms)
                          .slideY(begin: 0.1, end: 0, delay: 350.ms),

                    const SizedBox(height: 24),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Play Button ──────────────────────────────────────────────────────────────

class _PlayButton extends StatelessWidget {
  final String label;
  final bool enabled;
  final VoidCallback onTap;

  const _PlayButton({
    required this.label,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: AnimatedContainer(
        duration: 200.ms,
        height: 62,
        decoration: BoxDecoration(
          gradient: enabled
              ? AppColors.gradientPrimary
              : const LinearGradient(
                  colors: [Color(0xFFD1D5DB), Color(0xFFD1D5DB)]),
          borderRadius: BorderRadius.circular(18),
          boxShadow: enabled
              ? [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 28),
            const SizedBox(width: 10),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Secondary Button ─────────────────────────────────────────────────────────

class _SecondaryButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool enabled;
  final Color color;
  final VoidCallback onTap;

  const _SecondaryButton({
    required this.icon,
    required this.label,
    required this.enabled,
    required this.onTap,
    this.color = AppColors.primary,
  });

  @override
  Widget build(BuildContext context) {
    final c = enabled ? color : Colors.grey.shade400;
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        height: 50,
        decoration: BoxDecoration(
          color: c.withOpacity(0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: c.withOpacity(0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: c, size: 20),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: c,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── More Modes Section ───────────────────────────────────────────────────────

class _ModeItem {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  const _ModeItem(
      {required this.icon,
      required this.label,
      required this.color,
      required this.onTap});
}

class _MoreModesSection extends StatelessWidget {
  final bool expanded;
  final bool enabled;
  final VoidCallback onToggle;
  final List<_ModeItem> items;

  const _MoreModesSection({
    required this.expanded,
    required this.enabled,
    required this.onToggle,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header / toggle
          InkWell(
            onTap: enabled ? onToggle : null,
            borderRadius: BorderRadius.circular(18),
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.grid_view_rounded,
                        color: AppColors.primary, size: 18),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'More Modes',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  AnimatedRotation(
                    turns: expanded ? 0.5 : 0,
                    duration: 250.ms,
                    child: const Icon(Icons.keyboard_arrow_down_rounded,
                        color: Colors.grey),
                  ),
                ],
              ),
            ),
          ),

          // Expandable list
          AnimatedSize(
            duration: 280.ms,
            curve: Curves.easeInOut,
            child: expanded
                ? Column(
                    children: [
                      Divider(
                          height: 1, color: Colors.grey.shade100, indent: 18, endIndent: 18),
                      ...items.asMap().entries.map((e) {
                        final i = e.key;
                        final item = e.value;
                        return _ModeRow(item: item)
                            .animate()
                            .fadeIn(
                              delay: Duration(milliseconds: 40 * i),
                              duration: 200.ms,
                            )
                            .slideX(
                              begin: -0.05,
                              end: 0,
                              delay: Duration(milliseconds: 40 * i),
                            );
                      }),
                      const SizedBox(height: 6),
                    ],
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}

class _ModeRow extends StatelessWidget {
  final _ModeItem item;
  const _ModeRow({required this.item});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: item.onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: item.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(item.icon, color: item.color, size: 20),
            ),
            const SizedBox(width: 14),
            Text(
              item.label,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const Spacer(),
            Icon(Icons.arrow_forward_ios_rounded,
                size: 13, color: Colors.grey.shade400),
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
            const Icon(Icons.workspace_premium,
                color: AppColors.gold, size: 28),
            const SizedBox(width: 12),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Unlock All 250+ Flags',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'One-time purchase',
                    style: TextStyle(color: Colors.white54, fontSize: 12),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded,
                color: AppColors.gold, size: 14),
          ],
        ),
      ),
    );
  }
}
