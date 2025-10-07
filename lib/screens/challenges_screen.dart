import 'package:flutter/material.dart';
import 'package:team_erin_app/widgets/task_card.dart';
import '../models/task.dart';

class ChallengesScreen extends StatelessWidget {
  const ChallengesScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final List<Task> challenges = [
      Task(
        id: '1',
        title: 'Morning Workout',
        description: 'Complete a 30-minute morning exercise routine',
        difficulty: TaskDifficulty.easy,
      ),
      Task(
        id: '2',
        title: 'Cook a New Recipe',
        description: 'Try cooking a dish you\'ve never made before',
        difficulty: TaskDifficulty.medium,
      ),
      Task(
        id: '3',
        title: 'Learn a Dance Routine',
        description: 'Master a full choreographed dance routine',
        difficulty: TaskDifficulty.hard,
      ),
    ];

    return Scaffold(
      backgroundColor: Colors.black, // Minimal dark background
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  "Today's Challenges",
                  style: TextStyle(
                    color: Colors.white70,
                    fontSize: 18,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 20),
                // Tasks
                for (var task in challenges) ...[
                  TaskCard(task: task),
                  const SizedBox(height: 12),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
