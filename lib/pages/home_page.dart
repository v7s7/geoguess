import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:provider/provider.dart';
import 'package:geoguess_flags/l10n/app_localizations.dart';
import '../app.dart';
import '../models/country.dart';
import '../models/daily_quest.dart';
import '../models/game_config.dart';
import '../models/user_profile.dart';
import '../services/auth_service.dart';
import '../services/country_api.dart';
import '../services/friends_service.dart';
import '../services/mistakes_provider.dart';
import '../services/user_service.dart';
import '../theme/app_theme.dart';
import 'play_setup_page.dart';
import 'game_page.dart';
import 'learn_page.dart';
import 'speed_mode_page.dart';
import 'continent_battle_page.dart';
import 'leaderboard_page.dart';
import 'achievements_page.dart';
import 'profile_page.dart';
import 'auth/login_page.dart';
import 'online/multiplayer_lobby_page.dart';
import 'online/friends_page.dart';
import 'online/multiplayer_game_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Country> _allCountries = [];
  bool _isLoading = true;
  bool _loadFailed = false;

  // Challenge listener
  StreamSubscription<List<GameChallenge>>? _challengeSub;
  String? _listeningUid;
  final Set<String> _shownChallengeIds = {};

  // Daily quests
  UserProfile? _userProfile;
  StreamSubscription<UserProfile?>? _profileSub;
  final List<DailyQuest> _todayQuests = QuestDefinitions.getForToday();

  @override
  void initState() {
    super.initState();
    _preloadData();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<AuthService>().addListener(_onAuthChanged);
      _setupChallengeListener();
      _setupProfileListener();
    });
  }

  @override
  void dispose() {
    context.read<AuthService>().removeListener(_onAuthChanged);
    _challengeSub?.cancel();
    _profileSub?.cancel();
    super.dispose();
  }

  void _onAuthChanged() {
    _setupChallengeListener();
    _setupProfileListener();
  }

  void _setupProfileListener() {
    if (!mounted) return;
    final uid = context.read<AuthService>().uid;
    if (uid == null) return;
    _profileSub?.cancel();
    _profileSub = UserService().watchProfile(uid).listen(
      (p) { if (mounted) setState(() => _userProfile = p); },
      onError: (_) {}, // ignore transient Firestore errors; retried automatically
    );
  }

  void _setupChallengeListener() {
    if (!mounted) return;
    final auth = context.read<AuthService>();
    final uid = auth.uid;
    if (uid == _listeningUid) return;
    _challengeSub?.cancel();
    _listeningUid = uid;
    if (uid == null) return;
    _challengeSub = FriendsService().watchIncomingChallenges(uid).listen(
      (challenges) {
        for (final c in challenges) {
          if (_shownChallengeIds.contains(c.id)) continue;
          _shownChallengeIds.add(c.id);
          if (mounted) _showChallengeDialog(c);
        }
      },
      onError: (_) {}, // challenges index may not be deployed yet; fail silently
    );
  }

  Future<void> _showChallengeDialog(GameChallenge challenge) async {
    if (!mounted) return;
    final accepted = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _ChallengeDialog(challengerName: challenge.fromUsername),
    );

    final service = FriendsService();
    if (accepted == true && mounted) {
      final auth = context.read<AuthService>();
      final uid = auth.uid;
      if (uid == null) return;
      try {
        final roomId = await service.acceptChallenge(
          challengeId: challenge.id,
          challengerUid: challenge.fromUid,
          challengerName: challenge.fromUsername,
          acceptorUid: uid,
          acceptorName: auth.displayName ?? 'Player',
          flagCodes: challenge.flagCodes,
        );
        if (mounted) {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => MultiplayerGamePage(
                countries: _allCountries,
                roomId: roomId,
                isPlayer1: false,
              ),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Failed to start game: $e'), behavior: SnackBarBehavior.floating),
          );
        }
      }
    } else if (accepted == false) {
      service.declineChallenge(challenge.id);
    }
  }

  Future<void> _preloadData() async {
    setState(() { _isLoading = true; _loadFailed = false; });
    try {
      final countries = await CountryApi().fetchCountries();
      if (mounted) {
        setState(() {
          _allCountries = countries;
          _isLoading = false;
        });
        _preloadFlags(countries);
      }
    } catch (_) {
      if (mounted) setState(() { _isLoading = false; _loadFailed = true; });
    }
  }

  void _preloadFlags(List<Country> countries) {
    if (!mounted) return;
    // Shuffle so we don't always preload the same flags
    final shuffled = List<Country>.from(countries)..shuffle();
    for (final country in shuffled.take(40)) {
      precacheImage(CachedNetworkImageProvider(country.flagUrl), context);
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
    final l10n = AppLocalizations.of(context);
    debugPrint('[GeoGuess][HomePage] build called, l10n=${l10n != null ? "OK" : "NULL"}');
    if (l10n == null) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator()),
      );
    }
    final localeProv = Provider.of<LocaleProvider>(context);
    final mp = Provider.of<MistakesProvider>(context);
    final auth = Provider.of<AuthService>(context);

    return Scaffold(
      backgroundColor: AppColors.background,
      body: KeyedSubtree(
        key: ValueKey(localeProv.locale.languageCode),
        child: CustomScrollView(
        slivers: [
          // ── Gradient hero header ──────────────────────────────
          SliverToBoxAdapter(
            child: Container(
              decoration: const BoxDecoration(
                gradient: AppColors.gradientHero,
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
              ),
              clipBehavior: Clip.antiAlias,
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
                          // GeoCoins balance (shown when signed in)
                          if (auth.isSignedIn && _userProfile != null) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Text('🪙', style: TextStyle(fontSize: 12)),
                                  const SizedBox(width: 3),
                                  Text(
                                    '${_userProfile!.geoCoins}',
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 6),
                          ],
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
                      ),

                      const SizedBox(height: 28),

                      // Hero flag + title
                      const Text('🚩', style: TextStyle(fontSize: 64)),

                      const SizedBox(height: 12),
                      Text(
                        _isLoading || _loadFailed ? '...' : l10n.whatCountry,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.75),
                          fontSize: 15,
                          fontWeight: FontWeight.w500,
                        ),
                      ),

                      const SizedBox(height: 6),
                      Text(
                        '${_allCountries.isEmpty ? '...' : _allCountries.length}+ flags',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.45),
                          fontSize: 12,
                        ),
                      ),

                      const SizedBox(height: 28),

                      // ── Big PLAY button ──────────────────────
                      _BigPlayButton(
                        label: l10n.play,
                        enabled: !_isLoading && !_loadFailed,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const PlaySetupPage()),
                        ),
                      ),
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
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
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
                        enabled: !_isLoading && !_loadFailed,
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
                        enabled: !_isLoading && !_loadFailed,
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
                        enabled: !_isLoading && !_loadFailed,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => LearnPage(countries: _allCountries),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // ── Retry banner (shown when countries failed to load) ──
          if (_loadFailed)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.errorLight,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.error.withOpacity(0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.wifi_off_rounded, color: AppColors.error, size: 18),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          l10n.error,
                          style: const TextStyle(color: AppColors.error, fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _preloadData,
                        icon: const Icon(Icons.refresh_rounded, size: 16),
                        label: Text(l10n.retry),
                        style: TextButton.styleFrom(foregroundColor: AppColors.error),
                      ),
                    ],
                  ),
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
                ),
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
                  const SizedBox(width: 8),
                  Expanded(
                    child: _SocialButton(
                      icon: Icons.military_tech_rounded,
                      label: l10n.achievements,
                      color: const Color(0xFF14B8A6),
                      onTap: () => _requireAuth(context, () => const AchievementsPage()),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _SocialButton(
                      icon: Icons.people_rounded,
                      label: 'Friends',
                      color: const Color(0xFFEC4899),
                      onTap: () => _requireAuth(
                        context,
                        () => FriendsPage(countries: _allCountries),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
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
              ),
            ),
          ),

          // ── Daily Quests section ─────────────────────────────
          if (auth.isSignedIn)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: _DailyQuestsCard(
                  quests: _todayQuests,
                  profile: _userProfile,
                ),
              ),
            ),

          const SliverToBoxAdapter(child: SizedBox(height: 32)),
        ],
      ),
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
        duration: const Duration(milliseconds: 200),
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

// ─── Challenge Dialog ─────────────────────────────────────────────────────────

class _ChallengeDialog extends StatelessWidget {
  final String challengerName;
  const _ChallengeDialog({required this.challengerName});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: const Color(0xFF1E1B4B),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
                ),
              ),
              child: const Icon(Icons.sports_esports_rounded, color: Colors.white, size: 36),
            ),
            const SizedBox(height: 16),
            const Text(
              'Challenge!',
              style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 8),
            RichText(
              textAlign: TextAlign.center,
              text: TextSpan(
                style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 14, height: 1.5),
                children: [
                  TextSpan(
                    text: challengerName,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                  const TextSpan(text: ' is challenging you to a 20-flag showdown!'),
                ],
              ),
            ),
            const SizedBox(height: 28),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context, false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white60,
                      side: const BorderSide(color: Colors.white24),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: const Text('Decline', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4F46E5),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      elevation: 0,
                    ),
                    child: const Text('Accept!', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Daily Quests Card ────────────────────────────────────────────────────────

class _DailyQuestsCard extends StatelessWidget {
  final List<DailyQuest> quests;
  final UserProfile? profile;

  const _DailyQuestsCard({required this.quests, required this.profile});

  @override
  Widget build(BuildContext context) {
    final questProgress = profile?.questProgress ?? {};

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 6),
            child: Row(
              children: [
                Container(
                  width: 32, height: 32,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Center(child: Text('⚔️', style: TextStyle(fontSize: 16))),
                ),
                const SizedBox(width: 10),
                const Text('Daily Quests', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Text('Today', style: TextStyle(fontSize: 11, color: Color(0xFFF59E0B), fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Quest items
          ...quests.asMap().entries.map((e) {
            final quest = e.value;
            final progress = questProgress[quest.id] ?? 0;
            final isCompleted = progress >= quest.target;
            final pct = (progress / quest.target).clamp(0.0, 1.0);

            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(quest.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                            Text(quest.description, style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.55))),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Coins reward
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: isCompleted
                              ? AppColors.success.withOpacity(0.1)
                              : const Color(0xFFF59E0B).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('🪙', style: TextStyle(fontSize: 10)),
                            const SizedBox(width: 3),
                            Text(
                              '${quest.rewardCoins}',
                              style: TextStyle(
                                color: isCompleted ? AppColors.success : const Color(0xFFF59E0B),
                                fontWeight: FontWeight.bold,
                                fontSize: 11,
                              ),
                            ),
                            if (isCompleted) ...[
                              const SizedBox(width: 3),
                              Icon(Icons.check_circle_rounded, color: AppColors.success, size: 12),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  // Progress bar
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: pct,
                            backgroundColor: Theme.of(context).colorScheme.outlineVariant,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              isCompleted ? AppColors.success : AppColors.primary,
                            ),
                            minHeight: 6,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '$progress/${quest.target}',
                        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6)),
                      ),
                    ],
                  ),
                  if (e.key < quests.length - 1)
                    const Padding(padding: EdgeInsets.only(top: 8), child: Divider(height: 1)),
                ],
              ),
            );
          }),
          const SizedBox(height: 10),
        ],
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

