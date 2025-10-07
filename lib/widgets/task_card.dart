import 'package:flutter/material.dart';
import '../models/task.dart';
import '../screens/task_detail_screen.dart';

class TaskCard extends StatelessWidget {
  final Task task;

  const TaskCard({super.key, required this.task});

  Color _getDifficultyColor() {
    switch (task.difficulty) {
      case TaskDifficulty.easy:
        return Colors.greenAccent;
      case TaskDifficulty.medium:
        return Colors.amberAccent;
      case TaskDifficulty.hard:
        return Colors.redAccent;
    }
  }

  String _getDifficultyLabel() {
    switch (task.difficulty) {
      case TaskDifficulty.easy:
        return 'EASY';
      case TaskDifficulty.medium:
        return 'MEDIUM';
      case TaskDifficulty.hard:
        return 'HARD';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.grey[900], // dark minimalist background
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TaskDetailScreen(task: task),
            ),
          );
        },
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title + Difficulty Label
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      task.title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getDifficultyColor().withOpacity(0.2),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      _getDifficultyLabel(),
                      style: TextStyle(
                        fontSize: 12,
                        color: _getDifficultyColor(),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                task.description,
                style: const TextStyle(fontSize: 14, color: Colors.white70),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
