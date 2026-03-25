class UserProfile {
  final String uid;
  final String username;
  final String email;
  final int totalScore;
  final int gamesPlayed;
  final int gamesWon;
  final int streak;
  final String? lastPlayedDate; // YYYY-MM-DD
  final int speedHighScore;
  final List<String> achievements;
  final Map<String, int> continentStars; // {Africa: 3, Europe: 2, ...}
  final List<Map<String, String>> friends; // [{uid, username}, ...]

  const UserProfile({
    required this.uid,
    required this.username,
    required this.email,
    this.totalScore = 0,
    this.gamesPlayed = 0,
    this.gamesWon = 0,
    this.streak = 0,
    this.lastPlayedDate,
    this.speedHighScore = 0,
    this.achievements = const [],
    this.continentStars = const {},
    this.friends = const [],
  });

  factory UserProfile.fromMap(String uid, Map<String, dynamic> data) {
    return UserProfile(
      uid: uid,
      username: data['username'] ?? 'Player',
      email: data['email'] ?? '',
      totalScore: (data['totalScore'] ?? 0) as int,
      gamesPlayed: (data['gamesPlayed'] ?? 0) as int,
      gamesWon: (data['gamesWon'] ?? 0) as int,
      streak: (data['streak'] ?? 0) as int,
      lastPlayedDate: data['lastPlayedDate'] as String?,
      speedHighScore: (data['speedHighScore'] ?? 0) as int,
      achievements: List<String>.from(data['achievements'] ?? []),
      continentStars: Map<String, int>.from(data['continentStars'] ?? {}),
      friends: (data['friends'] as List<dynamic>? ?? []).map((f) {
        final m = f as Map<String, dynamic>;
        return {'uid': m['uid'] as String, 'username': m['username'] as String};
      }).toList(),
    );
  }

  Map<String, dynamic> toMap() => {
        'username': username,
        'usernameLower': username.toLowerCase(),
        'email': email,
        'totalScore': totalScore,
        'gamesPlayed': gamesPlayed,
        'gamesWon': gamesWon,
        'streak': streak,
        'lastPlayedDate': lastPlayedDate,
        'speedHighScore': speedHighScore,
        'achievements': achievements,
        'continentStars': continentStars,
        'friends': friends,
      };

  UserProfile copyWith({
    String? username,
    int? totalScore,
    int? gamesPlayed,
    int? gamesWon,
    int? streak,
    String? lastPlayedDate,
    int? speedHighScore,
    List<String>? achievements,
    Map<String, int>? continentStars,
    List<Map<String, String>>? friends,
  }) =>
      UserProfile(
        uid: uid,
        username: username ?? this.username,
        email: email,
        totalScore: totalScore ?? this.totalScore,
        gamesPlayed: gamesPlayed ?? this.gamesPlayed,
        gamesWon: gamesWon ?? this.gamesWon,
        streak: streak ?? this.streak,
        lastPlayedDate: lastPlayedDate ?? this.lastPlayedDate,
        speedHighScore: speedHighScore ?? this.speedHighScore,
        achievements: achievements ?? this.achievements,
        continentStars: continentStars ?? this.continentStars,
        friends: friends ?? this.friends,
      );
}
