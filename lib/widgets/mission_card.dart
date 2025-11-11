import 'package:flutter/material.dart';
import 'package:team_erin_app/screens/challenge_detail_screen.dart';
import '../models/challenge.dart';

class MissionCard extends StatelessWidget {
  final String title;
  final ChallengeDifficulty difficulty;
  final List<Color> gradient;
  final int points;
  final Challenge challenge;
  final bool isMain;

  const MissionCard({
    super.key,
    required this.title,
    required this.difficulty,
    required this.gradient,
    required this.points,
    required this.challenge,
    this.isMain = true,
  });

  String _difficultyLabel(ChallengeDifficulty difficulty) {
    switch (difficulty) {
      case ChallengeDifficulty.easy:
        return 'easy';
      case ChallengeDifficulty.medium:
        return 'medium';
      case ChallengeDifficulty.hard:
        return 'hard';
      default:
        return 'N/A';
    }
  }

  @override
  Widget build(BuildContext context) {
    final accent = gradient.first;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMain = screenWidth > 400;

    return _MissionCard(
      title: title,
      difficulty: _difficultyLabel(difficulty),
      gradient: gradient,
      accent: accent,
      isMain: isMain,
      points: points,
      challenge: challenge,
    );
  }
}

class _MissionCard extends StatelessWidget {
  final String title;
  final String difficulty;
  final List<Color> gradient;
  final Color accent;
  final bool isMain;
  final int points;
  final Challenge challenge;

  const _MissionCard({
    required this.title,
    required this.difficulty,
    required this.gradient,
    required this.accent,
    required this.isMain,
    required this.points,
    required this.challenge,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(isMain ? 28 : 22);
    final pad = EdgeInsets.fromLTRB(
      isMain ? 28 : 22,
      isMain ? 28 : 22,
      isMain ? 28 : 22,
      isMain ? 24 : 18,
    );

    return Container(
      margin: const EdgeInsets.all(16),
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
            blurRadius: isMain ? 40 : 25,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: radius,
        child: Padding(
          padding: pad,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              // Title
              Text(
                title,
                style: TextStyle(
                  fontFamily: 'Epoch',
                  fontWeight: FontWeight.w400,
                  fontSize: isMain ? 36 : 28,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),

              // Row with difficulty/points column and time remaining column
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Left column: Difficulty pill and points
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _DifficultyPill(
                        label: difficulty,
                        color: accent,
                        isMain: isMain,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '$points points',
                        style: TextStyle(
                          fontFamily: 'Urbanist',
                          fontWeight: FontWeight.w400,
                          fontSize: isMain ? 16 : 14,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                    ],
                  ),
                  
                  const Spacer(),
                  
                  // Right column: Time remaining
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'time remaining',
                        style: TextStyle(
                          fontFamily: 'Urbanist',
                          fontWeight: FontWeight.w500,
                          fontSize: isMain ? 14 : 12,
                          color: Colors.white.withOpacity(0.9),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '0d 22h 33m 45s',
                        style: TextStyle(
                          fontFamily: 'Urbanist',
                          fontWeight: FontWeight.w700,
                          fontSize: isMain ? 24 : 20,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ],
              ),

              SizedBox(height: isMain ? 24 : 20),

              // CTA
              _CTA(isMain: isMain, accentColor: accent, challenge: challenge),
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
  final bool isMain;

  const _DifficultyPill({
    required this.label,
    required this.color,
    required this.isMain,
  });

  @override
  Widget build(BuildContext context) {
    final h = isMain ? 32.0 : 26.0;
    final r = isMain ? 16.0 : 13.0;
    final dotSize = isMain ? 8.0 : 6.5;

    return Container(
      height: h,
      padding: EdgeInsets.symmetric(
        horizontal: isMain ? 16 : 14,
        vertical: isMain ? 6 : 5,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(r),
        border: Border.all(
          width: isMain ? 1.2 : 1.0,
          color: Colors.white.withOpacity(0.5),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: dotSize,
            height: dotSize,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: isMain ? 10 : 8),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Urbanist',
              fontWeight: FontWeight.w500,
              fontSize: isMain ? 16 : 14,
              height: 1.0,
              letterSpacing: isMain ? -0.32 : -0.28,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _CTA extends StatelessWidget {
  final bool isMain;
  final Color accentColor;
  final Challenge challenge;

  const _CTA({
    required this.isMain,
    required this.accentColor,
    required this.challenge,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: isMain ? 56 : 48,
      width: double.infinity,
      child: TextButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ChallengeDetailScreen(challenge: challenge),
            ),
          );
        },
        style: TextButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: accentColor,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(isMain ? 16 : 14),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'See details',
              style: TextStyle(
                fontFamily: 'Urbanist',
                fontWeight: FontWeight.w500,
                fontSize: isMain ? 18 : 16,
              ),
            ),
            const SizedBox(width: 12),
            Icon(
              Icons.arrow_forward,
              size: isMain ? 24 : 22,
              color: accentColor,
            ),
          ],
        ),
      ),
    );
  }
}