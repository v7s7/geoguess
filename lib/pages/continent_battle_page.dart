import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../models/country.dart';
import '../models/game_config.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../theme/app_theme.dart';
import 'game_page.dart';

class ContinentBattlePage extends StatefulWidget {
  final List<Country> countries;
  const ContinentBattlePage({super.key, required this.countries});

  @override
  State<ContinentBattlePage> createState() => _ContinentBattlePageState();
}

class _ContinentBattlePageState extends State<ContinentBattlePage> {
  Map<String, int> _stars = {};
  bool _loading = true;

  static const _continents = [
    _ContinentInfo('Africa',   '🌍', Color(0xFF10B981), 'Africa'),
    _ContinentInfo('Americas', '🌎', Color(0xFF3B82F6), 'Americas'),
    _ContinentInfo('Asia',     '🌏', Color(0xFFEC4899), 'Asia'),
    _ContinentInfo('Europe',   '🇪🇺', Color(0xFF8B5CF6), 'Europe'),
    _ContinentInfo('Oceania',  '🌊', Color(0xFF06B6D4), 'Oceania'),
    _ContinentInfo('Antarctic','❄️', Color(0xFF64748B), 'Antarctic'),
  ];

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    final uid = context.read<AuthService>().uid;
    if (uid != null) {
      final profile = await UserService().getProfile(uid);
      if (mounted && profile != null) {
        setState(() {
          _stars = profile.continentStars;
          _loading = false;
        });
        return;
      }
    }
    setState(() => _loading = false);
  }

  int _starsFor(String region) => _stars[region] ?? 0;

  void _startBattle(_ContinentInfo info) {
    final filtered = widget.countries
        .where((c) => c.region == info.region)
        .toList();

    if (filtered.isEmpty) return;

    final config = GameConfig(
      mode: GameMode.quiz,
      questionCount: filtered.length,
      choicesCount: 4,
    );

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => GamePage(
          countries: filtered,
          config: config,
          onFinished: (score, correctAnswers) => _onBattleFinished(info, filtered.length, correctAnswers),
        ),
      ),
    );
  }

  Future<void> _onBattleFinished(_ContinentInfo info, int totalFlags, int correctAnswers) async {
    final accuracy = totalFlags > 0 ? correctAnswers / totalFlags : 0.0;
    final newStars = accuracy >= 0.9 ? 3 : accuracy >= 0.7 ? 2 : accuracy >= 0.5 ? 1 : 0;
    final uid = context.read<AuthService>().uid;
    if (uid != null) {
      await UserService().updateContinentStars(uid, info.region, newStars);
      if (mounted) {
        setState(() {
          final current = _stars[info.region] ?? 0;
          if (newStars > current) _stars = Map.from(_stars)..[info.region] = newStars;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [Color(0xFF059669), Color(0xFF10B981)]),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 16, 20),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Continent Battles', style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                          Text('Master every region!', style: TextStyle(color: Colors.white70, fontSize: 13)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : GridView.builder(
                    padding: const EdgeInsets.all(20),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 0.85,
                    ),
                    itemCount: _continents.length,
                    itemBuilder: (context, i) {
                      final info = _continents[i];
                      final stars = _starsFor(info.region);
                      final count = widget.countries.where((c) => c.region == info.region).length;
                      return _ContinentCard(
                        info: info,
                        stars: stars,
                        flagCount: count,
                        onTap: () => _startBattle(info),
                        delay: i * 80,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _ContinentInfo {
  final String name;
  final String emoji;
  final Color color;
  final String region;
  const _ContinentInfo(this.name, this.emoji, this.color, this.region);
}

class _ContinentCard extends StatelessWidget {
  final _ContinentInfo info;
  final int stars;
  final int flagCount;
  final VoidCallback onTap;
  final int delay;

  const _ContinentCard({
    required this.info,
    required this.stars,
    required this.flagCount,
    required this.onTap,
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    final completed = stars == 3;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: completed ? AppColors.gold : Colors.grey.shade200,
            width: completed ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: (completed ? AppColors.gold : Colors.black).withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Emoji circle
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: info.color.withOpacity(0.12),
              ),
              child: Center(
                child: Text(info.emoji, style: const TextStyle(fontSize: 30)),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              info.name,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
            ),
            const SizedBox(height: 2),
            Text(
              '$flagCount flags',
              style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
            ),
            const SizedBox(height: 10),
            // Stars
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (i) => Icon(
                i < stars ? Icons.star_rounded : Icons.star_outline_rounded,
                color: i < stars ? Colors.amber : Colors.grey.shade300,
                size: 22,
              )),
            ),
            if (stars > 0) ...[
              const SizedBox(height: 4),
              Text(
                stars == 3 ? 'Mastered! ✨' : stars == 2 ? 'Good!' : 'Started',
                style: TextStyle(fontSize: 11, color: info.color, fontWeight: FontWeight.w600),
              ),
            ],
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(delay: Duration(milliseconds: delay), duration: 350.ms)
        .slideY(begin: 0.2, end: 0);
  }
}
