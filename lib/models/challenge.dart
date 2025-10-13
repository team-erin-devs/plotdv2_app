enum ChallengeDifficulty { easy, medium, hard }

class Challenge {
  final String id;
  final String title;
  final String description;
  final int points;
  final ChallengeDifficulty difficulty;

  Challenge({
    required this.id,
    required this.title,
    required this.description,
    required this.difficulty,
    required this.points,
  });
}
