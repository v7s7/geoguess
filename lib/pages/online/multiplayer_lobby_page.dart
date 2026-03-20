import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:provider/provider.dart';
import '../../l10n/app_localizations.dart';
import '../../models/country.dart';
import '../../services/auth_service.dart';
import '../../services/multiplayer_service.dart';
import '../../theme/app_theme.dart';
import 'multiplayer_game_page.dart';

class MultiplayerLobbyPage extends StatefulWidget {
  final List<Country> countries;
  const MultiplayerLobbyPage({super.key, required this.countries});

  @override
  State<MultiplayerLobbyPage> createState() => _MultiplayerLobbyPageState();
}

class _MultiplayerLobbyPageState extends State<MultiplayerLobbyPage>
    with TickerProviderStateMixin {
  final _service = MultiplayerService();

  _LobbyState _state = _LobbyState.idle;
  String? _roomId;
  bool _isPlayer1 = false;
  StreamSubscription? _roomSub;
  String? _error;

  late final AnimationController _pulseCtrl;

  @override
  void initState() {
    super.initState();
    _pulseCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 1))
      ..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseCtrl.dispose();
    _roomSub?.cancel();
    if (_state == _LobbyState.waiting && _roomId != null && _isPlayer1) {
      _service.deleteRoom(_roomId!);
    }
    super.dispose();
  }

  Future<void> _findMatch() async {
    final auth = context.read<AuthService>();
    final l10n = AppLocalizations.of(context)!;
    final uid = auth.uid!;
    final username = auth.displayName ?? 'Player';
    final cca2s = widget.countries.map((c) => c.cca2).toList();

    setState(() { _state = _LobbyState.searching; _error = null; });

    try {
      final joined = await _service.findAndJoinRoom(uid: uid, username: username);

      if (joined != null) {
        _roomId = joined;
        _isPlayer1 = false;
        _listenToRoom(joined);
      } else {
        final created = await _service.createRoom(uid: uid, username: username, allCca2s: cca2s);
        _roomId = created;
        _isPlayer1 = true;
        setState(() => _state = _LobbyState.waiting);
        _listenToRoom(created);
      }
    } catch (e) {
      if (mounted) setState(() { _state = _LobbyState.idle; _error = l10n.connectionError; });
    }
  }

  void _listenToRoom(String roomId) {
    _roomSub?.cancel();
    _roomSub = _service.watchRoom(roomId).listen((room) {
      if (room == null || !mounted) return;
      if (room.status == 'playing' && room.hasOpponent) {
        _roomSub?.cancel();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => MultiplayerGamePage(
              countries: widget.countries,
              roomId: roomId,
              isPlayer1: _isPlayer1,
            ),
          ),
        );
      }
    });
  }

  Future<void> _cancel() async {
    _roomSub?.cancel();
    if (_roomId != null && _isPlayer1) {
      await _service.deleteRoom(_roomId!);
    }
    if (mounted) setState(() { _state = _LobbyState.idle; _roomId = null; });
  }

  @override
  Widget build(BuildContext context) {
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
              Align(
                alignment: Alignment.topLeft,
                child: IconButton(
                  icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white70),
                  onPressed: _state == _LobbyState.waiting ? _cancel : () => Navigator.pop(context),
                ),
              ),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [_buildContent()],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    return switch (_state) {
      _LobbyState.idle => _buildIdle(),
      _LobbyState.searching => _buildSearching(),
      _LobbyState.waiting => _buildWaiting(),
    };
  }

  Widget _buildIdle() {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      children: [
        const Icon(Icons.people_rounded, size: 80, color: Colors.white)
            .animate().scale(duration: 600.ms, curve: Curves.elasticOut),
        const SizedBox(height: 20),
        Text(l10n.onlineMatch, style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.white)),
        const SizedBox(height: 8),
        Text(l10n.onlineMatchDesc,
            style: TextStyle(color: Colors.white.withOpacity(0.65), fontSize: 15), textAlign: TextAlign.center),
        const SizedBox(height: 10),
        _RuleChip('🏳 20 ${l10n.question}s'),
        const SizedBox(height: 6),
        _RuleChip('🔟 10 ${l10n.choicesCount.split(' ').last}'),
        const SizedBox(height: 6),
        _RuleChip('⏱ ${l10n.off} ${l10n.timer}'),
        const SizedBox(height: 48),
        if (_error != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: AppColors.error.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
              child: Text(_error!, style: const TextStyle(color: AppColors.error)),
            ),
          ),
        GestureDetector(
          onTap: _findMatch,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 20),
            decoration: BoxDecoration(
              gradient: const LinearGradient(colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)]),
              borderRadius: BorderRadius.circular(20),
              boxShadow: [BoxShadow(color: AppColors.primary.withOpacity(0.5), blurRadius: 20, offset: const Offset(0, 8))],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.search_rounded, color: Colors.white, size: 24),
                const SizedBox(width: 10),
                Text(l10n.findMatch, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.2, end: 0),
      ],
    );
  }

  Widget _buildSearching() {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      children: [
        const SizedBox(
          width: 60, height: 60,
          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 3),
        ),
        const SizedBox(height: 20),
        Text(l10n.searchingOpponent, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text(l10n.findingBestMatch, style: TextStyle(color: Colors.white.withOpacity(0.6))),
      ],
    );
  }

  Widget _buildWaiting() {
    final l10n = AppLocalizations.of(context)!;
    return Column(
      children: [
        AnimatedBuilder(
          animation: _pulseCtrl,
          builder: (_, __) => Container(
            width: 100, height: 100,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withOpacity(0.2 + _pulseCtrl.value * 0.15),
              border: Border.all(color: Colors.white.withOpacity(0.3 + _pulseCtrl.value * 0.3), width: 2),
            ),
            child: const Icon(Icons.wifi_tethering_rounded, size: 50, color: Colors.white),
          ),
        ),
        const SizedBox(height: 24),
        Text(l10n.waitingForPlayer, style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        Text(l10n.roomCreated, style: TextStyle(color: Colors.white.withOpacity(0.6))),
        const SizedBox(height: 40),
        TextButton.icon(
          onPressed: _cancel,
          icon: const Icon(Icons.close, color: Colors.white60),
          label: Text(l10n.cancel, style: const TextStyle(color: Colors.white60)),
        ),
      ],
    );
  }
}

enum _LobbyState { idle, searching, waiting }

class _RuleChip extends StatelessWidget {
  final String label;
  const _RuleChip(this.label);
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withOpacity(0.15)),
      ),
      child: Text(label, style: TextStyle(color: Colors.white.withOpacity(0.8), fontSize: 14)),
    );
  }
}
