enum TaskDifficulty { easy, medium, hard }

class Task {
  final String id;
  final String title;
  final String description;
  final TaskDifficulty difficulty;

  Task({
    required this.id,
    required this.title,
    required this.description,
    required this.difficulty,
  });
}
