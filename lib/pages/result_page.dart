import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:geoguess_flags/l10n/app_localizations.dart';
import '../theme/app_theme.dart';

class ResultPage extends StatelessWidget {
  final int score;
  final int playedQuestions;
  final int totalQuestions;

  const ResultPage({
    super.key,
    required this.score,
    required this.playedQuestions,
    required this.totalQuestions,
  });

  double get _percentage {
    final maxScore = playedQuestions * 100;
    return maxScore > 0 ? (score / maxScore).clamp(0.0, 1.0) : 0.0;
  }

  int get _stars {
    if (_percentage >= 0.9) return 3;
    if (_percentage >= 0.6) return 2;
    if (_percentage >= 0.3) return 1;
    return 0;
  }

  String _getMessage(AppLocalizations l10n) {
    if (_percentage >= 0.9) return 'Outstanding! 🏆';
    if (_percentage >= 0.6) return 'Great job! 🎉';
    if (_percentage >= 0.3) return 'Good effort! 💪';
    return 'Keep practicing! 📚';
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final pct = (_percentage * 100).toInt();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF312E81), Color(0xFFF0F4FF)],
            stops: [0.0, 0.45],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // ─── Top / Trophy section ──────────────────────
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                child: Column(
                  children: [
                    // Stars
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(3, (i) {
                        final filled = i < _stars;
                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Icon(
                            filled ? Icons.star_rounded : Icons.star_outline_rounded,
                            color: filled ? Colors.amber : Colors.white38,
                            size: 36,
                          )
                              .animate()
                              .scale(
                                  delay: Duration(milliseconds: 200 + i * 150),
                                  duration: 400.ms,
                                  curve: Curves.elasticOut)
                              .fadeIn(delay: Duration(milliseconds: 200 + i * 150)),
                        );
                      }),
                    ),

                    const SizedBox(height: 16),

                    Text(
                      l10n.gameOver,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white60,
                        letterSpacing: 2,
                        fontWeight: FontWeight.w500,
                      ),
                    ).animate().fadeIn(delay: 100.ms),

                    const SizedBox(height: 8),

                    // Score
                    Text(
                      '$score',
                      style: const TextStyle(
                        fontSize: 72,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        height: 1.0,
                      ),
                    )
                        .animate()
                        .fadeIn(delay: 200.ms, duration: 600.ms)
                        .slideY(begin: 0.3, end: 0, curve: Curves.easeOut),

                    Text(
                      l10n.finalScore,
                      style: const TextStyle(
                        fontSize: 15,
                        color: Colors.white70,
                      ),
                    ).animate().fadeIn(delay: 300.ms),

                    const SizedBox(height: 8),

                    Text(
                      _getMessage(l10n),
                      style: const TextStyle(
                        fontSize: 20,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ).animate().fadeIn(delay: 400.ms),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // ─── Stats Cards ────────────────────────────────
              Expanded(
                child: Container(
                  padding: const EdgeInsets.fromLTRB(20, 28, 20, 20),
                  decoration: const BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
                  ),
                  child: Column(
                    children: [
                      // Stats row
                      Row(
                        children: [
                          _StatCard(
                            icon: Icons.quiz_rounded,
                            value: '$playedQuestions / $totalQuestions',
                            label: l10n.question,
                            color: AppColors.primary,
                            delay: 500,
                          ),
                          const SizedBox(width: 12),
                          _StatCard(
                            icon: Icons.percent_rounded,
                            value: '$pct%',
                            label: l10n.score,
                            color: _percentage >= 0.6
                                ? AppColors.success
                                : AppColors.warning,
                            delay: 600,
                          ),
                          const SizedBox(width: 12),
                          _StatCard(
                            icon: Icons.star_rounded,
                            value: '$_stars / 3',
                            label: 'Stars',
                            color: Colors.amber,
                            delay: 700,
                          ),
                        ],
                      ),

                      const SizedBox(height: 24),

                      // Score accuracy bar
                      _AccuracyBar(percentage: _percentage),

                      const Spacer(),

                      // Buttons
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: DecoratedBox(
                          decoration: BoxDecoration(
                            gradient: AppColors.gradientPrimary,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.primary.withOpacity(0.35),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
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
                                  borderRadius: BorderRadius.circular(16)),
                            ),
                            icon: const Icon(Icons.home_rounded),
                            label: Text(l10n.backToHome,
                                style: const TextStyle(
                                    fontSize: 17, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      )
                          .animate()
                          .fadeIn(delay: 800.ms)
                          .slideY(begin: 0.3, end: 0),

                      const SizedBox(height: 12),

                      // Play again
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            // Pop result + setup, back to home
                            Navigator.of(context)
                              ..pop()
                              ..pop();
                          },
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                          ),
                          icon: const Icon(Icons.replay_rounded),
                          label: const Text('Play Again',
                              style: TextStyle(
                                  fontSize: 15, fontWeight: FontWeight.w600)),
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
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
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
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 10),
            Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      )
          .animate()
          .fadeIn(delay: Duration(milliseconds: delay), duration: 400.ms)
          .slideY(begin: 0.2, end: 0),
    );
  }
}

// ─── Accuracy Bar ─────────────────────────────────────────────────────────────

class _AccuracyBar extends StatelessWidget {
  final double percentage;
  const _AccuracyBar({required this.percentage});

  @override
  Widget build(BuildContext context) {
    final color = percentage >= 0.6 ? AppColors.success : AppColors.warning;
    final pct = (percentage * 100).toInt();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
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
              const Text('Accuracy',
                  style:
                      TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
              Text(
                '$pct%',
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: color),
              ),
            ],
          ),
          const SizedBox(height: 10),
          TweenAnimationBuilder<double>(
            tween: Tween<double>(begin: 0.0, end: percentage),
            duration: const Duration(milliseconds: 1200),
            curve: Curves.easeOut,
            builder: (context, value, _) => ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: value,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(color),
                minHeight: 10,
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 700.ms).slideY(begin: 0.2, end: 0);
  }
}
