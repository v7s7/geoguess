import 'package:cloud_firestore/cloud_firestore.dart';

class LeaderboardEntry {
  final String uid;
  final String username;
  final int totalScore;
  final int gamesPlayed;
  final int gamesWon;
  int rank;

  LeaderboardEntry({
    required this.uid,
    required this.username,
    required this.totalScore,
    required this.gamesPlayed,
    required this.gamesWon,
    this.rank = 0,
  });

  factory LeaderboardEntry.fromDoc(String uid, Map<String, dynamic> data) =>
      LeaderboardEntry(
        uid: uid,
        username: data['username'] ?? 'Player',
        totalScore: (data['totalScore'] ?? 0) as int,
        gamesPlayed: (data['gamesPlayed'] ?? 0) as int,
        gamesWon: (data['gamesWon'] ?? 0) as int,
      );
}

class LeaderboardService {
  final _db = FirebaseFirestore.instance;

  Future<List<LeaderboardEntry>> getTopPlayers({int limit = 50}) async {
    final snap = await _db
        .collection('leaderboard')
        .orderBy('totalScore', descending: true)
        .limit(limit)
        .get();

    final entries = snap.docs
        .map((d) => LeaderboardEntry.fromDoc(d.id, d.data()))
        .toList();

    for (int i = 0; i < entries.length; i++) {
      entries[i].rank = i + 1;
    }
    return entries;
  }

  Future<int> getMyRank(String uid) async {
    final myDoc = await _db.collection('leaderboard').doc(uid).get();
    if (!myDoc.exists) return 0;
    final myScore = (myDoc.data()?['totalScore'] ?? 0) as int;

    final above = await _db
        .collection('leaderboard')
        .where('totalScore', isGreaterThan: myScore)
        .count()
        .get();

    return (above.count ?? 0) + 1;
  }
}
