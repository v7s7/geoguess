import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../models/cosmetic_item.dart';
import '../models/user_profile.dart';
import '../services/auth_service.dart';
import '../services/user_service.dart';
import '../theme/app_theme.dart';

class ShopPage extends StatefulWidget {
  const ShopPage({super.key});

  @override
  State<ShopPage> createState() => _ShopPageState();
}

class _ShopPageState extends State<ShopPage> {
  UserProfile? _profile;
  bool _loading = true;
  StreamSubscription<UserProfile?>? _sub;

  @override
  void initState() {
    super.initState();
    _startListening();
  }

  void _startListening() {
    final uid = context.read<AuthService>().uid;
    if (uid == null) {
      setState(() => _loading = false);
      return;
    }
    _sub = UserService().watchProfile(uid).listen((p) {
      if (mounted) setState(() { _profile = p; _loading = false; });
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  Future<void> _handleBuy(CosmeticItem item) async {
    final uid = context.read<AuthService>().uid;
    if (uid == null) return;

    final coins = _profile?.geoCoins ?? 0;
    if (coins < item.price) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('Not enough coins! You need ${item.price} coins.'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.error,
      ));
      return;
    }

    final success = await UserService().purchaseCosmetic(uid, item.id, item.price);
    if (!mounted) return;
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('${item.name} purchased!'),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.success,
      ));
    }
  }

  Future<void> _handleEquip(CosmeticItem item) async {
    final uid = context.read<AuthService>().uid;
    if (uid == null) return;
    await UserService().equipCosmetic(uid, item.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text('${item.name} equipped!'),
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.primary,
    ));
  }

  @override
  Widget build(BuildContext context) {
    final coins = _profile?.geoCoins ?? 0;
    final owned = _profile?.ownedCosmetics ?? [];
    final active = _profile?.activeAvatarBorder;

    return Scaffold(
      body: Column(
        children: [
          // ── Header ─────────────────────────────────────────────
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [Color(0xFF5B21B6), Color(0xFF7C3AED)],
              ),
            ),
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(8, 4, 16, 20),
                child: Column(
                  children: [
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                        const Expanded(
                          child: Text(
                            '🛍️ Cosmetic Shop',
                            style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                        ),
                        // Coin balance
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              const Text('🪙', style: TextStyle(fontSize: 16)),
                              const SizedBox(width: 5),
                              Text(
                                '$coins',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Use GeoCoins to unlock avatar borders',
                      style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // ── Grid ───────────────────────────────────────────────
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : GridView.builder(
                    padding: const EdgeInsets.all(16),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      childAspectRatio: 0.82,
                      crossAxisSpacing: 14,
                      mainAxisSpacing: 14,
                    ),
                    itemCount: CosmeticItem.all.length,
                    itemBuilder: (context, i) {
                      final item = CosmeticItem.all[i];
                      final isOwned = owned.contains(item.id);
                      final isEquipped = active == item.id;
                      return _ShopCard(
                        item: item,
                        isOwned: isOwned,
                        isEquipped: isEquipped,
                        canAfford: coins >= item.price,
                        onBuy: () => _handleBuy(item),
                        onEquip: () => _handleEquip(item),
                        delay: i * 60,
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class _ShopCard extends StatelessWidget {
  final CosmeticItem item;
  final bool isOwned;
  final bool isEquipped;
  final bool canAfford;
  final VoidCallback onBuy;
  final VoidCallback onEquip;
  final int delay;

  const _ShopCard({
    required this.item,
    required this.isOwned,
    required this.isEquipped,
    required this.canAfford,
    required this.onBuy,
    required this.onEquip,
    required this.delay,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isEquipped
              ? item.borderColor
              : isOwned
                  ? item.borderColor.withOpacity(0.4)
                  : Colors.grey.shade200,
          width: isEquipped ? 2.5 : 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: (isEquipped ? item.borderColor : Colors.black).withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            // Border preview ring + emoji
            Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  width: 66,
                  height: 66,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: item.borderColor, width: 3),
                    color: item.borderColor.withOpacity(0.08),
                  ),
                ),
                Text(item.emoji, style: const TextStyle(fontSize: 28)),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              item.name,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            // Status chip
            if (isEquipped)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: item.borderColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: item.borderColor.withOpacity(0.4)),
                ),
                child: Text(
                  'Equipped',
                  style: TextStyle(
                    color: item.borderColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                  ),
                ),
              )
            else if (isOwned)
              SizedBox(
                width: double.infinity,
                height: 36,
                child: ElevatedButton(
                  onPressed: onEquip,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: item.borderColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                    padding: EdgeInsets.zero,
                  ),
                  child: const Text('Equip', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                ),
              )
            else
              SizedBox(
                width: double.infinity,
                height: 36,
                child: ElevatedButton.icon(
                  onPressed: canAfford ? onBuy : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: canAfford ? const Color(0xFF7C3AED) : Colors.grey.shade300,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                  ),
                  icon: const Text('🪙', style: TextStyle(fontSize: 12)),
                  label: Text(
                    '${item.price}',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ),
          ],
        ),
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: delay), duration: 350.ms).scale(
      begin: const Offset(0.9, 0.9),
      end: const Offset(1.0, 1.0),
      delay: Duration(milliseconds: delay),
    );
  }
}
