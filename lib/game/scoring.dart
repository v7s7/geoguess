class Scoring {
  static const int basePoints = 100;
  static const int correctPoints = 100; // backward compat alias

  /// Bonus points for speed: 5 pts per second remaining on the timer.
  static int timeBonus(int secondsLeft) => secondsLeft * 5;

  /// Streak multiplier — consecutive correct answers.
  static double streakMultiplier(int streak) {
    if (streak >= 10) return 2.0;
    if (streak >= 6) return 1.5;
    if (streak >= 3) return 1.2;
    return 1.0;
  }

  /// Human-readable multiplier label shown in the UI (e.g. "×1.5").
  static String streakLabel(int streak) {
    final m = streakMultiplier(streak);
    if (m == 1.0) return '';
    return '×${m.toStringAsFixed(1).replaceAll('.0', '')}';
  }

  /// Full points awarded for a single correct answer.
  ///
  /// [streak] — the streak *before* this correct answer is counted.
  /// [secondsLeft] — timer seconds remaining (0 when no timer).
  /// [hasTimer] — whether a per-question timer is active.
  static int calculate({
    required int streak,
    int secondsLeft = 0,
    bool hasTimer = false,
  }) {
    final time = hasTimer ? timeBonus(secondsLeft) : 0;
    final multiplier = streakMultiplier(streak);
    return ((basePoints + time) * multiplier).round();
  }
}
