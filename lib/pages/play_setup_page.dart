import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import 'package:geoguess_flags/l10n/app_localizations.dart';
import '../models/country.dart';
import '../models/game_config.dart';
import '../services/country_api.dart';
import '../services/purchase_service.dart';
import '../theme/app_theme.dart';
import 'game_page.dart';
import 'paywall_page.dart';

class PlaySetupPage extends StatefulWidget {
  const PlaySetupPage({super.key});

  @override
  State<PlaySetupPage> createState() => _PlaySetupPageState();
}

class _PlaySetupPageState extends State<PlaySetupPage> {
  GameMode _mode = GameMode.quiz;
  int _questionCount = 10;
  int _choicesCount = 4;
  int? _timerSeconds;
  bool _useRegionHint = false;
  bool _useCapitalHint = false;

  bool _isLoading = true;
  List<Country> _countries = [];
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final countries = await CountryApi().fetchCountries();
      if (mounted) setState(() { _countries = countries; _isLoading = false; });
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  void _onQuestionCountTap(int count) {
    final isPremium = context.read<PurchaseService>().isPremium;
    if (count == 254 && !isPremium) {
      _showPaywall();
      return;
    }
    setState(() => _questionCount = count);
  }

  Future<void> _showPaywall() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(builder: (_) => const PaywallPage()),
    );
    if (result == true && mounted) setState(() => _questionCount = 254);
  }

  void _startGame() {
    final config = GameConfig(
      mode: _mode,
      questionCount: _questionCount,
      choicesCount: _choicesCount,
      timerSeconds: _timerSeconds,
      showRegionHint: _useRegionHint,
      showCapitalHint: _useCapitalHint,
    );
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) => GamePage(countries: _countries, config: config),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isPremium = context.watch<PurchaseService>().isPremium;

    if (_error != null) {
      return Scaffold(
        body: Center(child: Text(l10n.error, style: const TextStyle(color: AppColors.error))),
      );
    }

    if (_isLoading) {
      return Scaffold(
        body: Container(
          decoration: const BoxDecoration(gradient: AppColors.gradientHero),
          child: const Center(
            child: CircularProgressIndicator(color: Colors.white),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          // ── Header ─────────────────────────────────────
          Container(
            decoration: const BoxDecoration(
              gradient: AppColors.gradientPrimary,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(4, 4, 16, 20),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded,
                          color: Colors.white, size: 20),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Expanded(
                      child: Text(
                        'Game Setup',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Content ────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 110),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Mode
                  _Label(l10n.gameMode),
                  Row(
                    children: [
                      Expanded(
                        child: _ModeCard(
                          icon: Icons.quiz_rounded,
                          title: l10n.quizMode,
                          subtitle: 'Pick the right flag',
                          selected: _mode == GameMode.quiz,
                          color: AppColors.primary,
                          onTap: () => setState(() => _mode = GameMode.quiz),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _ModeCard(
                          icon: Icons.school_rounded,
                          title: l10n.practiceMode,
                          subtitle: 'Learn at your pace',
                          selected: _mode == GameMode.practice,
                          color: AppColors.success,
                          onTap: () => setState(() => _mode = GameMode.practice),
                        ),
                      ),
                    ],
                  ).animate().fadeIn(delay: 50.ms).slideY(begin: 0.08, end: 0),

                  const SizedBox(height: 26),

                  // 2. Questions
                  _Label(l10n.questionsCount),
                  _buildQuestionChips(isPremium, l10n),

                  const SizedBox(height: 26),

                  // 3. Timer
                  _Label(l10n.timer),
                  _buildTimerChips(l10n),

                  const SizedBox(height: 26),

                  // 4. Choices (quiz only)
                  if (_mode == GameMode.quiz) ...[
                    _Label(
                      '${l10n.choicesCount}: ${_choicesCount == 0 ? l10n.typeMode : '$_choicesCount'}',
                    ),
                    _buildChoicesSlider(),
                    const SizedBox(height: 26),
                  ],

                  // 5. Hints
                  _Label(l10n.enableHints),
                  _buildHintsCard(l10n),
                ],
              ),
            ),
          ),
        ],
      ),

      // ── Start FAB ─────────────────────────────────────
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: SizedBox(
          width: double.infinity,
          height: 62,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: AppColors.gradientPrimary,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.45),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ElevatedButton.icon(
              onPressed: _startGame,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20)),
              ),
              icon: const Icon(Icons.play_circle_fill_rounded, size: 26),
              label: Text(
                l10n.start,
                style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuestionChips(bool isPremium, AppLocalizations l10n) {
    const counts = [5, 10, 20, 50, 100, 254];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: counts.map((count) {
        final isAll = count == 254;
        final isLocked = isAll && !isPremium;
        final isSelected = _questionCount == count;

        return GestureDetector(
          onTap: () => _onQuestionCountTap(count),
          child: AnimatedContainer(
            duration: 200.ms,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary
                  : isLocked
                      ? const Color(0xFF1A1A2E)
                      : AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected
                    ? AppColors.primary
                    : isLocked
                        ? Colors.amber.withOpacity(0.4)
                        : Colors.grey.shade200,
              ),
              boxShadow: [
                BoxShadow(
                  color: isSelected
                      ? AppColors.primary.withOpacity(0.3)
                      : Colors.black.withOpacity(0.03),
                  blurRadius: isSelected ? 8 : 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isLocked) ...[
                  const Icon(Icons.workspace_premium, size: 13, color: Colors.amber),
                  const SizedBox(width: 4),
                ],
                Text(
                  isAll ? '${l10n.all} (254)' : '$count',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: isSelected
                        ? Colors.white
                        : isLocked
                            ? Colors.amber
                            : Colors.black87,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.08, end: 0);
  }

  Widget _buildTimerChips(AppLocalizations l10n) {
    final options = <int?>[null, 10, 15, 20, 30, 60];
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((s) {
        final isSelected = _timerSeconds == s;
        final label = s == null ? l10n.off : '$s ${l10n.seconds}';
        return GestureDetector(
          onTap: () => setState(() => _timerSeconds = s),
          child: AnimatedContainer(
            duration: 200.ms,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.accent : AppColors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected ? AppColors.accent : Colors.grey.shade200,
              ),
              boxShadow: [
                BoxShadow(
                  color: isSelected
                      ? AppColors.accent.withOpacity(0.3)
                      : Colors.black.withOpacity(0.03),
                  blurRadius: isSelected ? 8 : 4,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Text(
              label,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: isSelected ? Colors.white : Colors.black87,
              ),
            ),
          ),
        );
      }).toList(),
    ).animate().fadeIn(delay: 150.ms).slideY(begin: 0.08, end: 0);
  }

  Widget _buildChoicesSlider() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
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
          SliderTheme(
            data: SliderTheme.of(context).copyWith(
              activeTrackColor: _choicesCount == 0 ? AppColors.error : AppColors.primary,
              thumbColor: _choicesCount == 0 ? AppColors.error : AppColors.primary,
              overlayColor: (_choicesCount == 0 ? AppColors.error : AppColors.primary)
                  .withOpacity(0.12),
              inactiveTrackColor: Colors.grey.shade200,
              valueIndicatorColor:
                  _choicesCount == 0 ? AppColors.error : AppColors.primary,
              valueIndicatorTextStyle:
                  const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
            child: Slider(
              value: _choicesCount.toDouble(),
              min: 0,
              max: 15,
              divisions: 15,
              label: _choicesCount == 0 ? 'Type' : '$_choicesCount',
              onChanged: (val) => setState(() => _choicesCount = val.toInt()),
            ),
          ),
          if (_choicesCount == 0)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.keyboard_alt_outlined,
                      size: 13, color: AppColors.error),
                  const SizedBox(width: 5),
                  Text(
                    'You\'ll type the country name',
                    style: TextStyle(fontSize: 12, color: AppColors.error),
                  ),
                ],
              ),
            ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.08, end: 0);
  }

  Widget _buildHintsCard(AppLocalizations l10n) {
    return Container(
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
          SwitchListTile(
            value: _useRegionHint,
            onChanged: (v) => setState(() => _useRegionHint = v),
            title: Text(l10n.showContinentHint,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            secondary: _HintIcon(icon: Icons.public_rounded),
            activeColor: AppColors.primary,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
          ),
          const Divider(height: 1, indent: 14),
          SwitchListTile(
            value: _useCapitalHint,
            onChanged: (v) => setState(() => _useCapitalHint = v),
            title: Text(l10n.showCapitalHint,
                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
            secondary: _HintIcon(icon: Icons.location_city_rounded),
            activeColor: AppColors.primary,
            contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 250.ms).slideY(begin: 0.08, end: 0);
  }
}

// ─── Helpers ──────────────────────────────────────────────────────────────────

class _Label extends StatelessWidget {
  final String text;
  const _Label(this.text);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: Colors.black87,
          ),
        ),
      );
}

class _HintIcon extends StatelessWidget {
  final IconData icon;
  const _HintIcon({required this.icon});
  @override
  Widget build(BuildContext context) => Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.09),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppColors.primary, size: 18),
      );
}

class _ModeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final Color color;
  final VoidCallback onTap;

  const _ModeCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: 200.ms,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? color.withOpacity(0.08) : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? color : Colors.grey.shade200,
            width: selected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 26, color: selected ? color : Colors.grey),
            const SizedBox(height: 8),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 13,
                color: selected ? color : Colors.black87,
              ),
            ),
            const SizedBox(height: 2),
            Text(subtitle, style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
          ],
        ),
      ),
    );
  }
}
