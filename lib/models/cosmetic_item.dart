import 'package:flutter/material.dart';

enum CosmeticType { avatarBorder }

class CosmeticItem {
  final String id;
  final CosmeticType type;
  final String name;
  final String emoji;
  final Color borderColor;
  final int price;

  const CosmeticItem({
    required this.id,
    required this.type,
    required this.name,
    required this.emoji,
    required this.borderColor,
    required this.price,
  });

  static const all = [
    CosmeticItem(
      id: 'border_gold',
      type: CosmeticType.avatarBorder,
      name: 'Gold Champion',
      emoji: '🏆',
      borderColor: Color(0xFFF59E0B),
      price: 200,
    ),
    CosmeticItem(
      id: 'border_fire',
      type: CosmeticType.avatarBorder,
      name: 'Fire Legend',
      emoji: '🔥',
      borderColor: Color(0xFFEF4444),
      price: 150,
    ),
    CosmeticItem(
      id: 'border_galaxy',
      type: CosmeticType.avatarBorder,
      name: 'Galaxy',
      emoji: '🌌',
      borderColor: Color(0xFF7C3AED),
      price: 250,
    ),
    CosmeticItem(
      id: 'border_ocean',
      type: CosmeticType.avatarBorder,
      name: 'Ocean',
      emoji: '🌊',
      borderColor: Color(0xFF06B6D4),
      price: 120,
    ),
    CosmeticItem(
      id: 'border_emerald',
      type: CosmeticType.avatarBorder,
      name: 'Emerald',
      emoji: '💎',
      borderColor: Color(0xFF10B981),
      price: 180,
    ),
  ];
}
