import 'package:flutter/material.dart';
import 'package:geoguess_flags/l10n/app_localizations.dart';
import '../models/country.dart';
import '../models/game_config.dart';
import '../services/country_api.dart';
import 'game_page.dart';

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

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    
    if (_error != null) return _buildErrorState(l10n);
    if (_isLoading) return _buildLoadingState(l10n);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text(l10n.gameSetup),
        backgroundColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 10, 24, 100),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // 1. Game Mode
            _buildSectionHeader(l10n.gameMode),
            Row(
              children: [
                Expanded(
                  child: _buildSelectCard(
                    title: l10n.quizMode, 
                    icon: Icons.quiz, 
                    isSelected: _mode == GameMode.quiz,
                    onTap: () => setState(() => _mode = GameMode.quiz),
                    color: Colors.indigo,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: _buildSelectCard(
                    title: l10n.practiceMode, 
                    icon: Icons.school, 
                    isSelected: _mode == GameMode.practice,
                    onTap: () => setState(() => _mode = GameMode.practice),
                    color: Colors.green,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),

            // 2. Question Count
            _buildSectionHeader(l10n.questionsCount),
            _buildDropdown<int>(
              value: _questionCount,
              items: [5, 10, 20, 50, 100, 254],
              textBuilder: (val) => val == 254 ? l10n.all : "$val",
              onChanged: (val) => setState(() => _questionCount = val!),
            ),
            const SizedBox(height: 24),

            // 3. Timer
            _buildSectionHeader(l10n.timer),
            _buildDropdown<int?>(
              value: _timerSeconds,
              items: [null, 10, 15, 20, 30, 60],
              textBuilder: (val) => val == null ? l10n.off : "$val ${l10n.seconds}",
              onChanged: (val) => setState(() => _timerSeconds = val),
            ),
            const SizedBox(height: 32),

            // 4. Hints
            _buildSectionHeader(l10n.enableHints),
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
              ),
              child: Column(
                children: [
                  _buildSwitchTile(l10n.showContinentHint, Icons.public, _useRegionHint, (v) => setState(() => _useRegionHint = v)),
                  const Divider(height: 1),
                  _buildSwitchTile(l10n.showCapitalHint, Icons.location_city, _useCapitalHint, (v) => setState(() => _useCapitalHint = v)),
                ],
              ),
            ),
            
            // 5. Choices Count (Slider 0-15)
            if (_mode == GameMode.quiz) ...[
              const SizedBox(height: 32),
              // Header shows long text
              _buildSectionHeader("${l10n.choicesCount}: ${_choicesCount == 0 ? l10n.typeMode : _choicesCount}"),
              SliderTheme(
                data: SliderTheme.of(context).copyWith(
                  activeTrackColor: _choicesCount == 0 ? Colors.red : Colors.indigo,
                  thumbColor: _choicesCount == 0 ? Colors.red : Colors.indigo,
                  overlayColor: (_choicesCount == 0 ? Colors.red : Colors.indigo).withOpacity(0.2),
                  // FIX: Essential to prevent Assertion Failed error
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
                  // FIX: Keep label short ("Type") to avoid layout overflow
                  label: _choicesCount == 0 ? "Type" : _choicesCount.toString(),
                  onChanged: (val) => setState(() => _choicesCount = val.toInt()),
                ),
              ),
            ],
          ],
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: FloatingActionButton.extended(
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
                MaterialPageRoute(builder: (_) => GamePage(countries: _countries, config: config)),
              );
            },
            backgroundColor: Colors.indigo,
            label: Text(l10n.start, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
            icon: const Icon(Icons.play_circle_fill, color: Colors.white),
            elevation: 4,
          ),
        ),
      ),
    );
  }

  Widget _buildDropdown<T>({
    required T value,
    required List<T> items,
    required String Function(T) textBuilder,
    required ValueChanged<T?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          items: items.map((e) => DropdownMenuItem(value: e, child: Text(textBuilder(e)))).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87)),
    );
  }

  Widget _buildSelectCard({required String title, required IconData icon, required bool isSelected, required VoidCallback onTap, required Color color}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isSelected ? color.withOpacity(0.1) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: isSelected ? color : Colors.grey.shade300, width: 2),
        ),
        child: Column(
          children: [
            Icon(icon, size: 32, color: isSelected ? color : Colors.grey),
            const SizedBox(height: 8),
            Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: isSelected ? color : Colors.grey)),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchTile(String title, IconData icon, bool value, Function(bool) onChanged) {
    return SwitchListTile(
      value: value, onChanged: onChanged,
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
      secondary: Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: Colors.blue.shade50, borderRadius: BorderRadius.circular(8)), child: Icon(icon, color: Colors.blue.shade700, size: 20)),
      activeColor: Colors.indigo,
    );
  }

  Widget _buildLoadingState(AppLocalizations l10n) => Scaffold(appBar: AppBar(title: Text(l10n.gameSetup)), body: const Center(child: CircularProgressIndicator()));
  Widget _buildErrorState(AppLocalizations l10n) => Scaffold(appBar: AppBar(title: Text(l10n.gameSetup)), body: Center(child: Text(l10n.error)));
}