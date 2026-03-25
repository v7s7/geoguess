import 'dart:math';
import '../models/country.dart';
import '../models/game_config.dart';
import '../models/country_difficulty.dart';

class RoundData {
  final Country correctCountry;
  final List<Country> options; // Empty for practice mode or text mode

  RoundData({required this.correctCountry, required this.options});
}

class GameEngine {
  final List<Country> _allCountries;
  final GameConfig _config;
  final Random _rnd = Random();

  List<Country> _shuffledPool = [];
  int _currentIndex = 0;

  GameEngine(this._allCountries, this._config) {
    // Filter by difficulty before creating pool
    List<Country> filtered;
    switch (_config.difficulty) {
      case Difficulty.easy:
        filtered = _allCountries.where((c) => CountryDifficulty.isEasy(c.cca2)).toList();
        break;
      case Difficulty.medium:
        filtered = _allCountries.where((c) => CountryDifficulty.isMedium(c.cca2)).toList();
        break;
      case Difficulty.hard:
        filtered = _allCountries.where((c) => CountryDifficulty.isHard(c.cca2)).toList();
        break;
      case Difficulty.all:
        filtered = _allCountries;
        break;
    }
    // Fallback to all if filtered is empty
    if (filtered.isEmpty) filtered = _allCountries;
    _shuffledPool = List.from(filtered)..shuffle(_rnd);
    
    int limit = _config.questionCount;
    // Cap questions based on available pool
    if (limit > _shuffledPool.length) limit = _shuffledPool.length;
    _shuffledPool = _shuffledPool.take(limit).toList();
  }

  int get totalQuestions => _shuffledPool.length;

  RoundData? getNextRound() {
    if (_currentIndex >= _shuffledPool.length) return null;

    final correct = _shuffledPool[_currentIndex];
    List<Country> options = [];

    // Only generate options in Quiz Mode with at least 1 choice.
    // choices == 0 means Text Mode — skip this block, leaving options empty.
    if (_config.mode == GameMode.quiz && _config.choicesCount >= 1) {
      final distractors = List<Country>.from(_allCountries)
        ..removeWhere((c) => c.cca2 == correct.cca2)
        ..shuffle(_rnd);
      
      // Safety check: Ensure we don't ask for more distractors than exist
      int countToTake = _config.choicesCount - 1;
      if (countToTake > distractors.length) countToTake = distractors.length;
      
      options = distractors.take(countToTake).toList();
      options.add(correct);
      options.shuffle(_rnd);
    }

    _currentIndex++;
    return RoundData(correctCountry: correct, options: options);
  }
}