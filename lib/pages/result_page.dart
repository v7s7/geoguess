import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:geoguess_flags/l10n/app_localizations.dart';
import '../theme/app_theme.dart';

class ResultPage extends StatelessWidget {
  final int score;
  final int playedQuestions;
  final int totalQuestions;
  final int correctAnswers;
  final int maxStreak;

  const ResultPage({
    super.key,
    required this.score,
    required this.totalQuestions,
    required this.playedQuestions,
    this.correctAnswers = 0,
    this.maxStreak = 0,
  });

  double get _accuracy =>
      playedQuestions > 0 ? correctAnswers / playedQuestions : 0.0;

  int get _stars {
    if (_accuracy >= 0.9) return 3;
    if (_accuracy >= 0.6) return 2;
    if (_accuracy >= 0.3) return 1;
    return 0;
  }

  String _getMessage() {
    if (_accuracy >= 0.9) return 'Outstanding! 🏆';
    if (_accuracy >= 0.6) return 'Great job! 🎉';
    if (_accuracy >= 0.3) return 'Good effort! 💪';
    return 'Keep practicing! 📚';
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
                      _getMessage(),
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
                            label: 'Correct',
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
                            label: 'Best Streak',
                            color: AppColors.warning,
                            delay: 700,
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Accuracy bar
                      _AccuracyBar(accuracy: _accuracy, delay: 750),

                      const Spacer(),

                      // ── Buttons ──────────────────────────
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: AppColors.gradientPrimary,
                            borderRadius: BorderRadius.circular(18),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withOpacity(0.35),
                                blurRadius: 14,
                                offset: const Offset(0, 5),
                              ),
                            ],
                          ),
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
                            Navigator.of(context)
                              ..pop()
                              ..pop();
                          },
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                            side: BorderSide(color: Colors.grey.shade300),
                          ),
                          icon: const Icon(Icons.replay_rounded),
                          label: const Text(
                            'Play Again',
                            style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
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
              const Text(
                'Accuracy',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
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
