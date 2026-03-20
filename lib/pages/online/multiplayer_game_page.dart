import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../models/country.dart';
import '../../services/auth_service.dart';
import '../../services/multiplayer_service.dart';
import '../../services/sound_service.dart';
import '../../services/user_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/flag_box.dart';

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
  Country? _selectedOption;
  bool? _lastCorrect;

  // For current question
  Country? _currentFlag;
  List<Country> _options = [];

  Map<String, Country> _cca2Map = {};

  @override
  void initState() {
    super.initState();
    // Build cca2 → Country map
    _cca2Map = {for (final c in widget.countries) c.cca2: c};

    _roomSub = _service.watchRoom(widget.roomId).listen(_onRoomUpdate);
  }

  @override
  void dispose() {
    _roomSub?.cancel();
    super.dispose();
  }

  void _onRoomUpdate(GameRoom? room) {
    if (room == null || !mounted) return;
    setState(() {
      _room = room;
      // Initialize the first flag the first time we receive room data.
      if (_currentFlag == null && room.flagCodes.isNotEmpty) {
        final flag = _cca2Map[room.flagCodes[0]];
        if (flag != null) {
          _currentFlag = flag;
          _generateOptions(flag);
        }
      }
    });
    if (room.bothFinished && !_gameFinished) {
      _finishGame(room);
    }
  }

  void _generateOptions(Country correct) {
    final others = widget.countries
        .where((c) => c.cca2 != correct.cca2)
        .toList()
      ..shuffle(_rnd);
    _options = [correct, ...others.take(9)]..shuffle(_rnd); // 10 choices
  }

  Country? get _myCurrentFlag {
    if (_room == null || _myIndex >= _room!.flagCodes.length) return null;
    return _cca2Map[_room!.flagCodes[_myIndex]];
  }

  Future<void> _answer(Country selected) async {
    if (_answered || _gameFinished) return;
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

    // Push to Firebase
    await _service.submitAnswer(
      roomId: widget.roomId,
      isPlayer1: widget.isPlayer1,
      newScore: newScore,
      newIndex: newIndex,
      finished: finished,
    );

    // Short pause for feedback, then next question
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;

    if (finished) {
      // Wait for opponent or timeout after 30s
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

  void _finishGame(GameRoom room) async {
    final auth = context.read<AuthService>();
    final uid = auth.uid;
    if (uid == null) return;

    final myFinalScore = widget.isPlayer1 ? room.player1Score : room.player2Score;
    final oppScore = widget.isPlayer1 ? room.player2Score : room.player1Score;
    final won = myFinalScore > oppScore;

    await UserService().recordGameResult(uid: uid, score: myFinalScore, won: won);
    if (won) {
      await UserService().unlockAchievement(uid, 'multiplayer_win');
    }

    if (mounted) {
      _showResult(room, won);
    }
  }

  void _showResult(GameRoom room, bool won) {
    final myName = widget.isPlayer1 ? room.player1Name : room.player2Name ?? 'You';
    final oppName = widget.isPlayer1 ? (room.player2Name ?? 'Opponent') : room.player1Name;
    final myScore = widget.isPlayer1 ? room.player1Score : room.player2Score;
    final oppScore = widget.isPlayer1 ? room.player2Score : room.player1Score;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(won ? '🏆 You Won!' : '😔 You Lost',
                style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _ScorePillar(name: myName, score: myScore, isMe: true, won: won),
                Text('VS', style: TextStyle(fontSize: 16, color: Colors.grey.shade500, fontWeight: FontWeight.bold)),
                _ScorePillar(name: oppName, score: oppScore, isMe: false, won: !won),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).pop();
                },
                child: const Text('Back to Home'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final opponentScore = widget.isPlayer1
        ? (_room?.player2Score ?? 0)
        : (_room?.player1Score ?? 0);
    final opponentName = widget.isPlayer1
        ? (_room?.player2Name ?? 'Opponent')
        : _room?.player1Name ?? 'Opponent';
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
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: Column(
                  children: [
                    // VS row
                    Row(
                      children: [
                        // Me
                        Expanded(
                          child: _PlayerScoreBox(
                            name: 'You',
                            score: _myScore,
                            index: _myIndex,
                            isMe: true,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Text('VS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 16)),
                        ),
                        // Opponent
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
                    // Progress
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
                      'Question ${_myIndex + 1} / ${MultiplayerService.questionCount}',
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
                ? _buildWaitingForOpponent()
                : _currentFlag == null
                    ? const Center(child: CircularProgressIndicator())
                    : _buildQuestion(),
          ),
        ],
      ),
    );
  }

  Widget _buildQuestion() {
    final flag = _currentFlag!;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Flag
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

          // 10 choices in 2-column grid
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
                      opt.nameEn,
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

  Widget _buildWaitingForOpponent() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(width: 48, height: 48, child: CircularProgressIndicator()),
          const SizedBox(height: 20),
          const Text('Waiting for opponent to finish...', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Your score: $_myScore', style: TextStyle(fontSize: 16, color: Colors.grey.shade600)),
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

class _ScorePillar extends StatelessWidget {
  final String name;
  final int score;
  final bool isMe;
  final bool won;
  const _ScorePillar({required this.name, required this.score, required this.isMe, required this.won});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (won) const Text('🏆', style: TextStyle(fontSize: 24)),
        CircleAvatar(
          radius: 28,
          backgroundColor: isMe ? AppColors.primary : Colors.grey.shade300,
          child: Text(name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: TextStyle(color: isMe ? Colors.white : Colors.black87, fontWeight: FontWeight.bold, fontSize: 20)),
        ),
        const SizedBox(height: 8),
        Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
        Text('$score pts', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900,
            color: won ? AppColors.success : AppColors.error)),
      ],
    );
  }
}
