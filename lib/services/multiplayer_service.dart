import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';

class GameRoom {
  final String roomId;
  final String status; // waiting | playing | finished
  final String player1Uid;
  final String player1Name;
  int player1Score;
  int player1Index;
  bool player1Finished;
  final String? player2Uid;
  final String? player2Name;
  int player2Score;
  int player2Index;
  bool player2Finished;
  final List<String> flagCodes; // 20 cca2 codes

  GameRoom({
    required this.roomId,
    required this.status,
    required this.player1Uid,
    required this.player1Name,
    this.player1Score = 0,
    this.player1Index = 0,
    this.player1Finished = false,
    this.player2Uid,
    this.player2Name,
    this.player2Score = 0,
    this.player2Index = 0,
    this.player2Finished = false,
    required this.flagCodes,
  });

  factory GameRoom.fromDoc(String id, Map<String, dynamic> d) => GameRoom(
        roomId: id,
        status: d['status'] ?? 'waiting',
        player1Uid: d['player1Uid'] ?? '',
        player1Name: d['player1Name'] ?? 'Player 1',
        player1Score: (d['player1Score'] ?? 0) as int,
        player1Index: (d['player1Index'] ?? 0) as int,
        player1Finished: (d['player1Finished'] ?? false) as bool,
        player2Uid: d['player2Uid'] as String?,
        player2Name: d['player2Name'] as String?,
        player2Score: (d['player2Score'] ?? 0) as int,
        player2Index: (d['player2Index'] ?? 0) as int,
        player2Finished: (d['player2Finished'] ?? false) as bool,
        flagCodes: List<String>.from(d['flagCodes'] ?? []),
      );

  bool get bothFinished => player1Finished && player2Finished;
  bool get hasOpponent => player2Uid != null;
}

class MultiplayerService {
  final _db = FirebaseFirestore.instance;
  static const int questionCount = 20;

  CollectionReference get _rooms => _db.collection('rooms');

  // ── Create a new room ─────────────────────────────────────────────────────────

  Future<String> createRoom({
    required String uid,
    required String username,
    required List<String> allCca2s,
  }) async {
    // Pick 20 random flags
    final shuffled = List<String>.from(allCca2s)..shuffle(Random());
    final flags = shuffled.take(questionCount).toList();

    final doc = await _rooms.add({
      'status': 'waiting',
      'player1Uid': uid,
      'player1Name': username,
      'player1Score': 0,
      'player1Index': 0,
      'player1Finished': false,
      'player2Uid': null,
      'player2Name': null,
      'player2Score': 0,
      'player2Index': 0,
      'player2Finished': false,
      'flagCodes': flags,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return doc.id;
  }

  // ── Find and join an existing room ────────────────────────────────────────────

  /// Returns the room ID that was joined, or null if none available.
  Future<String?> findAndJoinRoom({
    required String uid,
    required String username,
  }) async {
    String? joinedRoomId;

    await _db.runTransaction((tx) async {
      final snap = await _rooms
          .where('status', isEqualTo: 'waiting')
          .where('player1Uid', isNotEqualTo: uid)
          .limit(1)
          .get();

      if (snap.docs.isEmpty) return;

      final doc = snap.docs.first;
      joinedRoomId = doc.id;

      tx.update(doc.reference, {
        'status': 'playing',
        'player2Uid': uid,
        'player2Name': username,
      });
    });

    return joinedRoomId;
  }

  // ── Listen to room ────────────────────────────────────────────────────────────

  Stream<GameRoom?> watchRoom(String roomId) {
    return _rooms.doc(roomId).snapshots().map((snap) {
      if (!snap.exists) return null;
      return GameRoom.fromDoc(snap.id, snap.data() as Map<String, dynamic>);
    });
  }

  // ── Submit answer ─────────────────────────────────────────────────────────────

  Future<void> submitAnswer({
    required String roomId,
    required bool isPlayer1,
    required int newScore,
    required int newIndex,
    required bool finished,
  }) async {
    final prefix = isPlayer1 ? 'player1' : 'player2';
    final updates = <String, dynamic>{
      '${prefix}Score': newScore,
      '${prefix}Index': newIndex,
      '${prefix}Finished': finished,
    };
    if (finished) {
      updates['updatedAt'] = FieldValue.serverTimestamp();
    }
    await _rooms.doc(roomId).update(updates);
  }

  // ── Cleanup stale waiting rooms ────────────────────────────────────────────────

  Future<void> deleteRoom(String roomId) async {
    await _rooms.doc(roomId).delete();
  }

  Future<void> cleanUpMyWaitingRoom(String uid) async {
    final snap = await _rooms
        .where('status', isEqualTo: 'waiting')
        .where('player1Uid', isEqualTo: uid)
        .get();
    for (final doc in snap.docs) {
      await doc.reference.delete();
    }
  }
}
