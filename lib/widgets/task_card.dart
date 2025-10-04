import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
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
    final pixelFont = GoogleFonts.pressStart2p(
      textStyle: const TextStyle(fontSize: 10, color: Colors.white),
    );

    return Card(
      color: Colors.black,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.zero, // pixel vibe
        side: BorderSide(color: _getDifficultyColor(), width: 2),
      ),
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
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title + Difficulty Badge
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      task.title.toUpperCase(),
                      style: pixelFont.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: _getDifficultyColor(),
                      borderRadius: BorderRadius.zero,
                    ),
                    child: Text(
                      _getDifficultyLabel(),
                      style: pixelFont.copyWith(
                        fontSize: 8,
                        color: Colors.black,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                task.description,
                style: pixelFont.copyWith(fontSize: 8, color: Colors.white70),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
