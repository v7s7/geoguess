import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../models/user_profile.dart';
import '../services/auth_service.dart';
import '../services/sound_service.dart';
import '../services/user_service.dart';
import '../theme/app_theme.dart';

class ProfilePage extends StatefulWidget {
  const ProfilePage({super.key});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  UserProfile? _profile;
  bool _loading = true;
  bool _sound = true;
  bool _haptic = true;

  @override
  void initState() {
    super.initState();
    _sound = SoundService().soundEnabled;
    _haptic = SoundService().hapticEnabled;
    _load();
  }

  Future<void> _load() async {
    final uid = context.read<AuthService>().uid;
    if (uid == null) { setState(() => _loading = false); return; }
    final p = await UserService().getProfile(uid);
    if (mounted) setState(() { _profile = p; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthService>();

    return Scaffold(
      body: Column(
        children: [
          // Header
          Container(
            decoration: const BoxDecoration(gradient: AppColors.gradientPrimary),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 16, 28),
                child: Column(
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const Text('Profile', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 12),
                    // Avatar + name
                    CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.white.withOpacity(0.2),
                      child: Text(
                        _profile?.username.isNotEmpty == true
                            ? _profile!.username[0].toUpperCase()
                            : '?',
                        style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
                      ),
                    ).animate().scale(duration: 500.ms, curve: Curves.elasticOut),
                    const SizedBox(height: 10),
                    Text(
                      _profile?.username ?? auth.displayName ?? 'Player',
                      style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      auth.currentUser?.email ?? '',
                      style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
          ),

          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Stats
                        Row(
                          children: [
                            _StatBox('Games', '${_profile?.gamesPlayed ?? 0}', Icons.sports_esports_rounded, AppColors.primary),
                            const SizedBox(width: 10),
                            _StatBox('Wins', '${_profile?.gamesWon ?? 0}', Icons.emoji_events_rounded, Colors.amber),
                            const SizedBox(width: 10),
                            _StatBox('🔥 Streak', '${_profile?.streak ?? 0}', Icons.local_fire_department_rounded, AppColors.warning),
                          ],
                        ),

                        const SizedBox(height: 10),
                        Row(
                          children: [
                            _StatBox('Score', '${_profile?.totalScore ?? 0}', Icons.star_rounded, AppColors.secondary),
                            const SizedBox(width: 10),
                            _StatBox('Speed HS', '${_profile?.speedHighScore ?? 0}', Icons.bolt, AppColors.error),
                            const SizedBox(width: 10),
                            _StatBox('Badges', '${_profile?.achievements.length ?? 0}', Icons.military_tech_rounded, AppColors.success),
                          ],
                        ),

                        const SizedBox(height: 24),

                        _SectionTitle('Settings'),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8)],
                          ),
                          child: Column(
                            children: [
                              SwitchListTile(
                                value: _sound,
                                onChanged: (v) {
                                  setState(() => _sound = v);
                                  SoundService().soundEnabled = v;
                                },
                                title: const Text('Sound Effects', style: TextStyle(fontWeight: FontWeight.w600)),
                                secondary: Container(
                                  width: 36, height: 36,
                                  decoration: BoxDecoration(color: AppColors.primary.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                                  child: const Icon(Icons.volume_up_rounded, color: AppColors.primary, size: 20),
                                ),
                                activeColor: AppColors.primary,
                              ),
                              const Divider(height: 1, indent: 16),
                              SwitchListTile(
                                value: _haptic,
                                onChanged: (v) {
                                  setState(() => _haptic = v);
                                  SoundService().hapticEnabled = v;
                                },
                                title: const Text('Haptic Feedback', style: TextStyle(fontWeight: FontWeight.w600)),
                                secondary: Container(
                                  width: 36, height: 36,
                                  decoration: BoxDecoration(color: AppColors.secondary.withOpacity(0.1), borderRadius: BorderRadius.circular(10)),
                                  child: const Icon(Icons.vibration_rounded, color: AppColors.secondary, size: 20),
                                ),
                                activeColor: AppColors.primary,
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 24),

                        // Sign out
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              await context.read<AuthService>().signOut();
                              if (mounted) Navigator.of(context).pop();
                            },
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.error,
                              side: const BorderSide(color: AppColors.error),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            icon: const Icon(Icons.logout_rounded),
                            label: const Text('Sign Out', style: TextStyle(fontWeight: FontWeight.bold)),
                          ),
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

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: 12),
    child: Text(text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
  );
}

class _StatBox extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _StatBox(this.label, this.value, this.icon, this.color);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)],
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 22),
            const SizedBox(height: 6),
            Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
            Text(label, style: TextStyle(fontSize: 10, color: Colors.grey.shade500), textAlign: TextAlign.center),
          ],
        ),
      ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0),
    );
  }
}
