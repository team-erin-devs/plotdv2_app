class LeaderboardEntry {
  final String username;
  final int totalPoints;
  final String university;
  final int rank;

  LeaderboardEntry({
    required this.username,
    required this.totalPoints,
    required this.university,
    required this.rank,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      username: json['username'] ?? '',
      totalPoints: json['total_points'] ?? 0,
      university: json['university'] ?? '',
      rank: json['rank'] ?? 0,
    );
  }
}
