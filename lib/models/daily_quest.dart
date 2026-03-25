import 'dart:math';

enum QuestType { playGames, correctAnswers, winMultiplayer, speedMode, continentBattle }

class DailyQuest {
  final String id;
  final QuestType type;
  final String title;
  final String description;
  final int target;
  final int rewardCoins;

  const DailyQuest({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.target,
    required this.rewardCoins,
  });
}

class QuestDefinitions {
  static const all = [
    DailyQuest(
      id: 'play5',
      type: QuestType.playGames,
      title: 'Flag Explorer',
      description: 'Play 5 games',
      target: 5,
      rewardCoins: 50,
    ),
    DailyQuest(
      id: 'correct50',
      type: QuestType.correctAnswers,
      title: 'Sharp Eye',
      description: 'Get 50 correct answers',
      target: 50,
      rewardCoins: 75,
    ),
    DailyQuest(
      id: 'win_mp',
      type: QuestType.winMultiplayer,
      title: 'Online Warrior',
      description: 'Win 1 multiplayer match',
      target: 1,
      rewardCoins: 100,
    ),
    DailyQuest(
      id: 'speed1',
      type: QuestType.speedMode,
      title: 'Speed Runner',
      description: 'Complete Speed Mode once',
      target: 1,
      rewardCoins: 60,
    ),
    DailyQuest(
      id: 'correct100',
      type: QuestType.correctAnswers,
      title: 'Flag Master',
      description: 'Get 100 correct answers',
      target: 100,
      rewardCoins: 120,
    ),
    DailyQuest(
      id: 'play10',
      type: QuestType.playGames,
      title: 'Dedicated Player',
      description: 'Play 10 games',
      target: 10,
      rewardCoins: 80,
    ),
    DailyQuest(
      id: 'battle1',
      type: QuestType.continentBattle,
      title: 'Continent Conqueror',
      description: 'Complete a Continent Battle',
      target: 1,
      rewardCoins: 90,
    ),
  ];

  /// Returns 3 deterministic quests for today based on date seed
  static List<DailyQuest> getForToday() {
    final now = DateTime.now();
    final seed = now.year * 10000 + now.month * 100 + now.day;
    final rnd = Random(seed);
    final shuffled = List<DailyQuest>.from(all)..shuffle(rnd);
    return shuffled.take(3).toList();
  }
}
