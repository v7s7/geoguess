import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../models/elo_tier.dart';
import '../services/auth_service.dart';
import '../services/leaderboard_service.dart';
import '../services/user_service.dart';
import '../theme/app_theme.dart';

class LeaderboardPage extends StatefulWidget {
  const LeaderboardPage({super.key});

  @override
  State<LeaderboardPage> createState() => _LeaderboardPageState();
}

class _LeaderboardPageState extends State<LeaderboardPage>
    with SingleTickerProviderStateMixin {
  final _service = LeaderboardService();
  late TabController _tabController;

  List<LeaderboardEntry> _scoreEntries = [];
  List<LeaderboardEntry> _eloEntries = [];
  int _myRank = 0;
  int _myEloRank = 0;
  int _myElo = 1000;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final uid = context.read<AuthService>().uid;
      final scoreEntries = await _service.getTopPlayers();
      final eloEntries = await _service.getTopPlayersByElo();
      final rank = uid != null ? await _service.getMyRank(uid) : 0;
      final eloRank = uid != null ? await _service.getMyEloRank(uid) : 0;
      // Get my ELO from profile
      int myElo = 1000;
      if (uid != null) {
        final profile = await UserService().getProfile(uid);
        myElo = profile?.eloRating ?? 1000;
      }
      if (mounted) {
        setState(() {
          _scoreEntries = scoreEntries;
          _eloEntries = eloEntries;
          _myRank = rank;
          _myEloRank = eloRank;
          _myElo = myElo;
          _loading = false;
        });
      }
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
                padding: const EdgeInsets.fromLTRB(8, 4, 16, 0),
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
                        // My rank badge
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            if (_myRank > 0)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text('Rank #$_myRank',
                                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                              ),
                            const SizedBox(height: 2),
                            // ELO tier badge
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: Colors.white.withOpacity(0.15),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                '${EloTier.getLabel(_myElo)} · $_myElo ELO',
                                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 11),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Tab bar
                    TabBar(
                      controller: _tabController,
                      indicator: BoxDecoration(
                        color: Colors.white.withOpacity(0.25),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      labelColor: Colors.white,
                      unselectedLabelColor: Colors.white60,
                      labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      tabs: const [
                        Tab(text: 'Global Score'),
                        Tab(text: 'ELO Rank'),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Content
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator())
                : _error != null
                    ? Center(child: Text('Failed to load: $_error'))
                    : TabBarView(
                        controller: _tabController,
                        children: [
                          _buildScoreTab(myUid),
                          _buildEloTab(myUid),
                        ],
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildScoreTab(String? myUid) {
    if (_scoreEntries.isEmpty) {
      return const Center(child: Text('No players yet. Be the first!'));
    }
    return Column(
      children: [
        if (_scoreEntries.length >= 3)
          _buildPodium(_scoreEntries),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: _scoreEntries.length,
            itemBuilder: (context, i) {
              final e = _scoreEntries[i];
              final isMe = e.uid == myUid;
              return _EntryTile(entry: e, isMe: isMe, delay: i * 30, showElo: false);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildEloTab(String? myUid) {
    if (_eloEntries.isEmpty) {
      return const Center(child: Text('No ELO data yet.'));
    }
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      itemCount: _eloEntries.length,
      itemBuilder: (context, i) {
        final e = _eloEntries[i];
        final isMe = e.uid == myUid;
        return _EloEntryTile(entry: e, isMe: isMe, delay: i * 30);
      },
    );
  }

  Widget _buildPodium(List<LeaderboardEntry> entries) {
    final top3 = entries.take(3).toList();
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          _PodiumItem(entry: top3[1], rank: 2, height: 70),
          const SizedBox(width: 8),
          _PodiumItem(entry: top3[0], rank: 1, height: 100),
          const SizedBox(width: 8),
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
          Text('${entry.totalScore}', style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6))),
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
  final bool showElo;
  const _EntryTile({required this.entry, required this.isMe, required this.delay, this.showElo = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isMe ? AppColors.primary.withOpacity(0.08) : Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isMe ? AppColors.primary.withOpacity(0.4) : Theme.of(context).colorScheme.outlineVariant,
          width: isMe ? 2 : 1,
        ),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6)],
      ),
      child: Row(
        children: [
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
          CircleAvatar(
            radius: 18,
            backgroundColor: isMe ? AppColors.primary : Theme.of(context).colorScheme.outlineVariant,
            child: Text(
              entry.username.isNotEmpty ? entry.username[0].toUpperCase() : '?',
              style: TextStyle(fontWeight: FontWeight.bold, color: isMe ? Colors.white : Theme.of(context).colorScheme.onSurface),
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
                    style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurface.withOpacity(0.55))),
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

class _EloEntryTile extends StatelessWidget {
  final LeaderboardEntry entry;
  final bool isMe;
  final int delay;
  const _EloEntryTile({required this.entry, required this.isMe, required this.delay});

  @override
  Widget build(BuildContext context) {
    final tierLabel = EloTier.getLabel(entry.eloRating);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isMe ? AppColors.primary.withOpacity(0.08) : Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isMe ? AppColors.primary.withOpacity(0.4) : Theme.of(context).colorScheme.outlineVariant,
          width: isMe ? 2 : 1,
        ),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 6)],
      ),
      child: Row(
        children: [
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
          CircleAvatar(
            radius: 18,
            backgroundColor: isMe ? AppColors.primary : Theme.of(context).colorScheme.outlineVariant,
            child: Text(
              entry.username.isNotEmpty ? entry.username[0].toUpperCase() : '?',
              style: TextStyle(fontWeight: FontWeight.bold, color: isMe ? Colors.white : Theme.of(context).colorScheme.onSurface),
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
                // Tier badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    tierLabel,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Colors.amber),
                  ),
                ),
              ],
            ),
          ),
          Text(
            '${entry.eloRating}',
            style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 16, color: AppColors.secondary),
          ),
        ],
      ),
    ).animate().fadeIn(delay: Duration(milliseconds: delay), duration: 300.ms).slideX(begin: 0.1, end: 0);
  }
}
