class LeaderboardEntry {
  final String id;
  final String username;
  final int score;
  final String? avatarUrl; // Optional avatar
  final int rank;

  LeaderboardEntry({
    required this.id,
    required this.username,
    required this.score,
    this.avatarUrl,
    required this.rank,
  });

  // Factory constructor to create from JSON (for API calls later)
  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      id: json['id'].toString(),
      username: json['username'],
      score: json['score'],
      avatarUrl: json['avatar_url'],
      rank: json['rank'],
    );
  }
}
