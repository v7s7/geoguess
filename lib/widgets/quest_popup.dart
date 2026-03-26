import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../models/daily_quest.dart';
import '../theme/app_theme.dart';

/// Shows a floating quest-completion toast in the current Overlay.
/// Automatically dismisses after [duration].
class QuestPopup {
  static void show(
    BuildContext context,
    DailyQuest quest, {
    Duration duration = const Duration(seconds: 3),
  }) {
    final overlay = Overlay.of(context);
    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _QuestToast(
        quest: quest,
        onDone: () => entry.remove(),
        duration: duration,
      ),
    );
    overlay.insert(entry);
  }

  /// Convenience: show one popup per completed quest, staggered 800ms apart.
  static void showAll(BuildContext context, List<DailyQuest> quests) {
    for (int i = 0; i < quests.length; i++) {
      Future.delayed(Duration(milliseconds: i * 900), () {
        if (context.mounted) show(context, quests[i]);
      });
    }
  }
}

class _QuestToast extends StatefulWidget {
  final DailyQuest quest;
  final VoidCallback onDone;
  final Duration duration;

  const _QuestToast({
    required this.quest,
    required this.onDone,
    required this.duration,
  });

  @override
  State<_QuestToast> createState() => _QuestToastState();
}

class _QuestToastState extends State<_QuestToast>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _slide;
  late final Animation<double> _fade;
  Timer? _timer;
  bool _dismissing = false;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _slide = CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack);
    _fade  = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _ctrl.forward();
    _timer = Timer(widget.duration, _dismiss);
  }

  Future<void> _dismiss() async {
    if (_dismissing) return;
    _dismissing = true;
    _timer?.cancel();
    await _ctrl.reverse();
    widget.onDone();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: MediaQuery.of(context).padding.top + 60,
      left: 20,
      right: 20,
      child: GestureDetector(
        onTap: _dismiss,
        child: AnimatedBuilder(
          animation: _ctrl,
          builder: (_, child) => FadeTransition(
            opacity: _fade,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, -0.6),
                end: Offset.zero,
              ).animate(_slide),
              child: child,
            ),
          ),
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFF1E1B4B),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withOpacity(0.35),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
                border: Border.all(
                  color: AppColors.primary.withOpacity(0.5),
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  // Coin icon with glow
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFF59E0B).withOpacity(0.15),
                      border: Border.all(
                        color: const Color(0xFFF59E0B).withOpacity(0.5),
                        width: 1.5,
                      ),
                    ),
                    child: const Center(
                      child: Text('🪙', style: TextStyle(fontSize: 22)),
                    ),
                  ).animate(onPlay: (c) => c.repeat(reverse: true))
                   .scaleXY(begin: 1.0, end: 1.12, duration: 700.ms, curve: Curves.easeInOut),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            const Text(
                              '🎯 Quest Complete!',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w900,
                                fontSize: 13,
                                letterSpacing: 0.2,
                              ),
                            ),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF59E0B).withOpacity(0.2),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '+${widget.quest.rewardCoins} 🪙',
                                style: const TextStyle(
                                  color: Color(0xFFF59E0B),
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          widget.quest.title,
                          style: const TextStyle(
                            color: Color(0xFFBFD9FF),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Text(
                          widget.quest.description,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
