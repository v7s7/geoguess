import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../models/achievement.dart';
import '../models/user_profile.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../theme/app_theme.dart';

class AchievementsPage extends StatefulWidget {
  const AchievementsPage({super.key});

  @override
  State<AchievementsPage> createState() => _AchievementsPageState();
}

class _AchievementsPageState extends State<AchievementsPage> {
  UserProfile? _profile;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
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
    final unlocked = _profile?.achievements ?? [];
    final total = Achievements.all.length;
    final count = unlocked.length;

    return Scaffold(
      body: Column(
        children: [
          // Header
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [Color(0xFF7C3AED), Color(0xFF4F46E5)]),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 16, 20),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('🎖 Achievements', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text('$count / $total', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Progress bar
          if (!_loading)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Progress', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
                      Text('${(count / total * 100).toInt()}%', style: const TextStyle(color: AppColors.secondary, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: count / total),
                    duration: const Duration(milliseconds: 800),
                    curve: Curves.easeOut,
                    builder: (_, v, __) => ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(value: v, backgroundColor: Colors.grey.shade200, valueColor: const AlwaysStoppedAnimation(AppColors.secondary), minHeight: 8),
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 16),

          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : GridView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.9,
                    ),
                    itemCount: Achievements.all.length,
                    itemBuilder: (context, i) {
                      final a = Achievements.all[i];
                      final done = unlocked.contains(a.id);
                      return _AchievementCard(a: a, unlocked: done, delay: i * 60);
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _AchievementCard extends StatelessWidget {
  final Achievement a;
  final bool unlocked;
  final int delay;
  const _AchievementCard({required this.a, required this.unlocked, required this.delay});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _showDetails(context),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: unlocked ? a.color.withOpacity(0.08) : Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: unlocked ? a.color.withOpacity(0.4) : Colors.grey.shade200,
            width: unlocked ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: (unlocked ? a.color : Colors.black).withOpacity(0.06),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Badge
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 58, height: 58,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: unlocked ? a.color.withOpacity(0.15) : Colors.grey.shade100,
                    border: Border.all(
                      color: unlocked ? a.color.withOpacity(0.4) : Colors.grey.shade300,
                      width: 2,
                    ),
                  ),
                ),
                Icon(
                  a.icon,
                  size: 28,
                  color: unlocked ? a.color : Colors.grey.shade400,
                ),
                if (!unlocked)
                  Positioned(
                    bottom: 0, right: 0,
                    child: Container(
                      width: 20, height: 20,
                      decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.grey.shade300, border: Border.all(color: Colors.white, width: 2)),
                      child: const Icon(Icons.lock_rounded, size: 11, color: Colors.white),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              a.title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: unlocked ? Colors.black87 : Colors.grey.shade400,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            if (unlocked) ...[
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: a.color,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Text('Unlocked!', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
              ),
            ],
          ],
        ),
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: delay), duration: 350.ms).scale(begin: const Offset(0.9, 0.9), end: const Offset(1, 1));
  }

  void _showDetails(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 50, height: 5, decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(3))),
            const SizedBox(height: 24),
            Container(
              width: 72, height: 72,
              decoration: BoxDecoration(shape: BoxShape.circle, color: (unlocked ? a.color : Colors.grey.shade300).withOpacity(0.15)),
              child: Icon(a.icon, size: 36, color: unlocked ? a.color : Colors.grey.shade400),
            ),
            const SizedBox(height: 16),
            Text(a.title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(a.description, style: TextStyle(fontSize: 15, color: Colors.grey.shade600), textAlign: TextAlign.center),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: (unlocked ? AppColors.success : Colors.grey.shade300).withOpacity(0.15),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                unlocked ? '✅ Unlocked' : '🔒 Locked',
                style: TextStyle(
                  color: unlocked ? AppColors.success : Colors.grey,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
