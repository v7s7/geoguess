import 'package:flutter/material.dart';

class Achievement {
  final String id;
  final String title;
  final String description;
  final IconData icon;
  final Color color;

  const Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
  });
}

class Achievements {
  static const all = [
    Achievement(
      id: 'first_game',
      title: 'First Steps',
      description: 'Complete your first quiz',
      icon: Icons.star_rounded,
      color: Color(0xFF4F46E5),
    ),
    Achievement(
      id: 'perfect_score',
      title: 'Perfect Score',
      description: 'Get 100% accuracy in a quiz',
      icon: Icons.workspace_premium,
      color: Color(0xFFF59E0B),
    ),
    Achievement(
      id: 'speed_demon',
      title: 'Speed Demon',
      description: 'Answer 30+ flags correctly in Speed Mode',
      icon: Icons.bolt,
      color: Color(0xFFEF4444),
    ),
    Achievement(
      id: 'streak_3',
      title: 'On a Roll',
      description: 'Maintain a 3-day play streak',
      icon: Icons.local_fire_department_rounded,
      color: Color(0xFFF97316),
    ),
    Achievement(
      id: 'streak_7',
      title: 'Streak Champion',
      description: 'Maintain a 7-day play streak',
      icon: Icons.whatshot_rounded,
      color: Color(0xFFDC2626),
    ),
    Achievement(
      id: 'africa_expert',
      title: 'Africa Expert',
      description: 'Earn 3 stars on the Africa Continent Battle',
      icon: Icons.public_rounded,
      color: Color(0xFF10B981),
    ),
    Achievement(
      id: 'europe_expert',
      title: 'Europe Expert',
      description: 'Earn 3 stars on the Europe Continent Battle',
      icon: Icons.euro_rounded,
      color: Color(0xFF3B82F6),
    ),
    Achievement(
      id: 'asia_expert',
      title: 'Asia Expert',
      description: 'Earn 3 stars on the Asia Continent Battle',
      icon: Icons.temple_buddhist_rounded,
      color: Color(0xFFEC4899),
    ),
    Achievement(
      id: 'world_master',
      title: 'World Master',
      description: 'Complete the ALL flags quiz (254 countries)',
      icon: Icons.language_rounded,
      color: Color(0xFF7C3AED),
    ),
    Achievement(
      id: 'multiplayer_win',
      title: 'Online Champion',
      description: 'Win an online multiplayer match',
      icon: Icons.emoji_events_rounded,
      color: Color(0xFFF59E0B),
    ),
    Achievement(
      id: 'quiz_master',
      title: 'Quiz Master',
      description: 'Play 50 quiz games',
      icon: Icons.military_tech_rounded,
      color: Color(0xFF0891B2),
    ),
    Achievement(
      id: 'review_cleared',
      title: 'No More Mistakes',
      description: 'Clear all mistakes in Review Mode',
      icon: Icons.check_circle_rounded,
      color: Color(0xFF10B981),
    ),
  ];

  static Achievement? findById(String id) {
    try {
      return all.firstWhere((a) => a.id == id);
    } catch (_) {
      return null;
    }
  }
}
