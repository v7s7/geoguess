class EloTier {
  static String getLabel(int elo) {
    if (elo >= 2000) return 'Master 💎';
    if (elo >= 1700) return 'Diamond 💠';
    if (elo >= 1500) return 'Platinum 🔷';
    if (elo >= 1300) return 'Gold 🥇';
    if (elo >= 1100) return 'Silver 🥈';
    return 'Bronze 🥉';
  }

  static String getTierName(int elo) {
    if (elo >= 2000) return 'Master';
    if (elo >= 1700) return 'Diamond';
    if (elo >= 1500) return 'Platinum';
    if (elo >= 1300) return 'Gold';
    if (elo >= 1100) return 'Silver';
    return 'Bronze';
  }

  static String getTierEmoji(int elo) {
    if (elo >= 2000) return '💎';
    if (elo >= 1700) return '💠';
    if (elo >= 1500) return '🔷';
    if (elo >= 1300) return '🥇';
    if (elo >= 1100) return '🥈';
    return '🥉';
  }
}
