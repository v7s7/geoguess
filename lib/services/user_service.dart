import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_profile.dart';

class UserService {
  final _db = FirebaseFirestore.instance;

  CollectionReference get _users => _db.collection('users');
  CollectionReference get _leaderboard => _db.collection('leaderboard');

  // ── Create ──────────────────────────────────────────────────────────────────

  Future<void> createProfile({
    required String uid,
    required String username,
    required String email,
  }) async {
    final data = UserProfile(uid: uid, username: username, email: email).toMap();
    await _users.doc(uid).set(data);
    // Also create leaderboard entry
    await _leaderboard.doc(uid).set({
      'username': username,
      'totalScore': 0,
      'gamesPlayed': 0,
      'gamesWon': 0,
    });
  }

  // ── Read ─────────────────────────────────────────────────────────────────────

  Future<UserProfile?> getProfile(String uid) async {
    final doc = await _users.doc(uid).get();
    if (!doc.exists) return null;
    return UserProfile.fromMap(uid, doc.data() as Map<String, dynamic>);
  }

  Stream<UserProfile?> watchProfile(String uid) {
    return _users.doc(uid).snapshots().map((doc) {
      if (!doc.exists) return null;
      return UserProfile.fromMap(uid, doc.data() as Map<String, dynamic>);
    });
  }

  // ── Update after game ────────────────────────────────────────────────────────

  Future<void> recordGameResult({
    required String uid,
    required int score,
    required bool won,
  }) async {
    await _db.runTransaction((tx) async {
      final ref = _users.doc(uid);
      final snap = await tx.get(ref);
      if (!snap.exists) return;

      final data = snap.data() as Map<String, dynamic>;
      final newScore = (data['totalScore'] ?? 0) + score;
      final newGames = (data['gamesPlayed'] ?? 0) + 1;
      final newWins = (data['gamesWon'] ?? 0) + (won ? 1 : 0);

      tx.update(ref, {
        'totalScore': newScore,
        'gamesPlayed': newGames,
        'gamesWon': newWins,
      });

      // Leaderboard mirror
      final lbRef = _leaderboard.doc(uid);
      tx.set(
        lbRef,
        {
          'username': data['username'],
          'totalScore': newScore,
          'gamesPlayed': newGames,
          'gamesWon': newWins,
        },
        SetOptions(merge: true),
      );
    });
  }

  // ── Streak ───────────────────────────────────────────────────────────────────

  /// Call once per game session. Returns the updated streak count.
  Future<int> updateStreak(String uid) async {
    final today = _todayStr();
    int newStreak = 1;

    await _db.runTransaction((tx) async {
      final ref = _users.doc(uid);
      final snap = await tx.get(ref);
      if (!snap.exists) return;

      final data = snap.data() as Map<String, dynamic>;
      final last = data['lastPlayedDate'] as String?;
      final current = (data['streak'] ?? 0) as int;

      if (last == today) {
        newStreak = current; // already played today, no change
      } else if (last == _yesterdayStr()) {
        newStreak = current + 1; // continue streak
      } else {
        newStreak = 1; // reset
      }

      tx.update(ref, {'streak': newStreak, 'lastPlayedDate': today});
    });
    return newStreak;
  }

  // ── Speed High Score ─────────────────────────────────────────────────────────

  Future<void> updateSpeedScore(String uid, int score) async {
    final ref = _users.doc(uid);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) return;
      final data = snap.data() as Map<String, dynamic>;
      final current = (data['speedHighScore'] ?? 0) as int;
      if (score > current) {
        tx.update(ref, {'speedHighScore': score});
      }
    });
  }

  // ── Continent Progress ────────────────────────────────────────────────────────

  Future<void> updateContinentStars(
      String uid, String continent, int stars) async {
    final ref = _users.doc(uid);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) return;
      final data = snap.data() as Map<String, dynamic>;
      final Map<String, dynamic> current =
          Map<String, dynamic>.from(data['continentStars'] ?? {});
      final existing = (current[continent] ?? 0) as int;
      if (stars > existing) {
        current[continent] = stars;
        tx.update(ref, {'continentStars': current});
      }
    });
  }

  // ── Achievements ──────────────────────────────────────────────────────────────

  Future<bool> unlockAchievement(String uid, String achievementId) async {
    bool unlocked = false;
    final ref = _users.doc(uid);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) return;
      final data = snap.data() as Map<String, dynamic>;
      final List<String> list = List<String>.from(data['achievements'] ?? []);
      if (!list.contains(achievementId)) {
        list.add(achievementId);
        tx.update(ref, {'achievements': list});
        unlocked = true;
      }
    });
    return unlocked;
  }

  // ── Helpers ───────────────────────────────────────────────────────────────────

  String _todayStr() {
    final now = DateTime.now();
    return '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  String _yesterdayStr() {
    final y = DateTime.now().subtract(const Duration(days: 1));
    return '${y.year}-${y.month.toString().padLeft(2, '0')}-${y.day.toString().padLeft(2, '0')}';
  }
}
