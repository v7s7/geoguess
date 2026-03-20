import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:geoguess_flags/l10n/app_localizations.dart';
import '../game/rounds.dart';
import '../game/scoring.dart';
import '../models/country.dart';
import '../models/game_config.dart';
import '../services/auth_service.dart';
import '../services/mistakes_provider.dart';
import '../services/sound_service.dart';
import '../services/user_service.dart';
import '../theme/app_theme.dart';
import '../widgets/flag_box.dart';
import 'result_page.dart';

class GamePage extends StatefulWidget {
  final List<Country> countries;
  final GameConfig config;
  /// Optional callback invoked with the final score when the game ends.
  final void Function(int score)? onFinished;

  const GamePage({
    super.key,
    required this.countries,
    required this.config,
    this.onFinished,
  });

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> with SingleTickerProviderStateMixin {
  late GameEngine _engine;
  RoundData? _currentRound;

  int _score = 0;
  int _questionIndex = 0;
  int _correctCount = 0;
  int _streak = 0;
  int _maxStreak = 0;

  bool _answered = false;
  Country? _selectedOption;
  bool _isCorrect = false;
  String? _feedbackMessage;

  // Points pop-up
  int? _lastPoints;
  bool _showPointsPop = false;

  // Timer
  Timer? _timer;
  int _timeLeft = 0;

  // Auto-advance after answer
  Timer? _advanceTimer;

  final TextEditingController _typeController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _engine = GameEngine(widget.countries, widget.config);
    _nextRound();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _advanceTimer?.cancel();
    _typeController.dispose();
    super.dispose();
  }

  void _nextRound() {
    _timer?.cancel();
    _advanceTimer?.cancel();
    _typeController.clear();
    setState(() {
      _currentRound = _engine.getNextRound();
      _answered = false;
      _feedbackMessage = null;
      _selectedOption = null;
      _lastPoints = null;
      _showPointsPop = false;
      _questionIndex++;

      if (_currentRound == null) {
        _finishGame();
      } else if (widget.config.timerSeconds != null) {
        _timeLeft = widget.config.timerSeconds!;
        _startTimer();
      }
    });
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_timeLeft > 0) {
        setState(() => _timeLeft--);
      } else {
        _submitAnswer(timeOut: true);
      }
    });
  }

  String _normalize(String input) {
    String text = input.trim().toLowerCase();
    text = text.replaceAll(RegExp(r'[أإآ]'), 'ا');
    text = text.replaceAll('ة', 'ه');
    text = text.replaceAll('ى', 'ي');
    text = text.replaceAll(RegExp(r'\s+'), ' ');
    return text;
  }

  void _submitAnswer({
    bool? known,
    Country? selected,
    String? typedText,
    bool timeOut = false,
  }) {
    if (_answered) return;
    _timer?.cancel();

    final mistakesProv = Provider.of<MistakesProvider>(context, listen: false);
    final l10n = AppLocalizations.of(context)!;
    final sound = SoundService();

    bool correct = false;
    if (timeOut) {
      correct = false;
    } else if (widget.config.mode == GameMode.practice) {
      correct = known == true;
    } else if (widget.config.choicesCount == 0 && typedText != null) {
      final userInput = _normalize(typedText);
      final answer = _normalize(_currentRound!.correctCountry.localizedName(context));
      correct = userInput == answer;
    } else {
      correct = selected!.cca2 == _currentRound!.correctCountry.cca2;
    }

    // Calculate points
    int points = 0;
    if (correct) {
      sound.playCorrect();
      points = Scoring.calculate(
        streak: _streak,
        secondsLeft: _timeLeft,
        hasTimer: widget.config.timerSeconds != null,
      );
      _streak++;
      if (_streak > _maxStreak) _maxStreak = _streak;
      _correctCount++;
      _score += points;
    } else {
      sound.playWrong();
      _streak = 0;
    }

    // Mistakes tracking
    if (!correct) {
      mistakesProv.addMistake(_currentRound!.correctCountry.cca2);
    } else if (correct && widget.config.isReviewMode) {
      mistakesProv.removeMistake(_currentRound!.correctCountry.cca2);
    }

    setState(() {
      _answered = true;
      _isCorrect = correct;
      _selectedOption = selected;
      _lastPoints = correct ? points : null;
      _showPointsPop = correct;

      final correctName = _currentRound!.correctCountry.localizedName(context);
      if (!correct && !timeOut) {
        _feedbackMessage = '${l10n.correctAnswerIs} $correctName';
      } else if (timeOut) {
        _feedbackMessage = '⏱ Time\'s up! — $correctName';
      } else if (widget.config.isReviewMode) {
        _feedbackMessage = l10n.mistakesCleared;
      }
    });

    // Auto-advance after 1.4 s
    _advanceTimer = Timer(const Duration(milliseconds: 1400), () {
      if (mounted) _nextRound();
    });
  }

  void _finishGame() {
    final played = _questionIndex > _engine.totalQuestions
        ? _engine.totalQuestions
        : _questionIndex - 1;
    SoundService().playSuccess();
    _recordGameAchievements(played);
    widget.onFinished?.call(_score);
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => ResultPage(
          score: _score,
          totalQuestions: _engine.totalQuestions,
          playedQuestions: played,
          correctAnswers: _correctCount,
          maxStreak: _maxStreak,
        ),
      ),
    );
  }

  Future<void> _recordGameAchievements(int played) async {
    final uid = context.read<AuthService>().uid;
    if (uid == null) return;
    final userSvc = UserService();
    await userSvc.recordGameResult(uid: uid, score: _score, won: false);
    await userSvc.updateStreak(uid);
    await userSvc.unlockAchievement(uid, 'first_game');
    final maxScore = played * Scoring.basePoints;
    if (maxScore > 0 && _score >= maxScore) {
      await userSvc.unlockAchievement(uid, 'perfect_score');
    }
    if (_engine.totalQuestions >= 20) {
      await userSvc.unlockAchievement(uid, 'quiz_master');
    }
    if (_engine.totalQuestions >= widget.countries.length && widget.countries.length > 200) {
      await userSvc.unlockAchievement(uid, 'world_master');
    }
  }

  Future<bool> _onWillPop() async {
    final l10n = AppLocalizations.of(context)!;
    return await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text(l10n.endGame),
            content: Text(l10n.endGameConfirm),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: Text(l10n.cancel),
              ),
              FilledButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: Text(l10n.yes),
              ),
            ],
          ),
        ) ??
        false;
  }

  double get _timerProgress {
    if (widget.config.timerSeconds == null) return 1.0;
    return _timeLeft / widget.config.timerSeconds!;
  }

  Color get _timerColor {
    if (_timerProgress > 0.5) return AppColors.success;
    if (_timerProgress > 0.25) return AppColors.warning;
    return AppColors.error;
  }

  @override
  Widget build(BuildContext context) {
    if (_currentRound == null) return const Scaffold();
    final l10n = AppLocalizations.of(context)!;
    final hasTimer = widget.config.timerSeconds != null;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        if (await _onWillPop() && context.mounted) {
          _finishGame();
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.background,
        body: Column(
          children: [
            // ── Timer bar (full width, very top) ─────────────
            if (hasTimer)
              AnimatedContainer(
                duration: const Duration(milliseconds: 100),
                height: 4,
                child: LinearProgressIndicator(
                  value: _timerProgress,
                  backgroundColor: Colors.grey.shade200,
                  valueColor: AlwaysStoppedAnimation<Color>(_timerColor),
                  minHeight: 4,
                ),
              ),

            // ── Header ──────────────────────────────────────
            SafeArea(
              bottom: false,
              top: !hasTimer,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(4, 4, 16, 0),
                child: Row(
                  children: [
                    // Back / close
                    IconButton(
                      icon: const Icon(Icons.close_rounded, size: 22),
                      color: Colors.black54,
                      onPressed: () async {
                        if (await _onWillPop() && context.mounted) {
                          _finishGame();
                        }
                      },
                    ),

                    // Progress
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          Text(
                            '${_questionIndex > _engine.totalQuestions ? _engine.totalQuestions : _questionIndex} / ${_engine.totalQuestions}',
                            style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.black54,
                            ),
                          ),
                          const SizedBox(height: 4),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: (_questionIndex - 1) / _engine.totalQuestions,
                              backgroundColor: Colors.grey.shade200,
                              valueColor: const AlwaysStoppedAnimation(AppColors.primary),
                              minHeight: 4,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(width: 8),

                    // Streak
                    if (_streak >= 2)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.warning.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Row(
                          children: [
                            const Text('🔥', style: TextStyle(fontSize: 12)),
                            const SizedBox(width: 3),
                            Text(
                              '$_streak',
                              style: const TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: AppColors.warning,
                              ),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(width: 8),

                    // Score
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.star_rounded,
                              color: AppColors.primary, size: 14),
                          const SizedBox(width: 4),
                          Text(
                            '$_score',
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // ── Game content ────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                child: Column(
                  children: [
                    // Timer countdown (shown inline when < 10s)
                    if (hasTimer && _timeLeft <= 10 && !_answered)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Text(
                          '${_timeLeft}s',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.w900,
                            color: _timerColor,
                          ),
                        ).animate(key: ValueKey(_timeLeft)).scale(
                          begin: const Offset(1.3, 1.3),
                          end: const Offset(1.0, 1.0),
                          duration: 200.ms,
                          curve: Curves.easeOut,
                        ),
                      ),

                    // Flag
                    _FlagCard(
                      url: _currentRound!.correctCountry.flagUrl,
                      countryKey: _currentRound!.correctCountry.cca2,
                      pointsPop: _showPointsPop ? _lastPoints : null,
                      streakLabel: _showPointsPop && _streak >= 3
                          ? Scoring.streakLabel(_streak - 1)
                          : null,
                    ),

                    const SizedBox(height: 14),

                    // Hints
                    if (widget.config.showRegionHint || widget.config.showCapitalHint)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 14),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (widget.config.showRegionHint)
                              _HintPill(
                                icon: Icons.public_rounded,
                                value: _currentRound!.correctCountry.localizedRegion(context),
                              ),
                            if (widget.config.showRegionHint && widget.config.showCapitalHint)
                              const SizedBox(width: 8),
                            if (widget.config.showCapitalHint)
                              _HintPill(
                                icon: Icons.location_city_rounded,
                                value: _currentRound!.correctCountry.capital,
                              ),
                          ],
                        ),
                      ),

                    // ── Input ────────────────────────────────
                    if (widget.config.mode == GameMode.practice)
                      _PracticeButtons(
                        answered: _answered,
                        l10n: l10n,
                        onKnow: () => _submitAnswer(known: true),
                        onDontKnow: () => _submitAnswer(known: false),
                      )
                    else if (widget.config.choicesCount == 0)
                      _TypeInput(
                        controller: _typeController,
                        answered: _answered,
                        l10n: l10n,
                        onSubmit: (val) => _submitAnswer(typedText: val),
                      )
                    else
                      _ChoiceGrid(
                        options: _currentRound!.options,
                        correct: _currentRound!.correctCountry,
                        answered: _answered,
                        selected: _selectedOption,
                        onTap: (opt) => _submitAnswer(selected: opt),
                      ),

                    // ── Wrong answer feedback ──────────────
                    if (_answered && _feedbackMessage != null) ...[
                      const SizedBox(height: 12),
                      _WrongFeedback(message: _feedbackMessage!)
                          .animate()
                          .fadeIn(duration: 300.ms)
                          .slideY(begin: 0.2, end: 0),
                    ],
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

// ─── Flag Card with points pop ────────────────────────────────────────────────

class _FlagCard extends StatelessWidget {
  final String url;
  final String countryKey;
  final int? pointsPop;
  final String? streakLabel;

  const _FlagCard({
    required this.url,
    required this.countryKey,
    this.pointsPop,
    this.streakLabel,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.topRight,
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.1),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(22),
            child: FlagBox(url: url, height: 190),
          ),
        )
            .animate(key: ValueKey(countryKey))
            .fadeIn(duration: 350.ms)
            .scale(
              begin: const Offset(0.92, 0.92),
              end: const Offset(1, 1),
              curve: Curves.easeOut,
            ),

        // Points pop
        if (pointsPop != null)
          Positioned(
            top: 10,
            right: 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppColors.success,
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.success.withOpacity(0.4),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Text(
                '+$pointsPop${streakLabel != null ? ' $streakLabel' : ''}',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                  fontSize: 14,
                ),
              ),
            )
                .animate()
                .fadeIn(duration: 200.ms)
                .slideY(begin: 0.3, end: 0)
                .then(delay: 1000.ms)
                .fadeOut(),
          ),
      ],
    );
  }
}

// ─── Choice Grid ──────────────────────────────────────────────────────────────

class _ChoiceGrid extends StatelessWidget {
  final List<Country> options;
  final Country correct;
  final bool answered;
  final Country? selected;
  final void Function(Country) onTap;

  const _ChoiceGrid({
    required this.options,
    required this.correct,
    required this.answered,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: options.asMap().entries.map((e) {
        final i = e.key;
        final opt = e.value;

        Color bg = Colors.white;
        Color border = Colors.grey.shade200;
        Color textColor = Colors.black87;
        Widget? trailingIcon;

        if (answered) {
          if (opt.cca2 == correct.cca2) {
            bg = AppColors.successLight;
            border = AppColors.success;
            textColor = AppColors.success;
            trailingIcon = const Icon(Icons.check_circle_rounded,
                color: AppColors.success, size: 20);
          } else if (opt.cca2 == selected?.cca2) {
            bg = AppColors.errorLight;
            border = AppColors.error;
            textColor = AppColors.error;
            trailingIcon = const Icon(Icons.cancel_rounded,
                color: AppColors.error, size: 20);
          } else {
            bg = Colors.grey.shade50;
            border = Colors.grey.shade200;
            textColor = Colors.grey.shade400;
          }
        }

        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: GestureDetector(
            onTap: answered ? null : () => onTap(opt),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 15),
              decoration: BoxDecoration(
                color: bg,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: border, width: answered ? 1.5 : 1),
                boxShadow: answered
                    ? null
                    : [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 6,
                          offset: const Offset(0, 2),
                        ),
                      ],
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      opt.localizedName(context),
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: textColor,
                      ),
                    ),
                  ),
                  if (trailingIcon != null) trailingIcon,
                ],
              ),
            ),
          )
              .animate()
              .fadeIn(
                delay: Duration(milliseconds: answered ? 0 : 40 + i * 55),
                duration: 280.ms,
              )
              .slideY(
                begin: answered ? 0 : 0.12,
                end: 0,
                delay: Duration(milliseconds: answered ? 0 : 40 + i * 55),
              ),
        );
      }).toList(),
    );
  }
}

// ─── Practice Buttons ─────────────────────────────────────────────────────────

class _PracticeButtons extends StatelessWidget {
  final bool answered;
  final AppLocalizations l10n;
  final VoidCallback onKnow;
  final VoidCallback onDontKnow;

  const _PracticeButtons({
    required this.answered,
    required this.l10n,
    required this.onKnow,
    required this.onDontKnow,
  });

  @override
  Widget build(BuildContext context) {
    if (answered) return const SizedBox.shrink();
    return Row(
      children: [
        Expanded(
          child: _PracticeBtn(
            label: l10n.iDontKnowIt,
            icon: Icons.close_rounded,
            color: AppColors.error,
            onTap: onDontKnow,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _PracticeBtn(
            label: l10n.iKnowIt,
            icon: Icons.check_rounded,
            color: AppColors.success,
            onTap: onKnow,
          ),
        ),
      ],
    );
  }
}

class _PracticeBtn extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  const _PracticeBtn({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: color.withOpacity(0.35)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 26),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Type Input ───────────────────────────────────────────────────────────────

class _TypeInput extends StatelessWidget {
  final TextEditingController controller;
  final bool answered;
  final AppLocalizations l10n;
  final void Function(String) onSubmit;

  const _TypeInput({
    required this.controller,
    required this.answered,
    required this.l10n,
    required this.onSubmit,
  });

  @override
  Widget build(BuildContext context) {
    if (answered) return const SizedBox.shrink();
    return Column(
      children: [
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: l10n.typeAnswer,
            prefixIcon: const Icon(Icons.keyboard_alt_outlined, color: AppColors.primary),
            suffixIcon: IconButton(
              icon: const Icon(Icons.send_rounded, color: AppColors.primary),
              onPressed: () => onSubmit(controller.text),
            ),
          ),
          onSubmitted: onSubmit,
          textInputAction: TextInputAction.done,
          autofocus: true,
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: AppColors.gradientPrimary,
              borderRadius: BorderRadius.circular(14),
            ),
            child: ElevatedButton(
              onPressed: () => onSubmit(controller.text),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              child: Text(l10n.submit,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Wrong feedback banner ────────────────────────────────────────────────────

class _WrongFeedback extends StatelessWidget {
  final String message;
  const _WrongFeedback({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.errorLight,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.error.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded, color: AppColors.error, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: AppColors.error,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Hint Pill ────────────────────────────────────────────────────────────────

class _HintPill extends StatelessWidget {
  final IconData icon;
  final String value;
  const _HintPill({required this.icon, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.07),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: AppColors.primary),
          const SizedBox(width: 5),
          Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}
