import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';

// ── Data Models ───────────────────────────────────────────────────────────────

class FriendRequest {
  final String id;
  final String fromUid;
  final String fromUsername;
  final String toUid;
  final String toUsername;
  final String status; // pending | accepted | declined

  const FriendRequest({
    required this.id,
    required this.fromUid,
    required this.fromUsername,
    required this.toUid,
    required this.toUsername,
    required this.status,
  });

  factory FriendRequest.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return FriendRequest(
      id: doc.id,
      fromUid: d['fromUid'] ?? '',
      fromUsername: d['fromUsername'] ?? '',
      toUid: d['toUid'] ?? '',
      toUsername: d['toUsername'] ?? '',
      status: d['status'] ?? 'pending',
    );
  }
}

class GameChallenge {
  final String id;
  final String fromUid;
  final String fromUsername;
  final String toUid;
  final String toUsername;
  final String status; // pending | accepted | declined
  final String? roomId;
  final List<String> flagCodes;

  const GameChallenge({
    required this.id,
    required this.fromUid,
    required this.fromUsername,
    required this.toUid,
    required this.toUsername,
    required this.status,
    this.roomId,
    required this.flagCodes,
  });

  factory GameChallenge.fromDoc(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return GameChallenge(
      id: doc.id,
      fromUid: d['fromUid'] ?? '',
      fromUsername: d['fromUsername'] ?? '',
      toUid: d['toUid'] ?? '',
      toUsername: d['toUsername'] ?? '',
      status: d['status'] ?? 'pending',
      roomId: d['roomId'] as String?,
      flagCodes: List<String>.from(d['flagCodes'] ?? []),
    );
  }
}

// ── Service ───────────────────────────────────────────────────────────────────

class FriendsService {
  final _db = FirebaseFirestore.instance;
  static const int _challengeFlags = 20;

  CollectionReference get _requests => _db.collection('friendRequests');
  CollectionReference get _challenges => _db.collection('challenges');
  CollectionReference get _users => _db.collection('users');
  CollectionReference get _rooms => _db.collection('rooms');

  // ── User search ───────────────────────────────────────────────────────────────

  /// Find a user by exact username (case-insensitive). Returns null if not found.
  Future<Map<String, dynamic>?> searchByUsername(String username) async {
    final lower = username.trim().toLowerCase();
    if (lower.isEmpty) return null;
    final snap = await _users
        .where('usernameLower', isEqualTo: lower)
        .limit(1)
        .get();
    if (snap.docs.isEmpty) return null;
    final doc = snap.docs.first;
    final data = doc.data() as Map<String, dynamic>;
    return {'uid': doc.id, ...data};
  }

  // ── Relationship checks ───────────────────────────────────────────────────────

  Future<bool> areFriends(String uid1, String uid2) async {
    final doc = await _users.doc(uid1).get();
    if (!doc.exists) return false;
    final data = doc.data() as Map<String, dynamic>;
    final friends = data['friends'] as List<dynamic>? ?? [];
    return friends.any((f) => (f as Map<String, dynamic>)['uid'] == uid2);
  }

  Future<bool> hasPendingRequestTo(String fromUid, String toUid) async {
    final snap = await _requests
        .where('fromUid', isEqualTo: fromUid)
        .where('toUid', isEqualTo: toUid)
        .where('status', isEqualTo: 'pending')
        .limit(1)
        .get();
    return snap.docs.isNotEmpty;
  }

  // ── Friend requests ───────────────────────────────────────────────────────────

  Future<void> sendFriendRequest({
    required String fromUid,
    required String fromUsername,
    required String toUid,
    required String toUsername,
  }) async {
    final already = await hasPendingRequestTo(fromUid, toUid);
    if (already) return;
    await _requests.add({
      'fromUid': fromUid,
      'fromUsername': fromUsername,
      'toUid': toUid,
      'toUsername': toUsername,
      'status': 'pending',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  /// Stream of incoming pending friend requests for [uid].
  Stream<List<FriendRequest>> watchIncomingRequests(String uid) {
    return _requests
        .where('toUid', isEqualTo: uid)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snap) => snap.docs.map(FriendRequest.fromDoc).toList());
  }

  Future<void> acceptFriendRequest({
    required String requestId,
    required String fromUid,
    required String fromUsername,
    required String toUid,
    required String toUsername,
  }) async {
    final batch = _db.batch();
    batch.update(_requests.doc(requestId), {'status': 'accepted'});
    // Add each user to the other's friends array
    batch.update(_users.doc(toUid), {
      'friends': FieldValue.arrayUnion([
        {'uid': fromUid, 'username': fromUsername}
      ]),
    });
    batch.update(_users.doc(fromUid), {
      'friends': FieldValue.arrayUnion([
        {'uid': toUid, 'username': toUsername}
      ]),
    });
    await batch.commit();
  }

  Future<void> declineFriendRequest(String requestId) async {
    await _requests.doc(requestId).update({'status': 'declined'});
  }

  // ── Friends list ──────────────────────────────────────────────────────────────

  /// Real-time stream of the current user's friends list.
  Stream<List<Map<String, String>>> watchFriends(String uid) {
    return _users.doc(uid).snapshots().map((doc) {
      if (!doc.exists) return <Map<String, String>>[];
      final data = doc.data() as Map<String, dynamic>;
      final friends = data['friends'] as List<dynamic>? ?? [];
      return friends.map((f) {
        final m = f as Map<String, dynamic>;
        return {'uid': m['uid'] as String, 'username': m['username'] as String};
      }).toList();
    });
  }

  Future<void> removeFriend({
    required String uid,
    required String myUsername,
    required String friendUid,
    required String friendUsername,
  }) async {
    final batch = _db.batch();
    batch.update(_users.doc(uid), {
      'friends': FieldValue.arrayRemove([
        {'uid': friendUid, 'username': friendUsername}
      ]),
    });
    batch.update(_users.doc(friendUid), {
      'friends': FieldValue.arrayRemove([
        {'uid': uid, 'username': myUsername}
      ]),
    });
    await batch.commit();
  }

  // ── Challenges ────────────────────────────────────────────────────────────────

  /// Send a challenge to [toUid]. Returns the new challenge document ID.
  Future<String> sendChallenge({
    required String fromUid,
    required String fromUsername,
    required String toUid,
    required String toUsername,
    required List<String> allCca2s,
  }) async {
    final shuffled = List<String>.from(allCca2s)..shuffle(Random());
    final flags = shuffled.take(_challengeFlags).toList();

    final doc = await _challenges.add({
      'fromUid': fromUid,
      'fromUsername': fromUsername,
      'toUid': toUid,
      'toUsername': toUsername,
      'status': 'pending',
      'roomId': null,
      'flagCodes': flags,
      'createdAt': FieldValue.serverTimestamp(),
    });
    return doc.id;
  }

  /// Stream of incoming pending challenges for [uid].
  Stream<List<GameChallenge>> watchIncomingChallenges(String uid) {
    return _challenges
        .where('toUid', isEqualTo: uid)
        .where('status', isEqualTo: 'pending')
        .snapshots()
        .map((snap) => snap.docs.map(GameChallenge.fromDoc).toList());
  }

  /// Watch a single challenge document (for the challenger to track acceptance).
  Stream<GameChallenge?> watchChallenge(String challengeId) {
    return _challenges.doc(challengeId).snapshots().map((doc) {
      if (!doc.exists) return null;
      return GameChallenge.fromDoc(doc);
    });
  }

  /// Accept a challenge: creates the game room and marks challenge as accepted.
  /// Returns the new room ID. The challenger is player1, acceptor is player2.
  Future<String> acceptChallenge({
    required String challengeId,
    required String challengerUid,
    required String challengerName,
    required String acceptorUid,
    required String acceptorName,
    required List<String> flagCodes,
  }) async {
    final roomDoc = await _rooms.add({
      'status': 'playing',
      'player1Uid': challengerUid,
      'player1Name': challengerName,
      'player1Score': 0,
      'player1Index': 0,
      'player1Finished': false,
      'player2Uid': acceptorUid,
      'player2Name': acceptorName,
      'player2Score': 0,
      'player2Index': 0,
      'player2Finished': false,
      'flagCodes': flagCodes,
      'createdAt': FieldValue.serverTimestamp(),
    });

    await _challenges.doc(challengeId).update({
      'status': 'accepted',
      'roomId': roomDoc.id,
    });

    return roomDoc.id;
  }

  Future<void> declineChallenge(String challengeId) async {
    await _challenges.doc(challengeId).update({'status': 'declined'});
  }

  Future<void> cancelChallenge(String challengeId) async {
    await _challenges.doc(challengeId).update({'status': 'declined'});
  }
}
