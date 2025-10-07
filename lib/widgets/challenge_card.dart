import 'package:flutter/material.dart';
import '../models/challenge.dart';
import '../screens/challenge_detail_screen.dart';

class ChallengeCard extends StatelessWidget {
  final Challenge challenge;

  const ChallengeCard({super.key, required this.challenge});

  Color _getDifficultyColor() {
    switch (challenge.difficulty) {
      case ChallengeDifficulty.easy:
        return Colors.greenAccent;
      case ChallengeDifficulty.medium:
        return Colors.amberAccent;
      case ChallengeDifficulty.hard:
        return Colors.redAccent;
    }
  }

  String _getDifficultyLabel() {
    switch (challenge.difficulty) {
      case ChallengeDifficulty.easy:
        return 'EASY';
      case ChallengeDifficulty.medium:
        return 'MEDIUM';
      case ChallengeDifficulty.hard:
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
              builder: (context) => ChallengeDetailScreen(challenge: challenge),
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
                      challenge.title,
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
                challenge.description,
                style: const TextStyle(fontSize: 14, color: Colors.white70),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
