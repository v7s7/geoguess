import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:geoguess_flags/l10n/app_localizations.dart';
import '../game/rounds.dart';
import '../game/scoring.dart';
import '../models/country.dart';
import '../models/game_config.dart';
import '../services/mistakes_provider.dart';
import '../widgets/flag_box.dart';
import '../widgets/primary_card.dart';
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

  Timer? _timer;
  int _timeLeft = 0;

  // Typing Mode
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

  // --- Normalization Logic (The "Mercy" Function) ---
  String _normalize(String input) {
    String text = input.trim().toLowerCase();
    
    // Arabic Normalization
    text = text.replaceAll(RegExp(r'[أإآ]'), 'ا'); // Normalize Alef
    text = text.replaceAll('ة', 'ه'); // Normalize Ta Marbuta
    text = text.replaceAll('ى', 'ي'); // Normalize Ya
    text = text.replaceAll(RegExp(r'\s+'), ' '); // Collapse multiple spaces

    // Optional: Remove common prefixes like "the" or "al" if you want extra mercy
    // text = text.replaceAll(RegExp(r'^(the|al)\s+'), ''); 

    return text;
  }

  void _submitAnswer({bool? known, Country? selected, String? typedText, bool timeOut = false}) {
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
      // TYPING MODE CHECK
      final userInput = _normalize(typedText);
      final correctAnswer = _normalize(_currentRound!.correctCountry.localizedName(context));
      correct = userInput == correctAnswer;
    } else {
      // MULTIPLE CHOICE CHECK
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
      final correctName = _currentRound!.correctCountry.localizedName(context);

      if (correct) {
        _score += Scoring.correctPoints;
        _feedbackMessage = widget.config.isReviewMode ? l10n.mistakesCleared : null;
      } else {
        _feedbackMessage = "${l10n.correctAnswerIs} $correctName";
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
          playedQuestions: _questionIndex > _engine.totalQuestions ? _engine.totalQuestions : _questionIndex - 1,
        ),
      ),
    );
  }

  // ... (Keep _onWillPop and _buildHintChip methods same as before) ...
  Future<bool> _onWillPop() async {
    final l10n = AppLocalizations.of(context)!;
    return await showDialog(context: context, builder: (context) => AlertDialog(title: Text(l10n.endGame), content: Text(l10n.endGameConfirm), actions: [TextButton(onPressed: () => Navigator.of(context).pop(false), child: Text(l10n.cancel)), TextButton(onPressed: () => Navigator.of(context).pop(true), child: Text(l10n.yes))])) ?? false;
  }

  Widget _buildHintChip(BuildContext context, String label, String value, IconData icon) {
    return Container(padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8), decoration: BoxDecoration(color: Colors.indigo.shade50, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.indigo.shade100)), child: Row(children: [Icon(icon, size: 16, color: Colors.indigo), const SizedBox(width: 8), Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)), Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.indigo))])]));
  }

  @override
  Widget build(BuildContext context) {
    if (_currentRound == null) return const Scaffold();
    final l10n = AppLocalizations.of(context)!;

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        appBar: AppBar(
          title: Text("${l10n.question} $_questionIndex / ${_engine.totalQuestions}"),
          actions: [Center(child: Padding(padding: const EdgeInsets.symmetric(horizontal: 16), child: Text("${l10n.score}: $_score", style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16))))],
        ),
        body: Column(
          children: [
            if (widget.config.timerSeconds != null)
              LinearProgressIndicator(value: _timeLeft / widget.config.timerSeconds!, color: _timeLeft < 5 ? Colors.red : Colors.green, backgroundColor: Colors.grey.shade200),
            
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    FlagBox(url: _currentRound!.correctCountry.flagUrl),
                    const SizedBox(height: 24),

                    // Hints
                    if (widget.config.showRegionHint || widget.config.showCapitalHint) ...[
                      Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
                          if (widget.config.showRegionHint) _buildHintChip(context, l10n.region, _currentRound!.correctCountry.localizedRegion(context), Icons.public),
                          if (widget.config.showCapitalHint) _buildHintChip(context, l10n.capital, _currentRound!.correctCountry.capital, Icons.location_city),
                      ]),
                      const SizedBox(height: 24),
                    ],
                    
                    // --- INPUT AREA ---
                    if (widget.config.mode == GameMode.practice) ...[
                      Text(l10n.whatCountry, style: Theme.of(context).textTheme.headlineSmall),
                      const SizedBox(height: 32),
                      if (!_answered) ...[
                         Row(children: [
                             Expanded(child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade100, foregroundColor: Colors.red), onPressed: () => _submitAnswer(known: false), child: Text(l10n.iDontKnowIt))),
                             const SizedBox(width: 16),
                             Expanded(child: ElevatedButton(style: ElevatedButton.styleFrom(backgroundColor: Colors.green.shade100, foregroundColor: Colors.green), onPressed: () => _submitAnswer(known: true), child: Text(l10n.iKnowIt))),
                         ])
                      ],
                    ] else if (widget.config.choicesCount == 0) ...[
                      // --- TYPING MODE ---
                      if (!_answered) ...[
                        TextField(
                          controller: _typeController,
                          decoration: InputDecoration(
                            hintText: l10n.typeAnswer,
                            border: const OutlineInputBorder(),
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.send, color: Colors.indigo),
                              onPressed: () => _submitAnswer(typedText: _typeController.text),
                            ),
                          ),
                          onSubmitted: (val) => _submitAnswer(typedText: val),
                          textInputAction: TextInputAction.done,
                        ),
                        const SizedBox(height: 16),
                        SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: FilledButton(
                            onPressed: () => _submitAnswer(typedText: _typeController.text), 
                            child: Text(l10n.submit)
                          ),
                        ),
                      ],
                    ] else ...[
                      // --- MULTIPLE CHOICE MODE ---
                      if (!_answered)
                        ..._currentRound!.options.map((option) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: SizedBox(
                            width: double.infinity,
                            child: OutlinedButton(
                              style: OutlinedButton.styleFrom(padding: const EdgeInsets.all(16), textStyle: const TextStyle(fontSize: 18)),
                              onPressed: () => _submitAnswer(selected: option),
                              child: Text(option.localizedName(context)),
                            ),
                          ),
                        )),
                    ],

                    // --- FEEDBACK AREA ---
                    if (_answered) ...[
                      const SizedBox(height: 24),
                      PrimaryCard(
                        color: _isCorrect ? Colors.green.shade50 : Colors.red.shade50,
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(_isCorrect ? Icons.check_circle : Icons.cancel, color: _isCorrect ? Colors.green : Colors.red, size: 32),
                                const SizedBox(width: 8),
                                Expanded(child: Text(_currentRound!.correctCountry.localizedName(context), style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                              ],
                            ),
                            if (_feedbackMessage != null) Padding(padding: const EdgeInsets.only(top: 8.0), child: Text(_feedbackMessage!, style: TextStyle(color: _isCorrect ? Colors.green.shade700 : Colors.red.shade700))),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(width: double.infinity, height: 56, child: FilledButton(onPressed: _nextRound, child: Text(l10n.next))),
                    ]
                  ],
                ),
              ),
            ),
            
            Padding(padding: const EdgeInsets.all(16.0), child: TextButton.icon(icon: const Icon(Icons.exit_to_app, color: Colors.grey), label: Text(l10n.endGame, style: const TextStyle(color: Colors.grey)), onPressed: () async { if (await _onWillPop()) _finishGame(); })),
          ],
        ),
      ),
    );
  }
}