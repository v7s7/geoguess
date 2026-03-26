import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_profile.dart';
import '../models/daily_quest.dart';

class UserService {
  final _db = FirebaseFirestore.instance;

  CollectionReference get _users => _db.collection('users');
  CollectionReference get _leaderboard => _db.collection('leaderboard');

  // ── Username uniqueness ────────────────────────────────────────────────────────

  /// Returns true if [username] has not been taken yet (case-insensitive).
  Future<bool> isUsernameAvailable(String username) async {
    final lower = username.trim().toLowerCase();
    if (lower.isEmpty) return false;
    final snap = await _users
        .where('usernameLower', isEqualTo: lower)
        .limit(1)
        .get();
    return snap.docs.isEmpty;
  }

  // ── Create ──────────────────────────────────────────────────────────────────

  Future<void> createProfile({
    required String uid,
    required String username,
    required String email,
  }) async {
    final data = UserProfile(uid: uid, username: username, email: email).toMap();
    // toMap() already includes usernameLower via the model
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

    // Also reset quests if it's a new day
    await resetQuestsIfNewDay(uid);

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

  // ── ELO ──────────────────────────────────────────────────────────────────────

  /// Updates ELO rating: win+25, draw+5, loss-15, min 0.
  Future<void> updateElo(String uid, bool won, bool isDraw) async {
    final ref = _users.doc(uid);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) return;
      final data = snap.data() as Map<String, dynamic>;
      final current = (data['eloRating'] ?? 1000) as int;
      int delta;
      if (isDraw) {
        delta = 5;
      } else if (won) {
        delta = 25;
      } else {
        delta = -15;
      }
      final newElo = (current + delta).clamp(0, 999999);
      tx.update(ref, {'eloRating': newElo});
      // Mirror to leaderboard
      final lbRef = _leaderboard.doc(uid);
      tx.set(lbRef, {'eloRating': newElo}, SetOptions(merge: true));
    });
  }

  // ── GeoCoins ─────────────────────────────────────────────────────────────────

  Future<void> addCoins(String uid, int amount) async {
    final ref = _users.doc(uid);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) return;
      final data = snap.data() as Map<String, dynamic>;
      final current = (data['geoCoins'] ?? 0) as int;
      tx.update(ref, {'geoCoins': current + amount});
    });
  }

  // ── Daily Quests ─────────────────────────────────────────────────────────────

  /// Returns list of newly completed quest IDs.
  Future<List<String>> updateQuestProgress(String uid, QuestType type, int increment) async {
    final todayQuests = QuestDefinitions.getForToday();
    final matching = todayQuests.where((q) => q.type == type).toList();
    if (matching.isEmpty) return [];

    final List<String> completed = [];
    final ref = _users.doc(uid);

    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) return;
      final data = snap.data() as Map<String, dynamic>;
      final Map<String, dynamic> rawProgress =
          Map<String, dynamic>.from(data['questProgress'] ?? {});
      final Map<String, int> progress =
          rawProgress.map((k, v) => MapEntry(k, (v as num).toInt()));

      int coinsToAdd = 0;
      for (final quest in matching) {
        final prev = progress[quest.id] ?? 0;
        final wasCompleted = prev >= quest.target;
        if (wasCompleted) continue; // already completed

        final newVal = (prev + increment).clamp(0, quest.target);
        progress[quest.id] = newVal;
        if (newVal >= quest.target) {
          completed.add(quest.id);
          coinsToAdd += quest.rewardCoins;
        }
      }

      final currentCoins = (data['geoCoins'] ?? 0) as int;
      tx.update(ref, {
        'questProgress': progress,
        if (coinsToAdd > 0) 'geoCoins': currentCoins + coinsToAdd,
      });
    });

    return completed;
  }

  Future<void> resetQuestsIfNewDay(String uid) async {
    final today = _todayStr();
    final ref = _users.doc(uid);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) return;
      final data = snap.data() as Map<String, dynamic>;
      final lastQuestDate = data['lastQuestDate'] as String?;
      if (lastQuestDate != today) {
        tx.update(ref, {
          'questProgress': {},
          'lastQuestDate': today,
        });
      }
    });
  }

  // ── Cosmetics ────────────────────────────────────────────────────────────────

  /// Returns false if insufficient coins.
  Future<bool> purchaseCosmetic(String uid, String itemId, int price) async {
    bool success = false;
    final ref = _users.doc(uid);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (!snap.exists) return;
      final data = snap.data() as Map<String, dynamic>;
      final coins = (data['geoCoins'] ?? 0) as int;
      if (coins < price) return;
      final owned = List<String>.from(data['ownedCosmetics'] ?? []);
      if (owned.contains(itemId)) { success = true; return; }
      owned.add(itemId);
      tx.update(ref, {'geoCoins': coins - price, 'ownedCosmetics': owned});
      success = true;
    });
    return success;
  }

  Future<void> equipCosmetic(String uid, String itemId) async {
    await _users.doc(uid).update({'activeAvatarBorder': itemId});
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
