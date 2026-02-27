import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../services/auth_service.dart';
import '../services/leaderboard_service.dart';
import '../theme/app_theme.dart';

class LeaderboardPage extends StatefulWidget {
  const LeaderboardPage({super.key});

  @override
  State<LeaderboardPage> createState() => _LeaderboardPageState();
}

class _LeaderboardPageState extends State<LeaderboardPage> {
  final _service = LeaderboardService();
  List<LeaderboardEntry> _entries = [];
  int _myRank = 0;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final uid = context.read<AuthService>().uid;
      final entries = await _service.getTopPlayers();
      final rank = uid != null ? await _service.getMyRank(uid) : 0;
      if (mounted) setState(() { _entries = entries; _myRank = rank; _loading = false; });
    } catch (e) {
      if (mounted) setState(() { _error = e.toString(); _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    final myUid = context.read<AuthService>().uid;

    return Scaffold(
      body: Column(
        children: [
          // ── Header ─────────────────────────────────────────────
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(colors: [Color(0xFFD97706), Color(0xFFF59E0B)]),
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
                          child: Text('🏆 Leaderboard',
                              style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                        ),
                        if (_myRank > 0)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text('Your rank: #$_myRank',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13)),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Top 3 podium
          if (_entries.length >= 3 && !_loading)
            _buildPodium(),

          // Full list
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(child: Text('Failed to load: $_error'))
                    : _entries.isEmpty
                        ? const Center(child: Text('No players yet. Be the first!'))
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            itemCount: _entries.length,
                            itemBuilder: (context, i) {
                              final e = _entries[i];
                              final isMe = e.uid == myUid;
                              return _EntryTile(entry: e, isMe: isMe, delay: i * 30);
                            },
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildPodium() {
    final top3 = _entries.take(3).toList();
    return Container(
      color: AppColors.background,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 2nd
          _PodiumItem(entry: top3[1], rank: 2, height: 70),
          const SizedBox(width: 8),
          // 1st
          _PodiumItem(entry: top3[0], rank: 1, height: 100),
          const SizedBox(width: 8),
          // 3rd
          _PodiumItem(entry: top3[2], rank: 3, height: 55),
        ],
      ),
    ).animate().fadeIn(duration: 500.ms);
  }
}

class _PodiumItem extends StatelessWidget {
  final LeaderboardEntry entry;
  final int rank;
  final double height;
  const _PodiumItem({required this.entry, required this.rank, required this.height});

  Color get _color => rank == 1 ? Colors.amber : rank == 2 ? Colors.grey.shade400 : const Color(0xFFCD7F32);

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(rank == 1 ? '🥇' : rank == 2 ? '🥈' : '🥉', style: const TextStyle(fontSize: 24)),
          const SizedBox(height: 4),
          Text(entry.username, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12), maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 2),
          Text('${entry.totalScore}', style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
          const SizedBox(height: 6),
          Container(
            height: height,
            decoration: BoxDecoration(
              color: _color.withOpacity(0.15),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
              border: Border.all(color: _color.withOpacity(0.4)),
            ),
            child: Center(
              child: Text('#$rank', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: _color)),
            ),
          ),
        ],
      ),
    );
  }
}

class _EntryTile extends StatelessWidget {
  final LeaderboardEntry entry;
  final bool isMe;
  final int delay;
  const _EntryTile({required this.entry, required this.isMe, required this.delay});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isMe ? AppColors.primary.withOpacity(0.08) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isMe ? AppColors.primary.withOpacity(0.4) : Colors.grey.shade200,
          width: isMe ? 2 : 1,
        ),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6)],
      ),
      child: Row(
        children: [
          // Rank
          SizedBox(
            width: 32,
            child: Text(
              '#${entry.rank}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: entry.rank <= 3 ? Colors.amber.shade700 : Colors.grey,
              ),
            ),
          ),
          // Avatar
          CircleAvatar(
            radius: 18,
            backgroundColor: isMe ? AppColors.primary : Colors.grey.shade200,
            child: Text(
              entry.username.isNotEmpty ? entry.username[0].toUpperCase() : '?',
              style: TextStyle(fontWeight: FontWeight.bold, color: isMe ? Colors.white : Colors.black87),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(entry.username, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                    if (isMe) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(color: AppColors.primary, borderRadius: BorderRadius.circular(8)),
                        child: const Text('You', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                      ),
                    ],
                  ],
                ),
                Text('${entry.gamesPlayed} games · ${entry.gamesWon} wins',
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
              ],
            ),
          ),
          Text(
            '${entry.totalScore}',
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppColors.primary),
          ),
        ],
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: delay), duration: 300.ms).slideX(begin: 0.1, end: 0);
  }
}
