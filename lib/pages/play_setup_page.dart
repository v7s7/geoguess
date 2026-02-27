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
      if (mounted) {
        setState(() {
          _countries = countries;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    }
  }

  void _onQuestionCountChanged(int count) {
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
    if (result == true && mounted) {
      setState(() => _questionCount = 254);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isPremium = context.watch<PurchaseService>().isPremium;

    if (_error != null) return _buildErrorState(l10n);
    if (_isLoading) return _buildLoadingState(l10n);

    return Scaffold(
      body: Column(
        children: [
          // ─── Gradient Header ─────────────────────────────────
          Container(
            decoration: const BoxDecoration(gradient: AppColors.gradientPrimary),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 16, 20),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded,
                          color: Colors.white),
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

          // ─── Content ─────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 1. Game Mode
                  _SectionHeader(label: l10n.gameMode),
                  Row(
                    children: [
                      Expanded(
                        child: _ModeCard(
                          icon: Icons.quiz_rounded,
                          title: l10n.quizMode,
                          subtitle: 'Pick the right flag',
                          isSelected: _mode == GameMode.quiz,
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
                          isSelected: _mode == GameMode.practice,
                          color: AppColors.success,
                          onTap: () =>
                              setState(() => _mode = GameMode.practice),
                        ),
                      ),
                    ],
                  ).animate().fadeIn(delay: 50.ms).slideY(begin: 0.1, end: 0),

                  const SizedBox(height: 28),

                  // 2. Question Count
                  _SectionHeader(label: l10n.questionsCount),
                  _buildQuestionCountGrid(isPremium, l10n),

                  const SizedBox(height: 28),

                  // 3. Timer
                  _SectionHeader(label: l10n.timer),
                  _buildTimerChips(l10n),

                  const SizedBox(height: 28),

                  // 4. Hints
                  _SectionHeader(label: l10n.enableHints),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _HintTile(
                          title: l10n.showContinentHint,
                          icon: Icons.public_rounded,
                          value: _useRegionHint,
                          onChanged: (v) => setState(() => _useRegionHint = v),
                        ),
                        const Divider(height: 1, indent: 16),
                        _HintTile(
                          title: l10n.showCapitalHint,
                          icon: Icons.location_city_rounded,
                          value: _useCapitalHint,
                          onChanged: (v) =>
                              setState(() => _useCapitalHint = v),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(delay: 250.ms).slideY(begin: 0.1, end: 0),

                  // 5. Choices (quiz only)
                  if (_mode == GameMode.quiz) ...[
                    const SizedBox(height: 28),
                    _SectionHeader(
                      label:
                          '${l10n.choicesCount}: ${_choicesCount == 0 ? l10n.typeMode : _choicesCount}',
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 10,
                          ),
                        ],
                      ),
                      child: SliderTheme(
                        data: SliderTheme.of(context).copyWith(
                          activeTrackColor: _choicesCount == 0
                              ? AppColors.error
                              : AppColors.primary,
                          thumbColor: _choicesCount == 0
                              ? AppColors.error
                              : AppColors.primary,
                          overlayColor: (_choicesCount == 0
                                  ? AppColors.error
                                  : AppColors.primary)
                              .withOpacity(0.15),
                          inactiveTrackColor: Colors.grey.shade200,
                          valueIndicatorColor: _choicesCount == 0
                              ? AppColors.error
                              : AppColors.primary,
                          valueIndicatorTextStyle: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        child: Slider(
                          value: _choicesCount.toDouble(),
                          min: 0,
                          max: 15,
                          divisions: 15,
                          label: _choicesCount == 0
                              ? 'Type'
                              : _choicesCount.toString(),
                          onChanged: (val) =>
                              setState(() => _choicesCount = val.toInt()),
                        ),
                      ),
                    ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1, end: 0),
                    if (_choicesCount == 0)
                      Padding(
                        padding: const EdgeInsets.only(top: 8, left: 4),
                        child: Row(
                          children: [
                            const Icon(Icons.keyboard_alt_outlined,
                                size: 14, color: AppColors.error),
                            const SizedBox(width: 6),
                            Text(
                              'You\'ll type the country name',
                              style: TextStyle(
                                  fontSize: 12, color: AppColors.error),
                            ),
                          ],
                        ),
                      ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),

      // ─── Start Button ──────────────────────────────────────────
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: SizedBox(
          width: double.infinity,
          height: 60,
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: AppColors.gradientPrimary,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withOpacity(0.4),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ElevatedButton.icon(
              onPressed: () {
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
                      builder: (_) =>
                          GamePage(countries: _countries, config: config)),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(18)),
              ),
              icon: const Icon(Icons.play_circle_fill_rounded, size: 24),
              label: Text(
                l10n.start,
                style: const TextStyle(
                    fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildQuestionCountGrid(bool isPremium, AppLocalizations l10n) {
    const counts = [5, 10, 20, 50, 100, 254];
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: counts.map((count) {
        final isAll = count == 254;
        final isLocked = isAll && !isPremium;
        final isSelected = _questionCount == count;

        return GestureDetector(
          onTap: () => _onQuestionCountChanged(count),
          child: AnimatedContainer(
            duration: 200.ms,
            padding:
                const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary
                  : isLocked
                      ? const Color(0xFF1A1A2E)
                      : Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isSelected
                    ? AppColors.primary
                    : isLocked
                        ? Colors.amber.withOpacity(0.4)
                        : Colors.grey.shade200,
                width: isSelected ? 2 : 1,
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
                  const Icon(Icons.workspace_premium,
                      size: 14, color: Colors.amber),
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
    ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildTimerChips(AppLocalizations l10n) {
    final options = <int?>[null, 10, 15, 20, 30, 60];
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: options.map((seconds) {
        final isSelected = _timerSeconds == seconds;
        final label =
            seconds == null ? l10n.off : '$seconds ${l10n.seconds}';

        return GestureDetector(
          onTap: () => setState(() => _timerSeconds = seconds),
          child: AnimatedContainer(
            duration: 200.ms,
            padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.accent : Colors.white,
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
    ).animate().fadeIn(delay: 150.ms).slideY(begin: 0.1, end: 0);
  }

  Widget _buildLoadingState(AppLocalizations l10n) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(gradient: AppColors.gradientHero),
        child: const Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CircularProgressIndicator(color: Colors.white),
              SizedBox(height: 16),
              Text('Loading...', style: TextStyle(color: Colors.white)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(AppLocalizations l10n) {
    return Scaffold(
      body: Center(
        child: Text(l10n.error,
            style: const TextStyle(color: AppColors.error)),
      ),
    );
  }
}

// ─── Section Header ───────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(
        label,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }
}

// ─── Mode Card ────────────────────────────────────────────────────────────────

class _ModeCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isSelected;
  final Color color;
  final VoidCallback onTap;

  const _ModeCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.isSelected,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: 200.ms,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? color : Colors.grey.shade200,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 28, color: isSelected ? color : Colors.grey),
            const SizedBox(height: 10),
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: isSelected ? color : Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              subtitle,
              style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Hint Tile ────────────────────────────────────────────────────────────────

class _HintTile extends StatelessWidget {
  final String title;
  final IconData icon;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _HintTile({
    required this.title,
    required this.icon,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SwitchListTile(
      value: value,
      onChanged: onChanged,
      title: Text(title,
          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
      secondary: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Icon(icon, color: AppColors.primary, size: 20),
      ),
      activeColor: AppColors.primary,
    );
  }
}
