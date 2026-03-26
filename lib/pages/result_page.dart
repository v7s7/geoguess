import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:geoguess_flags/l10n/app_localizations.dart';
import '../models/achievement.dart';
import '../theme/app_theme.dart';

class ResultPage extends StatelessWidget {
  final int score;
  final int playedQuestions;
  final int totalQuestions;
  final int correctAnswers;
  final int maxStreak;
  final List<String> newlyUnlockedAchievements;
  final String? continentName;
  final int? continentEarnedStars;
  final void Function(BuildContext context)? onPlayAgain;

  const ResultPage({
    super.key,
    required this.score,
    required this.totalQuestions,
    required this.playedQuestions,
    this.correctAnswers = 0,
    this.maxStreak = 0,
    this.newlyUnlockedAchievements = const [],
    this.continentName,
    this.continentEarnedStars,
    this.onPlayAgain,
  });

  double get _accuracy =>
      playedQuestions > 0 ? correctAnswers / playedQuestions : 0.0;

  int get _stars {
    if (_accuracy >= 0.9) return 3;
    if (_accuracy >= 0.6) return 2;
    if (_accuracy >= 0.3) return 1;
    return 0;
  }

  String _getMessage(AppLocalizations l10n) {
    if (_accuracy >= 0.9) return l10n.outstanding;
    if (_accuracy >= 0.6) return l10n.greatJob;
    if (_accuracy >= 0.3) return l10n.goodEffort;
    return l10n.keepPracticing;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final pct = (_accuracy * 100).toInt();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1E1B4B), Color(0xFF312E81), Color(0xFFF0F4FF)],
            stops: [0.0, 0.3, 0.55],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // ── Trophy area ──────────────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
                child: Column(
                  children: [
                    // Stars
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(3, (i) {
                        final filled = i < _stars;
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 5),
                          child: Icon(
                            filled ? Icons.star_rounded : Icons.star_outline_rounded,
                            color: filled ? Colors.amber : Colors.white24,
                            size: 40,
                          )
                              .animate()
                              .scale(
                                delay: Duration(milliseconds: 150 + i * 150),
                                duration: 450.ms,
                                curve: Curves.elasticOut,
                              )
                              .fadeIn(delay: Duration(milliseconds: 150 + i * 150)),
                        );
                      }),
                    ),

                    const SizedBox(height: 18),

                    Text(
                      l10n.gameOver,
                      style: const TextStyle(
                        fontSize: 13,
                        color: Colors.white54,
                        letterSpacing: 2.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ).animate().fadeIn(delay: 100.ms),

                    const SizedBox(height: 6),

                    Text(
                      '$score',
                      style: const TextStyle(
                        fontSize: 76,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        height: 1.0,
                      ),
                    )
                        .animate()
                        .fadeIn(delay: 200.ms, duration: 600.ms)
                        .slideY(begin: 0.25, end: 0, curve: Curves.easeOut),

                    Text(
                      l10n.finalScore,
                      style: const TextStyle(fontSize: 14, color: Colors.white60),
                    ).animate().fadeIn(delay: 300.ms),

                    const SizedBox(height: 8),

                    Text(
                      _getMessage(l10n),
                      style: const TextStyle(
                        fontSize: 18,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ).animate().fadeIn(delay: 400.ms),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // ── Stats panel ──────────────────────────────
              Expanded(
                child: Container(
                  padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                  decoration: const BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(36)),
                  ),
                  child: Column(
                    children: [
                      // Top stat row
                      Row(
                        children: [
                          _StatCard(
                            icon: Icons.check_circle_rounded,
                            value: '$correctAnswers/$playedQuestions',
                            label: l10n.correct,
                            color: AppColors.success,
                            delay: 500,
                          ),
                          const SizedBox(width: 10),
                          _StatCard(
                            icon: Icons.percent_rounded,
                            value: '$pct%',
                            label: l10n.score,
                            color: _accuracy >= 0.6 ? AppColors.success : AppColors.warning,
                            delay: 600,
                          ),
                          const SizedBox(width: 10),
                          _StatCard(
                            icon: Icons.local_fire_department_rounded,
                            value: '$maxStreak',
                            label: l10n.bestStreak,
                            color: AppColors.warning,
                            delay: 700,
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Accuracy bar
                      _AccuracyBar(accuracy: _accuracy, delay: 750),

                      // ── Continent stars ───────────────────
                      if (continentName != null && continentEarnedStars != null) ...[
                        const SizedBox(height: 16),
                        _ContinentStarsPanel(
                          continentName: continentName!,
                          stars: continentEarnedStars!,
                          correct: correctAnswers,
                          total: playedQuestions,
                        ),
                      ],

                      // ── Newly unlocked achievements ───────
                      if (newlyUnlockedAchievements.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        _UnlockedAchievementsPanel(ids: newlyUnlockedAchievements),
                      ],

                      const Spacer(),

                      // ── Buttons ──────────────────────────
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: Container(
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withOpacity(0.35),
                                blurRadius: 14,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(18),
                            child: DecoratedBox(
                              decoration: const BoxDecoration(gradient: AppColors.gradientPrimary),
                              child: ElevatedButton.icon(
                            onPressed: () => Navigator.of(context).pop(),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(18)),
                            ),
                            icon: const Icon(Icons.home_rounded),
                            label: Text(
                              l10n.backToHome,
                              style: const TextStyle(
                                  fontSize: 17, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      ),
                    ),
                  )
                          .animate()
                          .fadeIn(delay: 800.ms)
                          .slideY(begin: 0.3, end: 0),

                      const SizedBox(height: 12),

                      SizedBox(
                        width: double.infinity,
                        height: 50,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            if (onPlayAgain != null) {
                              onPlayAgain!(context);
                            } else {
                              Navigator.of(context)
                                ..pop()
                                ..pop();
                            }
                          },
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                            side: BorderSide(color: Colors.grey.shade300),
                          ),
                          icon: const Icon(Icons.replay_rounded),
                          label: Text(
                            l10n.playAgain,
                            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                          ),
                        ),
                      )
                          .animate()
                          .fadeIn(delay: 900.ms)
                          .slideY(begin: 0.3, end: 0),
                    ],
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

// ─── Stat Card ────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;
  final int delay;

  const _StatCard({
    required this.icon,
    required this.value,
    required this.label,
    required this.color,
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 10),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(18),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w900,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      )
          .animate()
          .fadeIn(delay: Duration(milliseconds: delay), duration: 350.ms)
          .slideY(begin: 0.2, end: 0),
    );
  }
}

// ─── Continent Stars Panel ────────────────────────────────────────────────────

class _ContinentStarsPanel extends StatelessWidget {
  final String continentName;
  final int stars;
  final int correct;
  final int total;
  const _ContinentStarsPanel({
    required this.continentName,
    required this.stars,
    required this.correct,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final label = stars == 3
        ? 'Mastered! ✨'
        : stars == 2
            ? 'Good job!'
            : stars == 1
                ? 'Keep going!'
                : 'Try again';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.amber.withOpacity(stars > 0 ? 0.5 : 0.2)),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(Icons.map_rounded, color: AppColors.secondary, size: 18),
              const SizedBox(width: 8),
              Text(
                '$continentName Battle Result',
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
              ),
              const Spacer(),
              Text(
                '$correct / $total flags',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600, fontWeight: FontWeight.w600),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ...List.generate(3, (i) => Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: Icon(
                  i < stars ? Icons.star_rounded : Icons.star_outline_rounded,
                  color: i < stars ? Colors.amber : Colors.grey.shade300,
                  size: 32,
                ).animate(delay: Duration(milliseconds: 900 + i * 150))
                    .scale(duration: 400.ms, curve: Curves.elasticOut),
              )),
            ],
          ),
          const SizedBox(height: 6),
          Text(label, style: TextStyle(
            color: stars > 0 ? Colors.amber.shade700 : Colors.grey,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          )),
        ],
      ),
    ).animate().fadeIn(delay: 800.ms);
  }
}

// ─── Unlocked Achievements Panel ──────────────────────────────────────────────

class _UnlockedAchievementsPanel extends StatelessWidget {
  final List<String> ids;
  const _UnlockedAchievementsPanel({required this.ids});

  @override
  Widget build(BuildContext context) {
    final achievements = ids
        .map(Achievements.findById)
        .whereType<Achievement>()
        .toList();
    if (achievements.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF9E6),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.amber.withOpacity(0.4)),
        boxShadow: [BoxShadow(color: Colors.amber.withOpacity(0.08), blurRadius: 8, offset: const Offset(0, 2))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('🏅', style: TextStyle(fontSize: 16)),
              const SizedBox(width: 6),
              Text('Achievement${achievements.length > 1 ? 's' : ''} Unlocked!',
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Color(0xFF92400E))),
            ],
          ),
          const SizedBox(height: 10),
          ...achievements.asMap().entries.map((e) {
            final a = e.value;
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  Container(
                    width: 32, height: 32,
                    decoration: BoxDecoration(
                      color: a.color.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(a.icon, color: a.color, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(a.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        Text(a.description, style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
                      ],
                    ),
                  ),
                ],
              ).animate(delay: Duration(milliseconds: 850 + e.key * 100)).fadeIn().slideX(begin: 0.1, end: 0),
            );
          }),
        ],
      ),
    ).animate().fadeIn(delay: 800.ms);
  }
}

// ─── Accuracy Bar ─────────────────────────────────────────────────────────────

class _AccuracyBar extends StatelessWidget {
  final double accuracy;
  final int delay;
  const _AccuracyBar({required this.accuracy, required this.delay});

  @override
  Widget build(BuildContext context) {
    final color = accuracy >= 0.6 ? AppColors.success : AppColors.warning;
    final pct = (accuracy * 100).toInt();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppLocalizations.of(context)!.accuracy,
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
              ),
              Text(
                '$pct%',
                style: TextStyle(
                  fontWeight: FontWeight.w900,
                  fontSize: 13,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0.0, end: accuracy),
            duration: const Duration(milliseconds: 1100),
            curve: Curves.easeOut,
            builder: (context, value, _) => ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: value,
                backgroundColor: Colors.grey.shade100,
                valueColor: AlwaysStoppedAnimation<Color>(color),
                minHeight: 10,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: delay), duration: 350.ms);
  }
}
