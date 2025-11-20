import 'package:flutter/material.dart';
import '../models/challenge.dart';

class UploadMissionCard extends StatelessWidget {
  final String title;
  final String description;
  final ChallengeDifficulty difficulty;
  final int points;
  final List<Color> gradient;
  final Widget uploadSection;
  final String timeRemaining; // Added this parameter

  const UploadMissionCard({
    super.key,
    required this.title,
    required this.description,
    required this.difficulty,
    required this.points,
    required this.gradient,
    required this.uploadSection,
    required this.timeRemaining, // Added this parameter
  });

  String _difficultyLabel(ChallengeDifficulty difficulty) {
    switch (difficulty) {
      case ChallengeDifficulty.easy:
        return 'easy';
      case ChallengeDifficulty.medium:
        return 'medium';
      case ChallengeDifficulty.hard:
        return 'hard';
    }
  }

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(28);
    final accent = gradient.first;
    final difficultyLabel = _difficultyLabel(difficulty);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: radius,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradient,
        ),
        boxShadow: [
          BoxShadow(
            color: accent.withOpacity(0.4),
            blurRadius: 40,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              Text(
                title,
                style: const TextStyle(
                  fontFamily: 'Epoch',
                  fontWeight: FontWeight.w400,
                  fontSize: 36,
                  height: 1.1,
                  letterSpacing: -0.7,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),

              // Row with difficulty/points and time remaining
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left: Difficulty and points
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _DifficultyPill(label: difficultyLabel, color: accent),
                      const SizedBox(height: 8),
                      Text(
                        '$points points',
                        style: TextStyle(
                          fontFamily: 'Urbanist',
                          fontWeight: FontWeight.w400,
                          fontSize: 16,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  // Right: Time remaining
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'time remaining',
                        style: TextStyle(
                          fontFamily: 'Urbanist',
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.7),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        timeRemaining, // Use the passed timer value
                        style: const TextStyle(
                          fontFamily: 'Urbanist',
                          fontWeight: FontWeight.w700,
                          fontSize: 24,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Description
              Text(
                description,
                style: TextStyle(
                  fontFamily: 'Urbanist',
                  fontWeight: FontWeight.w500,
                  fontSize: 15,
                  height: 1.5,
                  color: Colors.white.withOpacity(0.9),
                ),
              ),
              const SizedBox(height: 24),

              // Upload section (injected from parent)
              uploadSection,
            ],
          ),
        ),
      ),
    );
  }
}

class _DifficultyPill extends StatelessWidget {
  final String label;
  final Color color;

  const _DifficultyPill({
    required this.label,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          width: 1.2,
          color: Colors.white.withOpacity(0.5),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 10),
          Text(
            label,
            style: const TextStyle(
              fontFamily: 'Urbanist',
              fontWeight: FontWeight.w400,
              fontSize: 16,
              height: 1.0,
              letterSpacing: -0.32,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}