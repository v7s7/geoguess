enum GameMode { practice, quiz }

class GameConfig {
  final GameMode mode;
  final int questionCount;
  final int choicesCount;
  final int? timerSeconds;
  final bool isReviewMode;
  // NEW FIELDS
  final bool showRegionHint;
  final bool showCapitalHint;

  GameConfig({
    required this.mode,
    required this.questionCount,
    this.choicesCount = 4,
    this.timerSeconds,
    this.isReviewMode = false,
    this.showRegionHint = false, // Default off
    this.showCapitalHint = false, // Default off
  });
}