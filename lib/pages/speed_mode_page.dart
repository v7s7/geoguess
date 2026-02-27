import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../models/country.dart';
import '../services/auth_service.dart';
import '../services/sound_service.dart';
import '../services/user_service.dart';
import '../theme/app_theme.dart';
import '../widgets/flag_box.dart';

class SpeedModePage extends StatefulWidget {
  final List<Country> countries;
  const SpeedModePage({super.key, required this.countries});

  @override
  State<SpeedModePage> createState() => _SpeedModePageState();
}

class _SpeedModePageState extends State<SpeedModePage>
    with TickerProviderStateMixin {
  static const int totalSeconds = 60;
  static const int choicesCount = 4;

  final _sound = SoundService();
  final _rnd = Random();

  Timer? _timer;
  int _timeLeft = totalSeconds;
  int _score = 0;
  int _correct = 0;
  int _total = 0;
  bool _started = false;
  bool _finished = false;

  late Country _currentCountry;
  late List<Country> _options;

  // Flash state
  Country? _selectedOption;
  bool? _lastCorrect;

  @override
  void initState() {
    super.initState();
    _generateQuestion();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _start() {
    setState(() => _started = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (_timeLeft > 0) {
        setState(() => _timeLeft--);
        if (_timeLeft <= 5) _sound.playTick();
      } else {
        _finish();
      }
    });
  }

  void _generateQuestion() {
    final shuffled = List<Country>.from(widget.countries)..shuffle(_rnd);
    _currentCountry = shuffled.first;

    final distractors = shuffled
        .where((c) => c.cca2 != _currentCountry.cca2)
        .take(choicesCount - 1)
        .toList();
    _options = [...distractors, _currentCountry]..shuffle(_rnd);
    _selectedOption = null;
    _lastCorrect = null;
  }

  Future<void> _answer(Country selected) async {
    if (!_started || _finished) return;
    final isCorrect = selected.cca2 == _currentCountry.cca2;

    setState(() {
      _selectedOption = selected;
      _lastCorrect = isCorrect;
      _total++;
      if (isCorrect) {
        _correct++;
        _score += 100;
      }
    });

    if (isCorrect) {
      _sound.playCorrect();
    } else {
      _sound.playWrong();
    }

    // Very short flash then next question
    await Future.delayed(const Duration(milliseconds: 350));
    if (!mounted || _finished) return;
    setState(() => _generateQuestion());
  }

  Future<void> _finish() async {
    _timer?.cancel();
    setState(() => _finished = true);
    _sound.playSuccess();

    // Save high score
    final uid = context.read<AuthService>().uid;
    if (uid != null) {
      await UserService().updateSpeedScore(uid, _score);
    }
  }

  Color _optionColor(Country option) {
    if (_selectedOption == null) return Colors.white;
    if (option.cca2 == _currentCountry.cca2) return AppColors.successLight;
    if (option.cca2 == _selectedOption!.cca2 && !(_lastCorrect ?? true)) {
      return AppColors.errorLight;
    }
    return Colors.white;
  }

  Color _optionBorder(Country option) {
    if (_selectedOption == null) return Colors.grey.shade200;
    if (option.cca2 == _currentCountry.cca2) return AppColors.success;
    if (option.cca2 == _selectedOption!.cca2 && !(_lastCorrect ?? true)) {
      return AppColors.error;
    }
    return Colors.grey.shade200;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          // ── Header ─────────────────────────────────────────────
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFFDC2626), Color(0xFFEF4444)],
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 16, 16),
                child: Column(
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const Expanded(
                          child: Text(
                            '⚡ Speed Mode',
                            style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                        ),
                        // Score
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                              const SizedBox(width: 4),
                              Text('$_score', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    // Timer bar
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Row(
                        children: [
                          const Icon(Icons.timer_rounded, color: Colors.white70, size: 16),
                          const SizedBox(width: 6),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: _timeLeft / totalSeconds,
                                backgroundColor: Colors.white.withOpacity(0.2),
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  _timeLeft > 20 ? Colors.white : Colors.amber,
                                ),
                                minHeight: 6,
                              ),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text('${_timeLeft}s', style: TextStyle(
                            color: _timeLeft <= 10 ? Colors.amber : Colors.white,
                            fontWeight: FontWeight.bold,
                          )),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          Expanded(
            child: _finished
                ? _buildResults()
                : !_started
                    ? _buildSplash()
                    : _buildGame(),
          ),
        ],
      ),
    );
  }

  Widget _buildSplash() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.bolt, size: 80, color: AppColors.warning).animate().scale(duration: 600.ms, curve: Curves.elasticOut),
          const SizedBox(height: 16),
          const Text('⚡ SPEED MODE', style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.black87)),
          const SizedBox(height: 8),
          Text('Answer as many flags as possible in 60 seconds!',
              style: TextStyle(fontSize: 16, color: Colors.grey.shade600), textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Text('4 choices · instant feedback · no waiting',
              style: TextStyle(fontSize: 13, color: Colors.grey.shade400)),
          const SizedBox(height: 40),
          GestureDetector(
            onTap: _start,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFFDC2626), Color(0xFFEF4444)]),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: Colors.red.withOpacity(0.4), blurRadius: 16, offset: const Offset(0, 6))],
              ),
              child: const Text('START!', style: TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900, letterSpacing: 2)),
            ),
          ).animate().fadeIn(delay: 400.ms).scale(begin: const Offset(0.9, 0.9), end: const Offset(1, 1)),
        ],
      ),
    );
  }

  Widget _buildGame() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          // Stats row
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _StatPill('✅ $_correct', Colors.green),
              const SizedBox(width: 12),
              _StatPill('❌ ${_total - _correct}', Colors.red),
              const SizedBox(width: 12),
              _StatPill('🏳 $_total total', Colors.blue),
            ],
          ),
          const SizedBox(height: 16),
          // Flag
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 20, offset: const Offset(0, 6))],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: FlagBox(url: _currentCountry.flagUrl, height: 180),
            ),
          ).animate(key: ValueKey(_currentCountry.cca2)).fadeIn(duration: 200.ms).scale(begin: const Offset(0.95, 0.95), end: const Offset(1, 1)),

          const SizedBox(height: 20),

          // 4 choice buttons
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            childAspectRatio: 2.6,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            children: _options.map((option) {
              return GestureDetector(
                onTap: () => _answer(option),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  decoration: BoxDecoration(
                    color: _optionColor(option),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _optionBorder(option), width: 2),
                    boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 6)],
                  ),
                  child: Center(
                    child: Text(
                      option.nameEn,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildResults() {
    final accuracy = _total > 0 ? (_correct / _total * 100).toInt() : 0;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.timer_off_rounded, size: 64, color: AppColors.error).animate().scale(duration: 500.ms, curve: Curves.elasticOut),
            const SizedBox(height: 16),
            const Text("Time's Up!", style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900)),
            const SizedBox(height: 32),
            _ResultCard(label: 'Score', value: '$_score', color: AppColors.primary, icon: Icons.star_rounded),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(child: _ResultCard(label: 'Correct', value: '$_correct', color: AppColors.success, icon: Icons.check_rounded)),
                const SizedBox(width: 12),
                Expanded(child: _ResultCard(label: 'Accuracy', value: '$accuracy%', color: AppColors.warning, icon: Icons.percent_rounded)),
              ],
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(colors: [Color(0xFFDC2626), Color(0xFFEF4444)]),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: ElevatedButton.icon(
                  onPressed: () {
                    setState(() {
                      _timeLeft = totalSeconds;
                      _score = 0;
                      _correct = 0;
                      _total = 0;
                      _started = false;
                      _finished = false;
                      _generateQuestion();
                    });
                  },
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                  icon: const Icon(Icons.replay_rounded),
                  label: const Text('Play Again', style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold)),
                ),
              ),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => Navigator.pop(context),
              icon: const Icon(Icons.home_rounded),
              label: const Text('Home'),
              style: OutlinedButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatPill extends StatelessWidget {
  final String label;
  final Color color;
  const _StatPill(this.label, this.color);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(label, style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12)),
    );
  }
}

class _ResultCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;
  const _ResultCard({required this.label, required this.value, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: TextStyle(fontSize: 12, color: Colors.grey.shade500)),
              Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
            ],
          ),
        ],
      ),
    );
  }
}
