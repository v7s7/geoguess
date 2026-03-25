import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../models/country.dart';
import '../../services/auth_service.dart';
import '../../services/multiplayer_service.dart';
import '../../services/sound_service.dart';
import '../../services/user_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/flag_box.dart';
import 'multiplayer_lobby_page.dart';

class MultiplayerGamePage extends StatefulWidget {
  final List<Country> countries;
  final String roomId;
  final bool isPlayer1;

  const MultiplayerGamePage({
    super.key,
    required this.countries,
    required this.roomId,
    required this.isPlayer1,
  });

  @override
  State<MultiplayerGamePage> createState() => _MultiplayerGamePageState();
}

class _MultiplayerGamePageState extends State<MultiplayerGamePage> {
  final _service = MultiplayerService();
  final _sound = SoundService();
  final _rnd = Random();

  StreamSubscription? _roomSub;
  GameRoom? _room;

  int _myScore = 0;
  int _myIndex = 0;
  bool _answered = false;
  bool _gameFinished = false;
  bool _resultFinalized = false; // prevents double _finishGame calls
  Country? _selectedOption;
  bool? _lastCorrect;

  Country? _currentFlag;
  List<Country> _options = [];

  Map<String, Country> _cca2Map = {};

  // ── Timer (2 minutes for 20 flags) ───────────────────────────────────────────
  static const _totalSeconds = 120;
  Timer? _gameTimer;
  int _secondsLeft = _totalSeconds;
  bool _timerStarted = false;
  bool _timedOut = false;

  // ── Result screen state ───────────────────────────────────────────────────────
  bool _showResult = false;
  bool _iWon = false;
  int _myFinalScore = 0;
  int _oppFinalScore = 0;
  String _myName = '';
  String _oppName = '';

  @override
  void initState() {
    super.initState();
    _cca2Map = {for (final c in widget.countries) c.cca2: c};
    _roomSub = _service.watchRoom(widget.roomId).listen(_onRoomUpdate);
    // Start timer immediately — both players start at roughly the same time
    _startGameTimer();
  }

  @override
  void dispose() {
    _gameTimer?.cancel();
    _roomSub?.cancel();
    super.dispose();
  }

  // ── Timer ─────────────────────────────────────────────────────────────────────

  void _startGameTimer() {
    _timerStarted = true;
    _gameTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (!mounted) { t.cancel(); return; }
      if (_secondsLeft > 0) {
        setState(() => _secondsLeft--);
      } else {
        t.cancel();
        _onTimerTimeout();
      }
    });
  }

  Future<void> _onTimerTimeout() async {
    if (_timedOut || _resultFinalized) return;
    _timedOut = true;
    // Mark this player as finished with current score
    setState(() => _gameFinished = true);
    await _service.submitAnswer(
      roomId: widget.roomId,
      isPlayer1: widget.isPlayer1,
      newScore: _myScore,
      newIndex: _myIndex,
      finished: true,
    );
    // Safety: if opponent hasn't finished in 20 s, force show result anyway
    Future.delayed(const Duration(seconds: 20), () {
      if (mounted && !_resultFinalized && _room != null) {
        _finalizeResult(_room!);
      }
    });
  }

  String get _timerLabel {
    final m = _secondsLeft ~/ 60;
    final s = _secondsLeft % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  Color get _timerColor {
    if (_secondsLeft > 60) return Colors.white;
    if (_secondsLeft > 30) return Colors.amber;
    return Colors.redAccent;
  }

  // ── Room updates ──────────────────────────────────────────────────────────────

  void _onRoomUpdate(GameRoom? room) {
    if (room == null || !mounted) return;
    setState(() {
      _room = room;
      if (_currentFlag == null && room.flagCodes.isNotEmpty) {
        final flag = _cca2Map[room.flagCodes[0]];
        if (flag != null) {
          _currentFlag = flag;
          _generateOptions(flag);
        }
      }
    });
    if (room.bothFinished && !_resultFinalized) {
      _gameTimer?.cancel();
      _finalizeResult(room);
    }
  }

  void _generateOptions(Country correct) {
    final others = widget.countries
        .where((c) => c.cca2 != correct.cca2)
        .toList()
      ..shuffle(_rnd);
    _options = [correct, ...others.take(9)]..shuffle(_rnd);
  }

  Country? get _myCurrentFlag {
    if (_room == null || _myIndex >= _room!.flagCodes.length) return null;
    return _cca2Map[_room!.flagCodes[_myIndex]];
  }

  // ── Answer logic ──────────────────────────────────────────────────────────────

  Future<void> _answer(Country selected) async {
    if (_answered || _gameFinished || _timedOut) return;
    final correct = _myCurrentFlag;
    if (correct == null) return;

    final isCorrect = selected.cca2 == correct.cca2;
    final newScore = _myScore + (isCorrect ? 100 : 0);
    final newIndex = _myIndex + 1;
    final finished = newIndex >= MultiplayerService.questionCount;

    setState(() {
      _answered = true;
      _selectedOption = selected;
      _lastCorrect = isCorrect;
      _myScore = newScore;
      _myIndex = newIndex;
    });

    if (isCorrect) _sound.playCorrect(); else _sound.playWrong();

    await _service.submitAnswer(
      roomId: widget.roomId,
      isPlayer1: widget.isPlayer1,
      newScore: newScore,
      newIndex: newIndex,
      finished: finished,
    );

    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;

    if (finished) {
      _gameTimer?.cancel();
      setState(() => _gameFinished = true);
    } else {
      final next = _cca2Map[_room!.flagCodes[newIndex]];
      if (next != null) {
        setState(() {
          _answered = false;
          _selectedOption = null;
          _lastCorrect = null;
          _currentFlag = next;
          _generateOptions(next);
        });
      }
    }
  }

  // ── Game completion ───────────────────────────────────────────────────────────

  Future<void> _finalizeResult(GameRoom room) async {
    if (_resultFinalized) return;
    _resultFinalized = true;
    _gameTimer?.cancel();

    final auth = context.read<AuthService>();
    final uid = auth.uid;
    final myName = widget.isPlayer1 ? room.player1Name : (room.player2Name ?? 'You');
    final oppName = widget.isPlayer1 ? (room.player2Name ?? 'Opponent') : room.player1Name;
    final myScore = widget.isPlayer1 ? room.player1Score : room.player2Score;
    final oppScore = widget.isPlayer1 ? room.player2Score : room.player1Score;
    final won = myScore > oppScore;

    if (uid != null) {
      await UserService().recordGameResult(uid: uid, score: myScore, won: won);
      if (won) await UserService().unlockAchievement(uid, 'multiplayer_win');
    }

    if (mounted) {
      setState(() {
        _showResult = true;
        _iWon = won;
        _myFinalScore = myScore;
        _oppFinalScore = oppScore;
        _myName = myName;
        _oppName = oppName;
      });
      if (won) _sound.playSuccess();
    }
  }

  // ── Navigation ────────────────────────────────────────────────────────────────

  void _goHome() {
    Navigator.popUntil(context, (route) => route.isFirst);
  }

  void _rematch() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => MultiplayerLobbyPage(countries: widget.countries),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    if (_showResult) return _buildResultScreen();

    final l10n = AppLocalizations.of(context)!;
    final opponentScore = widget.isPlayer1
        ? (_room?.player2Score ?? 0)
        : (_room?.player1Score ?? 0);
    final opponentName = widget.isPlayer1
        ? (_room?.player2Name ?? l10n.opponent)
        : _room?.player1Name ?? l10n.opponent;
    final opponentIndex = widget.isPlayer1
        ? (_room?.player2Index ?? 0)
        : (_room?.player1Index ?? 0);

    return Scaffold(
      body: Column(
        children: [
          // ── Header ─────────────────────────────────────────────
          Container(
            decoration: const BoxDecoration(gradient: AppColors.gradientPrimary),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _PlayerScoreBox(
                            name: l10n.youLabel,
                            score: _myScore,
                            index: _myIndex,
                            isMe: true,
                          ),
                        ),
                        // Timer in center
                        _TimerBadge(label: _timerLabel, color: _timerColor),
                        Expanded(
                          child: _PlayerScoreBox(
                            name: opponentName,
                            score: opponentScore,
                            index: opponentIndex,
                            isMe: false,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: _myIndex / MultiplayerService.questionCount,
                        backgroundColor: Colors.white.withOpacity(0.2),
                        valueColor: const AlwaysStoppedAnimation(Colors.white),
                        minHeight: 4,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${l10n.question} ${_myIndex + 1} / ${MultiplayerService.questionCount}',
                      style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 12),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Game area ───────────────────────────────────────────
          Expanded(
            child: _gameFinished && !(_room?.bothFinished ?? false)
                ? _buildWaitingForOpponent(l10n)
                : _currentFlag == null
                    ? const Center(child: CircularProgressIndicator())
                    : _buildQuestion(l10n),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestion(AppLocalizations l10n) {
    final flag = _currentFlag!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 16, offset: const Offset(0, 6))],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: FlagBox(url: flag.flagUrl, height: 160),
            ),
          ).animate(key: ValueKey(flag.cca2)).fadeIn(duration: 300.ms).scale(begin: const Offset(0.95, 0.95), end: const Offset(1, 1)),

          const SizedBox(height: 16),

          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            childAspectRatio: 3.0,
            crossAxisSpacing: 8,
            mainAxisSpacing: 8,
            children: _options.asMap().entries.map((e) {
              final i = e.key;
              final opt = e.value;
              Color bg = Colors.white;
              Color border = Colors.grey.shade200;

              if (_answered) {
                if (opt.cca2 == flag.cca2) { bg = AppColors.successLight; border = AppColors.success; }
                else if (opt.cca2 == _selectedOption?.cca2 && !(_lastCorrect ?? true)) {
                  bg = AppColors.errorLight; border = AppColors.error;
                }
              }

              return GestureDetector(
                onTap: _answered ? null : () => _answer(opt),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: bg,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: border, width: 1.5),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 4)],
                  ),
                  child: Center(
                    child: Text(
                      opt.localizedName(context),
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ).animate().fadeIn(delay: Duration(milliseconds: 30 + i * 20), duration: 200.ms);
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildWaitingForOpponent(AppLocalizations l10n) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(width: 48, height: 48, child: CircularProgressIndicator()),
          const SizedBox(height: 20),
          Text(
            _timedOut ? 'Time\'s up! Waiting for opponent...' : l10n.waitingForOpponentFinish,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text('${l10n.score}: $_myScore', style: TextStyle(fontSize: 16, color: Colors.grey.shade600)),
        ],
      ),
    );
  }

  // ── Result Screen ─────────────────────────────────────────────────────────────

  Widget _buildResultScreen() {
    final isDraw = _myFinalScore == _oppFinalScore;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFF1E1B4B), Color(0xFF312E81), Color(0xFFF0F4FF)],
            stops: [0.0, 0.35, 0.6],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 32),

              // Trophy / emoji
              Text(
                isDraw ? '🤝' : (_iWon ? '🏆' : '😔'),
                style: const TextStyle(fontSize: 80),
              ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),

              const SizedBox(height: 12),

              Text(
                isDraw ? 'It\'s a Draw!' : (_iWon ? 'You Won!' : 'You Lost!'),
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  color: isDraw ? Colors.amber : (_iWon ? Colors.greenAccent : Colors.redAccent),
                ),
              ).animate().fadeIn(delay: 200.ms),

              const SizedBox(height: 32),

              // Score comparison
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _ResultPillar(name: _myName, score: _myFinalScore, isWinner: _iWon || isDraw, isMe: true),
                    Text('VS',
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                            fontSize: 18,
                            fontWeight: FontWeight.bold)),
                    _ResultPillar(name: _oppName, score: _oppFinalScore, isWinner: !_iWon || isDraw, isMe: false),
                  ],
                ),
              ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1, end: 0),

              if (_timedOut) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.amber.withOpacity(0.4)),
                  ),
                  child: const Text(
                    '⏱ Time ran out!',
                    style: TextStyle(color: Colors.amber, fontWeight: FontWeight.w600),
                  ),
                ),
              ],

              const Spacer(),

              // Buttons
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 0, 24, 32),
                child: Column(
                  children: [
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton.icon(
                        onPressed: _rematch,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4F46E5),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          elevation: 0,
                        ),
                        icon: const Icon(Icons.replay_rounded),
                        label: const Text('Rematch', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                      ),
                    ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.2, end: 0),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: OutlinedButton.icon(
                        onPressed: _goHome,
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white70,
                          side: const BorderSide(color: Colors.white30),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                        ),
                        icon: const Icon(Icons.home_rounded),
                        label: const Text('Go Home', style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
                      ),
                    ).animate().fadeIn(delay: 600.ms).slideY(begin: 0.2, end: 0),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Widgets ───────────────────────────────────────────────────────────────────

class _TimerBadge extends StatelessWidget {
  final String label;
  final Color color;
  const _TimerBadge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: color == Colors.redAccent
            ? Colors.redAccent.withOpacity(0.25)
            : Colors.white.withOpacity(0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.6), width: 1.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.timer_outlined, color: color, size: 14),
          const SizedBox(width: 4),
          Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w900, fontSize: 15)),
        ],
      ),
    );
  }
}

class _PlayerScoreBox extends StatelessWidget {
  final String name;
  final int score;
  final int index;
  final bool isMe;
  const _PlayerScoreBox({required this.name, required this.score, required this.index, required this.isMe});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: isMe ? CrossAxisAlignment.start : CrossAxisAlignment.end,
      children: [
        Text(name, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13), overflow: TextOverflow.ellipsis),
        Text('$score pts', style: TextStyle(color: Colors.white.withOpacity(0.9), fontWeight: FontWeight.w900, fontSize: 18)),
        Text('Q$index/${MultiplayerService.questionCount}', style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 11)),
      ],
    );
  }
}

class _ResultPillar extends StatelessWidget {
  final String name;
  final int score;
  final bool isWinner;
  final bool isMe;
  const _ResultPillar({required this.name, required this.score, required this.isWinner, required this.isMe});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (isWinner) const Text('🏆', style: TextStyle(fontSize: 26)),
        CircleAvatar(
          radius: 30,
          backgroundColor: isMe
              ? AppColors.primary.withOpacity(0.4)
              : Colors.white.withOpacity(0.15),
          child: Text(
            name.isNotEmpty ? name[0].toUpperCase() : '?',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 22),
          ),
        ),
        const SizedBox(height: 8),
        Text(name,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
            overflow: TextOverflow.ellipsis),
        const SizedBox(height: 4),
        Text(
          '$score pts',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w900,
            color: isWinner ? Colors.greenAccent : Colors.redAccent.shade100,
          ),
        ),
      ],
    );
  }
}
