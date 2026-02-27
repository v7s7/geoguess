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
        SnackBar(
          content: Text(l10n.noMistakes),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
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

  void _openLoginOrProfile(BuildContext context) {
    final auth = context.read<AuthService>();
    if (auth.isSignedIn) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const ProfilePage()));
    } else {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginPage()));
    }
  }

  void _requireAuth(BuildContext context, Widget Function() builder) {
    final auth = context.read<AuthService>();
    if (!auth.isSignedIn) {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const LoginPage()));
      return;
    }
    Navigator.push(context, MaterialPageRoute(builder: (_) => builder()));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final localeProv = Provider.of<LocaleProvider>(context);
    final mistakesProv = Provider.of<MistakesProvider>(context);
    final ps = Provider.of<PurchaseService>(context);
    final auth = Provider.of<AuthService>(context);

    return Scaffold(
      body: Column(
        children: [
          _HeroHeader(
            isPremium: ps.isPremium,
            isLoading: _isLoading,
            isSignedIn: auth.isSignedIn,
            displayName: auth.displayName,
            onProfileTap: () => _openLoginOrProfile(context),
          ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Action Cards Row (Play + Learn)
                  Row(
                    children: [
                      Expanded(
                        child: _ActionCard(
                          icon: Icons.play_circle_fill_rounded,
                          label: l10n.play,
                          subtitle: 'Quiz your flag skills',
                          gradient: AppColors.gradientPrimary,
                          delay: 100,
                          onTap: _isLoading
                              ? null
                              : () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) => const PlaySetupPage()),
                                  ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _ActionCard(
                          icon: Icons.auto_stories_rounded,
                          label: l10n.learn,
                          subtitle: 'Explore all flags',
                          gradient: const LinearGradient(
                            colors: [Color(0xFF0891B2), Color(0xFF06B6D4)],
                          ),
                          delay: 200,
                          onTap: _isLoading
                              ? null
                              : () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                        builder: (_) => LearnPage(
                                            countries: _allCountries)),
                                  ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Online Modes Row
                  Row(
                    children: [
                      Expanded(
                        child: _ActionCard(
                          icon: Icons.wifi_rounded,
                          label: 'Online Match',
                          subtitle: 'Play vs a stranger',
                          gradient: const LinearGradient(
                            colors: [Color(0xFF059669), Color(0xFF10B981)],
                          ),
                          delay: 250,
                          onTap: _isLoading
                              ? null
                              : () => _requireAuth(
                                    context,
                                    () => MultiplayerLobbyPage(
                                        countries: _allCountries),
                                  ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _ActionCard(
                          icon: Icons.bolt_rounded,
                          label: 'Speed Mode',
                          subtitle: '60-second sprint',
                          gradient: const LinearGradient(
                            colors: [Color(0xFFDC2626), Color(0xFFEF4444)],
                          ),
                          delay: 300,
                          onTap: _isLoading
                              ? null
                              : () => Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (_) => SpeedModePage(
                                          countries: _allCountries),
                                    ),
                                  ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Continent Battle (full width)
                  _WideCard(
                    icon: Icons.map_rounded,
                    label: 'Continent Battle',
                    subtitle: 'Conquer Africa, Europe, Asia & more',
                    gradient: const LinearGradient(
                      colors: [Color(0xFF7C3AED), Color(0xFF8B5CF6)],
                    ),
                    delay: 350,
                    onTap: _isLoading
                        ? null
                        : () => Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => ContinentBattlePage(
                                    countries: _allCountries),
                              ),
                            ),
                  ),

                  const SizedBox(height: 12),

                  // Stats Row: Leaderboard + Achievements
                  Row(
                    children: [
                      Expanded(
                        child: _ActionCard(
                          icon: Icons.leaderboard_rounded,
                          label: 'Leaderboard',
                          subtitle: 'Top players',
                          gradient: const LinearGradient(
                            colors: [Color(0xFFD97706), Color(0xFFF59E0B)],
                          ),
                          delay: 400,
                          onTap: () => _requireAuth(
                            context,
                            () => const LeaderboardPage(),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _ActionCard(
                          icon: Icons.military_tech_rounded,
                          label: 'Achievements',
                          subtitle: 'Unlock badges',
                          gradient: const LinearGradient(
                            colors: [Color(0xFF0F766E), Color(0xFF14B8A6)],
                          ),
                          delay: 450,
                          onTap: () => _requireAuth(
                            context,
                            () => const AchievementsPage(),
                          ),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 12),

                  // Review Mistakes Card
                  _ReviewCard(
                    mistakesCount: mistakesProv.mistakenCca2s.length,
                    hasMistakes: mistakesProv.hasMistakes && !_isLoading,
                    label: l10n.reviewMistakes,
                    delay: 500,
                    onTap: () => _startReview(context, mistakesProv),
                  ),

                  const SizedBox(height: 12),

                  // Premium Card
                  if (!ps.isPremium)
                    _PremiumBannerCard(
                      delay: 550,
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const PaywallPage()),
                        );
                      },
                    ),

                  if (ps.isPremium) _PremiumActiveCard(delay: 550),

                  const SizedBox(height: 20),

                  // Language Card
                  _SettingsCard(
                    localeProv: localeProv,
                    label: l10n.language,
                    delay: 600,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Hero Header ─────────────────────────────────────────────────────────────

class _WideCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Gradient gradient;
  final int delay;
  final VoidCallback? onTap;

  const _WideCard({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.gradient,
    required this.delay,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.15),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Icon(icon, color: Colors.white, size: 32),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.bold)),
                  Text(subtitle,
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.75), fontSize: 12)),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded,
                color: Colors.white70, size: 16),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(delay: Duration(milliseconds: delay), duration: 400.ms)
        .slideY(begin: 0.2, end: 0, curve: Curves.easeOut);
  }
}

// ─── Hero Header ─────────────────────────────────────────────────────────────

class _HeroHeader extends StatelessWidget {
  final bool isPremium;
  final bool isLoading;
  final bool isSignedIn;
  final String? displayName;
  final VoidCallback onProfileTap;

  const _HeroHeader({
    required this.isPremium,
    required this.isLoading,
    required this.isSignedIn,
    required this.displayName,
    required this.onProfileTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: AppColors.gradientHero,
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.public_rounded,
                        color: Colors.white, size: 28),
                  ),
                  Row(
                    children: [
                      if (isPremium)
                        Container(
                          margin: const EdgeInsets.only(right: 8),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                            ),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.workspace_premium,
                                  color: Colors.white, size: 14),
                              SizedBox(width: 4),
                              Text(
                                'PREMIUM',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 1,
                                ),
                              ),
                            ],
                          ),
                        ),
                      GestureDetector(
                        onTap: onProfileTap,
                        child: CircleAvatar(
                          radius: 20,
                          backgroundColor: Colors.white.withOpacity(0.2),
                          child: isSignedIn
                              ? Text(
                                  (displayName?.isNotEmpty == true
                                          ? displayName![0]
                                          : '?')
                                      .toUpperCase(),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                )
                              : const Icon(Icons.person_outline_rounded,
                                  color: Colors.white, size: 20),
                        ),
                      ),
                    ],
                  ),
                ],
              )
                  .animate()
                  .fadeIn(duration: 400.ms)
                  .slideY(begin: -0.2, end: 0),
              const SizedBox(height: 20),
              const Text(
                'GeoGuess',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white60,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 3,
                ),
              ).animate().fadeIn(delay: 100.ms),
              const Text(
                'Flags',
                style: TextStyle(
                  fontSize: 40,
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  height: 1.0,
                ),
              ).animate().fadeIn(delay: 150.ms).slideX(begin: -0.1, end: 0),
              const SizedBox(height: 8),
              Text(
                isLoading
                    ? 'Loading countries...'
                    : 'Test your world flags knowledge!',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.white.withOpacity(0.75),
                ),
              ).animate().fadeIn(delay: 200.ms),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Action Card ─────────────────────────────────────────────────────────────

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final Gradient gradient;
  final int delay;
  final VoidCallback? onTap;

  const _ActionCard({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.gradient,
    required this.delay,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: onTap == null
              ? const LinearGradient(colors: [Colors.grey, Colors.blueGrey])
              : gradient,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withOpacity(0.25),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: Colors.white, size: 32),
            const SizedBox(height: 12),
            Text(
              label,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(
                color: Colors.white.withOpacity(0.75),
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(delay: Duration(milliseconds: delay), duration: 400.ms)
        .slideY(begin: 0.2, end: 0, curve: Curves.easeOut);
  }
}

// ─── Review Card ─────────────────────────────────────────────────────────────

class _ReviewCard extends StatelessWidget {
  final int mistakesCount;
  final bool hasMistakes;
  final String label;
  final int delay;
  final VoidCallback onTap;

  const _ReviewCard({
    required this.mistakesCount,
    required this.hasMistakes,
    required this.label,
    required this.delay,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: hasMistakes ? onTap : null,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: hasMistakes
                ? AppColors.warning.withOpacity(0.4)
                : Colors.grey.shade200,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 12,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: hasMistakes
                    ? AppColors.warning.withOpacity(0.12)
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(
                Icons.refresh_rounded,
                color: hasMistakes ? AppColors.warning : Colors.grey,
                size: 26,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: hasMistakes
                          ? Colors.black87
                          : Colors.grey.shade400,
                    ),
                  ),
                  Text(
                    hasMistakes
                        ? '$mistakesCount flag(s) to review'
                        : 'No mistakes yet — great job!',
                    style: TextStyle(
                      fontSize: 12,
                      color: hasMistakes
                          ? AppColors.warning
                          : Colors.grey.shade400,
                    ),
                  ),
                ],
              ),
            ),
            if (hasMistakes)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  '$mistakesCount',
                  style: const TextStyle(
                    color: AppColors.warning,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(delay: Duration(milliseconds: delay), duration: 400.ms)
        .slideY(begin: 0.2, end: 0);
  }
}

// ─── Premium Banner Card ──────────────────────────────────────────────────────

class _PremiumBannerCard extends StatelessWidget {
  final int delay;
  final VoidCallback onTap;

  const _PremiumBannerCard({required this.delay, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1A1A2E), Color(0xFF0F3460)],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.2),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.gold.withOpacity(0.4),
                    blurRadius: 12,
                  ),
                ],
              ),
              child: const Icon(Icons.workspace_premium,
                  color: Colors.white, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Unlock All 250+ Flags',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'One-time purchase — play forever',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded,
                color: Colors.amber, size: 16),
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(delay: Duration(milliseconds: delay), duration: 400.ms)
        .slideY(begin: 0.2, end: 0);
  }
}

// ─── Premium Active Card ──────────────────────────────────────────────────────

class _PremiumActiveCard extends StatelessWidget {
  final int delay;
  const _PremiumActiveCard({required this.delay});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: const Row(
        children: [
          Icon(Icons.workspace_premium, color: Colors.white, size: 28),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'You have Premium!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  'All 250+ flags are unlocked 🌍',
                  style: TextStyle(color: Colors.white70, fontSize: 12),
                ),
              ],
            ),
          ),
          Icon(Icons.check_circle, color: Colors.white, size: 24),
        ],
      ),
    )
        .animate()
        .fadeIn(delay: Duration(milliseconds: delay))
        .slideY(begin: 0.2, end: 0);
  }
}

// ─── Settings Card ────────────────────────────────────────────────────────────

class _SettingsCard extends StatelessWidget {
  final LocaleProvider localeProv;
  final String label;
  final int delay;

  const _SettingsCard({
    required this.localeProv,
    required this.label,
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.language_rounded,
              color: AppColors.primary, size: 22),
        ),
        title: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
        ),
        trailing: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: localeProv.locale.languageCode,
            borderRadius: BorderRadius.circular(12),
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
    ).animate().fadeIn(delay: Duration(milliseconds: delay), duration: 400.ms);
  }
}
