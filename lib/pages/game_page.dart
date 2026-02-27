import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:geoguess_flags/l10n/app_localizations.dart';
import '../game/rounds.dart';
import '../game/scoring.dart';
import '../models/country.dart';
import '../models/game_config.dart';
import '../services/mistakes_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/flag_box.dart';
import 'result_page.dart';

class GamePage extends StatefulWidget {
  final List<Country> countries;
  final GameConfig config;

  const GamePage({super.key, required this.countries, required this.config});

  @override
  State<GamePage> createState() => _GamePageState();
}

class _GamePageState extends State<GamePage> {
  late GameEngine _engine;
  RoundData? _currentRound;
  int _score = 0;
  int _questionIndex = 0;
  bool _answered = false;
  String? _feedbackMessage;
  bool _isCorrect = false;
  Country? _selectedOption;

  Timer? _timer;
  int _timeLeft = 0;

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
    _typeController.dispose();
    super.dispose();
  }

  void _nextRound() {
    _timer?.cancel();
    _typeController.clear();
    setState(() {
      _currentRound = _engine.getNextRound();
      _answered = false;
      _feedbackMessage = null;
      _selectedOption = null;
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
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_timeLeft > 0) {
        setState(() => _timeLeft--);
      } else {
        _handleTimeOut();
      }
    });
  }

  void _handleTimeOut() {
    _timer?.cancel();
    _submitAnswer(known: false, timeOut: true);
  }

  String _normalize(String input) {
    String text = input.trim().toLowerCase();
    text = text.replaceAll(RegExp(r'[أإآ]'), 'ا');
    text = text.replaceAll('ة', 'ه');
    text = text.replaceAll('ى', 'ي');
    text = text.replaceAll(RegExp(r'\s+'), ' ');
    return text;
  }

  void _submitAnswer(
      {bool? known,
      Country? selected,
      String? typedText,
      bool timeOut = false}) {
    if (_answered) return;
    _timer?.cancel();

    final mistakesProv = Provider.of<MistakesProvider>(context, listen: false);
    final l10n = AppLocalizations.of(context)!;

    bool correct = false;

    if (timeOut) {
      correct = false;
    } else if (widget.config.mode == GameMode.practice) {
      correct = known == true;
    } else if (widget.config.choicesCount == 0 && typedText != null) {
      final userInput = _normalize(typedText);
      final correctAnswer =
          _normalize(_currentRound!.correctCountry.localizedName(context));
      correct = userInput == correctAnswer;
    } else {
      correct = selected!.cca2 == _currentRound!.correctCountry.cca2;
    }

    if (!correct) {
      mistakesProv.addMistake(_currentRound!.correctCountry.cca2);
    } else if (correct && widget.config.isReviewMode) {
      mistakesProv.removeMistake(_currentRound!.correctCountry.cca2);
    }

    setState(() {
      _answered = true;
      _isCorrect = correct;
      _selectedOption = selected;
      final correctName = _currentRound!.correctCountry.localizedName(context);

      if (correct) {
        _score += Scoring.correctPoints;
        _feedbackMessage =
            widget.config.isReviewMode ? l10n.mistakesCleared : null;
      } else {
        _feedbackMessage = '${l10n.correctAnswerIs} $correctName';
      }
    });
  }

  void _finishGame() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => ResultPage(
          score: _score,
          totalQuestions: _engine.totalQuestions,
          playedQuestions: _questionIndex > _engine.totalQuestions
              ? _engine.totalQuestions
              : _questionIndex - 1,
        ),
      ),
    );
  }

  Future<bool> _onWillPop() async {
    final l10n = AppLocalizations.of(context)!;
    return await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Text(l10n.endGame),
            content: Text(l10n.endGameConfirm),
            actions: [
              TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(l10n.cancel)),
              FilledButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  child: Text(l10n.yes)),
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

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        body: Column(
          children: [
            // ─── Header ─────────────────────────────────────────
            Container(
              decoration:
                  const BoxDecoration(gradient: AppColors.gradientPrimary),
              child: SafeArea(
                bottom: false,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(8, 4, 16, 12),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.close_rounded,
                                color: Colors.white70),
                            onPressed: () async {
                              if (await _onWillPop()) _finishGame();
                            },
                          ),
                          Expanded(
                            child: Column(
                              children: [
                                Text(
                                  '${l10n.question} ${_questionIndex > _engine.totalQuestions ? _engine.totalQuestions : _questionIndex} / ${_engine.totalQuestions}',
                                  style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 13,
                                  ),
                                ),
                                // Progress bar
                                const SizedBox(height: 6),
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(4),
                                  child: LinearProgressIndicator(
                                    value: (_questionIndex - 1) /
                                        _engine.totalQuestions,
                                    backgroundColor:
                                        Colors.white.withOpacity(0.2),
                                    valueColor:
                                        const AlwaysStoppedAnimation<Color>(
                                            Colors.white),
                                    minHeight: 4,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          // Score badge
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.15),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.star_rounded,
                                    color: Colors.amber, size: 16),
                                const SizedBox(width: 4),
                                Text(
                                  '$_score',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 15,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Timer bar
                    if (widget.config.timerSeconds != null)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
                        child: Row(
                          children: [
                            Icon(Icons.timer_rounded,
                                color: _timerColor, size: 18),
                            const SizedBox(width: 8),
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: _timerProgress,
                                  backgroundColor:
                                      Colors.white.withOpacity(0.2),
                                  valueColor:
                                      AlwaysStoppedAnimation<Color>(_timerColor),
                                  minHeight: 6,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '${_timeLeft}s',
                              style: TextStyle(
                                color: _timerColor,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
            ),

            // ─── Game Content ────────────────────────────────────
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    // Question prompt
                    Text(
                      l10n.whatCountry,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade600,
                      ),
                    ).animate().fadeIn(duration: 300.ms),

                    const SizedBox(height: 16),

                    // Flag
                    Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.12),
                            blurRadius: 24,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: FlagBox(
                            url: _currentRound!.correctCountry.flagUrl,
                            height: 180),
                      ),
                    )
                        .animate(key: ValueKey(_currentRound!.correctCountry.cca2))
                        .fadeIn(duration: 400.ms)
                        .scale(begin: const Offset(0.92, 0.92), end: const Offset(1, 1), curve: Curves.easeOut),

                    const SizedBox(height: 16),

                    // Hints
                    if (widget.config.showRegionHint ||
                        widget.config.showCapitalHint) ...[
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          if (widget.config.showRegionHint)
                            _HintChip(
                              icon: Icons.public_rounded,
                              label: l10n.region,
                              value: _currentRound!.correctCountry
                                  .localizedRegion(context),
                            ),
                          if (widget.config.showRegionHint &&
                              widget.config.showCapitalHint)
                            const SizedBox(width: 8),
                          if (widget.config.showCapitalHint)
                            _HintChip(
                              icon: Icons.location_city_rounded,
                              label: l10n.capital,
                              value: _currentRound!.correctCountry.capital,
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],

                    // ─── Input Area ──────────────────────────────
                    if (widget.config.mode == GameMode.practice) ...[
                      if (!_answered)
                        Row(
                          children: [
                            Expanded(
                              child: _AnswerButton(
                                label: l10n.iDontKnowIt,
                                color: AppColors.error,
                                icon: Icons.close_rounded,
                                onTap: () => _submitAnswer(known: false),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: _AnswerButton(
                                label: l10n.iKnowIt,
                                color: AppColors.success,
                                icon: Icons.check_rounded,
                                onTap: () => _submitAnswer(known: true),
                              ),
                            ),
                          ],
                        ),
                    ] else if (widget.config.choicesCount == 0) ...[
                      // Typing Mode
                      if (!_answered) ...[
                        TextField(
                          controller: _typeController,
                          decoration: InputDecoration(
                            hintText: l10n.typeAnswer,
                            prefixIcon: const Icon(Icons.keyboard_alt_outlined,
                                color: AppColors.primary),
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.send_rounded,
                                  color: AppColors.primary),
                              onPressed: () =>
                                  _submitAnswer(typedText: _typeController.text),
                            ),
                          ),
                          onSubmitted: (val) => _submitAnswer(typedText: val),
                          textInputAction: TextInputAction.done,
                          autofocus: true,
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: AppColors.gradientPrimary,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: ElevatedButton(
                              onPressed: () =>
                                  _submitAnswer(typedText: _typeController.text),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.transparent,
                                shadowColor: Colors.transparent,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14)),
                              ),
                              child: Text(l10n.submit,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16)),
                            ),
                          ),
                        ),
                      ],
                    ] else ...[
                      // Multiple Choice
                      if (!_answered)
                        ..._currentRound!.options.asMap().entries.map((entry) {
                          final i = entry.key;
                          final option = entry.value;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _ChoiceButton(
                              option: option,
                              onTap: () =>
                                  _submitAnswer(selected: option),
                            )
                                .animate()
                                .fadeIn(
                                    delay: Duration(milliseconds: 50 + i * 60),
                                    duration: 300.ms)
                                .slideY(
                                    begin: 0.15,
                                    end: 0,
                                    delay: Duration(milliseconds: 50 + i * 60)),
                          );
                        }),
                    ],

                    // ─── Feedback ────────────────────────────────
                    if (_answered) ...[
                      const SizedBox(height: 8),
                      _FeedbackCard(
                        isCorrect: _isCorrect,
                        countryName: _currentRound!.correctCountry
                            .localizedName(context),
                        message: _feedbackMessage,
                      )
                          .animate()
                          .fadeIn(duration: 400.ms)
                          .scale(
                              begin: const Offset(0.95, 0.95),
                              end: const Offset(1, 1),
                              curve: Curves.elasticOut),

                      const SizedBox(height: 16),

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
                            onPressed: _nextRound,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16)),
                            ),
                            icon: const Icon(Icons.arrow_forward_rounded),
                            label: Text(l10n.next,
                                style: const TextStyle(
                                    fontSize: 17, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      )
                          .animate()
                          .fadeIn(delay: 200.ms)
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

// ─── Hint Chip ────────────────────────────────────────────────────────────────

class _HintChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _HintChip(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withOpacity(0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: AppColors.primary),
          const SizedBox(width: 6),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style:
                      TextStyle(fontSize: 10, color: Colors.grey.shade500)),
              Text(value,
                  style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary)),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Choice Button ────────────────────────────────────────────────────────────

class _ChoiceButton extends StatelessWidget {
  final Country option;
  final VoidCallback onTap;

  const _ChoiceButton({required this.option, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          option.localizedName(context),
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}

// ─── Answer Button (Practice Mode) ───────────────────────────────────────────

class _AnswerButton extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;
  final VoidCallback onTap;

  const _AnswerButton({
    required this.label,
    required this.color,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 18),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withOpacity(0.4)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 6),
            Text(
              label,
              style: TextStyle(
                  color: color, fontWeight: FontWeight.bold, fontSize: 14),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Feedback Card ────────────────────────────────────────────────────────────

class _FeedbackCard extends StatelessWidget {
  final bool isCorrect;
  final String countryName;
  final String? message;

  const _FeedbackCard({
    required this.isCorrect,
    required this.countryName,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    final color = isCorrect ? AppColors.success : AppColors.error;
    final bgColor = isCorrect ? AppColors.successLight : AppColors.errorLight;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: color,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  isCorrect ? Icons.check_rounded : Icons.close_rounded,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  countryName,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: color.withOpacity(0.9),
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ],
          ),
          if (message != null) ...[
            const SizedBox(height: 8),
            Text(
              message!,
              style: TextStyle(color: color.withOpacity(0.8), fontSize: 13),
              textAlign: TextAlign.center,
            ),
          ],
        ],
      ),
    );
  }
}
