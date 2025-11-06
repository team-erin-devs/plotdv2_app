import 'package:flutter/material.dart';
import '../models/challenge.dart';
import '../services/api_service.dart';

class MissionCard extends StatefulWidget {
  const MissionCard({super.key, 
  required String title, 
  required ChallengeDifficulty difficulty, 
  required List<Color> gradient, 
  required int points, 
  /*required timeRemaining*/});

  @override
  State<MissionCard> createState() => _MissionCardState();
}

class _MissionCardState extends State<MissionCard> {
  late Future<List<Challenge>> _future;

  final List<List<Color>> _gradients = const [
    [Color(0xFFA621ED), Color(0xFF5E1387)], // purple
    [Color(0xFFED2190), Color(0xFF871352)], // pink
    [Color(0xFF23B2CA), Color(0xFF126C87)], // cyan
  ];

  @override
  void initState() {
    super.initState();
    _future = ApiService.fetchChallenge();
  }

  String _difficultyLabel(dynamic difficulty) {
    if (difficulty == null) return 'N/A';
    if (difficulty is String) {
      final val = difficulty.split('.').last;
      return val[0].toUpperCase() + val.substring(1).toLowerCase();
    }
    if (difficulty is int) {
      switch (difficulty) {
        case 1:
          return 'Easy';
        case 2:
          return 'Medium';
        case 3:
          return 'Hard';
      }
    }
    return difficulty.toString();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Challenge>>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snap.hasError) {
          return Center(
            child: Text(
              'Failed to load data',
              style: TextStyle(color: Colors.red.shade300),
            ),
          );
        }

        final items = snap.data ?? [];
        if (items.isEmpty) {
          return const Text('No challenges available');
        }

        // Use first challenge as example
        final challenge = items.first;
        final title = challenge.title;
        final difficulty = _difficultyLabel(challenge.difficulty);
        final grad = _gradients.first;
        final accent = grad.first;

        // Responsiveness
        final screenWidth = MediaQuery.of(context).size.width;
        final isMain = screenWidth > 400; // larger layout for tablets/desktops

        return _MissionCard(
          title: title,
          difficulty: difficulty,
          gradient: grad,
          accent: accent,
          isMain: isMain,
        );
      },
    );
  }
}

class _MissionCard extends StatelessWidget {
  final String title;
  final String difficulty;
  final List<Color> gradient;
  final Color accent;
  final bool isMain;

  const _MissionCard({
    required this.title,
    required this.difficulty,
    required this.gradient,
    required this.accent,
    required this.isMain,
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

              // Difficulty pill
              _DifficultyPill(
                label: difficulty,
                color: accent,
                isMain: isMain,
              ),
              
              SizedBox(height: isMain ? 120 : 100),
              // CTA
              _CTA(isMain: isMain),
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

    return Container(
      height: h,
      padding: EdgeInsets.symmetric(horizontal: isMain ? 16 : 14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(r),
        border: Border.all(
          color: Colors.white.withOpacity(0.5),
        ),
        color: Colors.white.withOpacity(0.08),
      ),
      child: Center(
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Urbanist',
            fontWeight: FontWeight.w600,
            fontSize: isMain ? 16 : 14,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

class _CTA extends StatelessWidget {
  final bool isMain;

  const _CTA({required this.isMain});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: isMain ? 50 : 40,
      width: double.infinity,
      child: TextButton(
        onPressed: () {},
        style: TextButton.styleFrom(
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF030303),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(isMain ? 14 : 12),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'See details',
              style: TextStyle(
                fontFamily: 'Urbanist',
                fontWeight: FontWeight.w700,
                fontSize: isMain ? 16 : 14,
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.arrow_forward,
              size: isMain ? 22 : 20,
              color: const Color(0xFF030303),
            ),
          ],
        ),
      ),
    );
  }
}