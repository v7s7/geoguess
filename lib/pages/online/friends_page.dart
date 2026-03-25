import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../models/country.dart';
import '../../services/auth_service.dart';
import '../../services/friends_service.dart';
import '../../theme/app_theme.dart';
import 'multiplayer_game_page.dart';

class FriendsPage extends StatefulWidget {
  final List<Country> countries;
  const FriendsPage({super.key, required this.countries});

  @override
  State<FriendsPage> createState() => _FriendsPageState();
}

class _FriendsPageState extends State<FriendsPage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthService>();
    final uid = auth.uid!;
    final service = FriendsService();

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF0F172A), Color(0xFF1E1B4B), Color(0xFF312E81)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white70),
                      onPressed: () => Navigator.pop(context),
                    ),
                    const Text(
                      'Friends',
                      style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800),
                    ),
                  ],
                ),
              ),

              // Tab bar
              StreamBuilder<List<FriendRequest>>(
                stream: service.watchIncomingRequests(uid),
                builder: (context, snap) {
                  final count = snap.data?.length ?? 0;
                  return TabBar(
                    controller: _tabs,
                    labelColor: Colors.white,
                    unselectedLabelColor: Colors.white38,
                    indicatorColor: AppColors.primary,
                    labelStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                    tabs: [
                      const Tab(text: 'Friends'),
                      const Tab(text: 'Find Players'),
                      Tab(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('Requests'),
                            if (count > 0) ...[
                              const SizedBox(width: 6),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.redAccent,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text('$count', style: const TextStyle(fontSize: 11, color: Colors.white, fontWeight: FontWeight.bold)),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ],
                  );
                },
              ),

              const Divider(color: Colors.white12, height: 1),

              Expanded(
                child: TabBarView(
                  controller: _tabs,
                  children: [
                    _FriendsTab(countries: widget.countries, uid: uid, service: service, auth: auth),
                    _SearchTab(countries: widget.countries, uid: uid, service: service, auth: auth),
                    _RequestsTab(uid: uid, service: service, auth: auth),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Friends Tab ───────────────────────────────────────────────────────────────

class _FriendsTab extends StatefulWidget {
  final List<Country> countries;
  final String uid;
  final FriendsService service;
  final AuthService auth;

  const _FriendsTab({
    required this.countries,
    required this.uid,
    required this.service,
    required this.auth,
  });

  @override
  State<_FriendsTab> createState() => _FriendsTabState();
}

class _FriendsTabState extends State<_FriendsTab> {
  String? _pendingChallengeId;
  StreamSubscription<GameChallenge?>? _challengeSub;

  @override
  void dispose() {
    _challengeSub?.cancel();
    super.dispose();
  }

  Future<void> _challenge(Map<String, String> friend) async {
    final cca2s = widget.countries.map((c) => c.cca2).toList();
    try {
      final challengeId = await widget.service.sendChallenge(
        fromUid: widget.uid,
        fromUsername: widget.auth.displayName ?? 'Player',
        toUid: friend['uid']!,
        toUsername: friend['username']!,
        allCca2s: cca2s,
      );
      setState(() => _pendingChallengeId = challengeId);
      _listenForChallengeResponse(challengeId, friend['username']!);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to send challenge: $e'), behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  void _listenForChallengeResponse(String challengeId, String opponentName) {
    _challengeSub?.cancel();
    _challengeSub = widget.service.watchChallenge(challengeId).listen((challenge) {
      if (challenge == null || !mounted) return;
      if (challenge.status == 'accepted' && challenge.roomId != null) {
        _challengeSub?.cancel();
        setState(() => _pendingChallengeId = null);
        // Navigate to game as player1 (challenger)
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => MultiplayerGamePage(
              countries: widget.countries,
              roomId: challenge.roomId!,
              isPlayer1: true,
            ),
          ),
        );
      } else if (challenge.status == 'declined') {
        _challengeSub?.cancel();
        setState(() => _pendingChallengeId = null);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('$opponentName declined your challenge.'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    });
  }

  void _cancelChallenge() {
    if (_pendingChallengeId != null) {
      widget.service.cancelChallenge(_pendingChallengeId!);
      _challengeSub?.cancel();
      setState(() => _pendingChallengeId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_pendingChallengeId != null) {
      return _buildWaitingForResponse();
    }

    return StreamBuilder<List<Map<String, String>>>(
      stream: widget.service.watchFriends(widget.uid),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Colors.white));
        }
        final friends = snap.data ?? [];
        if (friends.isEmpty) {
          return _buildEmpty(
            icon: Icons.people_outline_rounded,
            message: 'No friends yet',
            sub: 'Go to "Find Players" to add friends',
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: friends.length,
          itemBuilder: (_, i) {
            final f = friends[i];
            return _FriendTile(
              username: f['username']!,
              onChallenge: () => _challenge(f),
              onRemove: () async {
                await widget.service.removeFriend(
                  uid: widget.uid,
                  myUsername: widget.auth.displayName ?? 'Player',
                  friendUid: f['uid']!,
                  friendUsername: f['username']!,
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildWaitingForResponse() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(
            width: 60, height: 60,
            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
          ),
          const SizedBox(height: 24),
          const Text(
            'Waiting for response...',
            style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Your challenge has been sent',
            style: TextStyle(color: Colors.white.withOpacity(0.6), fontSize: 14),
          ),
          const SizedBox(height: 40),
          TextButton.icon(
            onPressed: _cancelChallenge,
            icon: const Icon(Icons.close, color: Colors.white60),
            label: const Text('Cancel', style: TextStyle(color: Colors.white60)),
          ),
        ],
      ).animate().fadeIn(),
    );
  }
}

class _FriendTile extends StatelessWidget {
  final String username;
  final VoidCallback onChallenge;
  final VoidCallback onRemove;

  const _FriendTile({
    required this.username,
    required this.onChallenge,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.primary.withOpacity(0.3),
            child: Text(
              username[0].toUpperCase(),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              username,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15),
            ),
          ),
          // Challenge button
          GestureDetector(
            onTap: onChallenge,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)]),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.sports_esports_rounded, color: Colors.white, size: 16),
                  SizedBox(width: 6),
                  Text('Challenge', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          // Remove button
          IconButton(
            icon: const Icon(Icons.person_remove_rounded, color: Colors.white38, size: 20),
            onPressed: onRemove,
            tooltip: 'Remove friend',
          ),
        ],
      ),
    ).animate().fadeIn().slideX(begin: 0.05, end: 0);
  }
}

// ── Search Tab ────────────────────────────────────────────────────────────────

class _SearchTab extends StatefulWidget {
  final List<Country> countries;
  final String uid;
  final FriendsService service;
  final AuthService auth;

  const _SearchTab({
    required this.countries,
    required this.uid,
    required this.service,
    required this.auth,
  });

  @override
  State<_SearchTab> createState() => _SearchTabState();
}

class _SearchTabState extends State<_SearchTab> {
  final _searchCtrl = TextEditingController();
  bool _searching = false;
  Map<String, dynamic>? _result;
  String? _resultStatus; // null | 'self' | 'friend' | 'pending' | 'stranger'
  bool _actionLoading = false;
  String? _searchError;

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _search() async {
    final q = _searchCtrl.text.trim();
    if (q.isEmpty) return;
    setState(() { _searching = true; _result = null; _resultStatus = null; _searchError = null; });

    final found = await widget.service.searchByUsername(q);
    if (!mounted) return;

    if (found == null) {
      setState(() { _searching = false; _searchError = 'No user found with that username.'; });
      return;
    }

    if (found['uid'] == widget.uid) {
      setState(() { _searching = false; _result = found; _resultStatus = 'self'; });
      return;
    }

    final isFriend = await widget.service.areFriends(widget.uid, found['uid'] as String);
    if (isFriend) {
      setState(() { _searching = false; _result = found; _resultStatus = 'friend'; });
      return;
    }

    final hasPending = await widget.service.hasPendingRequestTo(widget.uid, found['uid'] as String);
    if (hasPending) {
      setState(() { _searching = false; _result = found; _resultStatus = 'pending'; });
      return;
    }

    setState(() { _searching = false; _result = found; _resultStatus = 'stranger'; });
  }

  Future<void> _sendRequest() async {
    if (_result == null) return;
    setState(() => _actionLoading = true);
    await widget.service.sendFriendRequest(
      fromUid: widget.uid,
      fromUsername: widget.auth.displayName ?? 'Player',
      toUid: _result!['uid'] as String,
      toUsername: _result!['username'] as String,
    );
    if (mounted) setState(() { _actionLoading = false; _resultStatus = 'pending'; });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _searchCtrl,
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    hintText: 'Enter exact username...',
                    hintStyle: TextStyle(color: Colors.white.withOpacity(0.4)),
                    prefixIcon: const Icon(Icons.search_rounded, color: Colors.white54),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.1),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide(color: Colors.white.withOpacity(0.2)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: Colors.white, width: 1.5),
                    ),
                  ),
                  onSubmitted: (_) => _search(),
                ),
              ),
              const SizedBox(width: 10),
              GestureDetector(
                onTap: _searching ? null : _search,
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)]),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: _searching
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.search_rounded, color: Colors.white, size: 20),
                ),
              ),
            ],
          ),
        ),

        if (_searchError != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white.withOpacity(0.1)),
              ),
              child: Text(_searchError!, style: TextStyle(color: Colors.white.withOpacity(0.6)), textAlign: TextAlign.center),
            ),
          ),

        if (_result != null) _buildResultCard(),
      ],
    );
  }

  Widget _buildResultCard() {
    final username = _result!['username'] as String;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white.withOpacity(0.15)),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 24,
              backgroundColor: AppColors.primary.withOpacity(0.3),
              child: Text(username[0].toUpperCase(),
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18)),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(username,
                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16)),
                  const SizedBox(height: 2),
                  Text(_statusLabel(),
                      style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
                ],
              ),
            ),
            _buildActionButton(),
          ],
        ),
      ).animate().fadeIn().scale(begin: const Offset(0.95, 0.95)),
    );
  }

  String _statusLabel() {
    switch (_resultStatus) {
      case 'self': return 'That\'s you!';
      case 'friend': return 'Already friends';
      case 'pending': return 'Request sent';
      default: return 'GeoGuess player';
    }
  }

  Widget _buildActionButton() {
    if (_resultStatus == 'self' || _resultStatus == 'friend') return const SizedBox.shrink();

    if (_resultStatus == 'pending') {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.1),
          borderRadius: BorderRadius.circular(10),
        ),
        child: const Text('Pending', style: TextStyle(color: Colors.white60, fontSize: 13)),
      );
    }

    // stranger
    return GestureDetector(
      onTap: _actionLoading ? null : _sendRequest,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          gradient: const LinearGradient(colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)]),
          borderRadius: BorderRadius.circular(10),
        ),
        child: _actionLoading
            ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
            : const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.person_add_rounded, color: Colors.white, size: 16),
                  SizedBox(width: 6),
                  Text('Add Friend', style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                ],
              ),
      ),
    );
  }
}

// ── Requests Tab ──────────────────────────────────────────────────────────────

class _RequestsTab extends StatelessWidget {
  final String uid;
  final FriendsService service;
  final AuthService auth;

  const _RequestsTab({required this.uid, required this.service, required this.auth});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<FriendRequest>>(
      stream: service.watchIncomingRequests(uid),
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator(color: Colors.white));
        }
        final requests = snap.data ?? [];
        if (requests.isEmpty) {
          return _buildEmpty(
            icon: Icons.mark_email_unread_rounded,
            message: 'No pending requests',
            sub: 'Friend requests will appear here',
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: requests.length,
          itemBuilder: (_, i) {
            final req = requests[i];
            return _RequestTile(
              request: req,
              onAccept: () => service.acceptFriendRequest(
                requestId: req.id,
                fromUid: req.fromUid,
                fromUsername: req.fromUsername,
                toUid: req.toUid,
                toUsername: req.toUsername,
              ),
              onDecline: () => service.declineFriendRequest(req.id),
            );
          },
        );
      },
    );
  }
}

class _RequestTile extends StatefulWidget {
  final FriendRequest request;
  final Future<void> Function() onAccept;
  final Future<void> Function() onDecline;

  const _RequestTile({required this.request, required this.onAccept, required this.onDecline});

  @override
  State<_RequestTile> createState() => _RequestTileState();
}

class _RequestTileState extends State<_RequestTile> {
  bool _loading = false;

  Future<void> _act(Future<void> Function() fn) async {
    setState(() => _loading = true);
    await fn();
    // Stream will update automatically
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withOpacity(0.12)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.accent.withOpacity(0.3),
            child: Text(
              widget.request.fromUsername[0].toUpperCase(),
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(widget.request.fromUsername,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 15)),
                Text('wants to be friends', style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12)),
              ],
            ),
          ),
          if (_loading)
            const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
          else ...[
            // Accept
            GestureDetector(
              onTap: () => _act(widget.onAccept),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF10B981).withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFF10B981).withOpacity(0.5)),
                ),
                child: const Text('Accept', style: TextStyle(color: Color(0xFF10B981), fontSize: 13, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(width: 8),
            // Decline
            GestureDetector(
              onTap: () => _act(widget.onDecline),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.06),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white.withOpacity(0.2)),
                ),
                child: const Text('Decline', style: TextStyle(color: Colors.white60, fontSize: 13)),
              ),
            ),
          ],
        ],
      ),
    ).animate().fadeIn().slideX(begin: 0.05, end: 0);
  }
}

// ── Empty state helper ────────────────────────────────────────────────────────

Widget _buildEmpty({required IconData icon, required String message, required String sub}) {
  return Center(
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 64, color: Colors.white24),
        const SizedBox(height: 16),
        Text(message, style: const TextStyle(color: Colors.white60, fontSize: 18, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Text(sub, style: TextStyle(color: Colors.white.withOpacity(0.35), fontSize: 13), textAlign: TextAlign.center),
      ],
    ).animate().fadeIn(),
  );
}
