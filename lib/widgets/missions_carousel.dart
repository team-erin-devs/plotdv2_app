import 'package:flutter/material.dart';
import 'package:team_erin_app/screens/challenge_detail_screen.dart';
import "../models/challenge.dart";
import '../services/api_service.dart';

class MissionsCarousel extends StatefulWidget {
  const MissionsCarousel({super.key});

  @override
  State<MissionsCarousel> createState() => _MissionsCarouselState();
}

class _MissionsCarouselState extends State<MissionsCarousel> {
  late final PageController _ctrl;
  late Future<List<Challenge>> _future;

  // show neighbors - adjusted for better peek
  static const double _viewport = 0.75;

  // brand gradients
  final List<List<Color>> _grads = const [
    [Color(0xFFA621ED), Color(0xFF5E1387)], // purple
    [Color(0xFFED2190), Color(0xFF871352)], // pink
    [Color(0xFF23B2CA), Color(0xFF126C87)], // cyan
  ];

  @override
  void initState() {
    super.initState();
    // Start at a high page number to allow infinite scrolling
    _ctrl = PageController(initialPage: 1000, viewportFraction: 0.75);
    _future = ApiService.fetchChallenge();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  String _difficultyLabel(dynamic difficulty) {
    if (difficulty == null) return 'N/A';

    // Enum: ChallengeDifficulty.easy -> "Easy"
    if (difficulty is Enum) {
      final n = difficulty.name; // Dart enums expose .name
      return n.isEmpty ? 'N/A' : n[0].toUpperCase() + n.substring(1);
    }

    // String: "ChallengeDifficulty.easy" or "easy" -> "Easy"
    if (difficulty is String) {
      final raw = difficulty.trim();
      if (raw.isEmpty) return 'N/A';
      final tail = raw.contains('.') ? raw.split('.').last : raw;
      final lower = tail.toLowerCase();
      if (lower == 'easy' || lower == 'medium' || lower == 'hard') {
        return lower[0].toUpperCase() + lower.substring(1);
      }
      return tail[0].toUpperCase() + tail.substring(1);
    }

    // Int mapping
    if (difficulty is int) {
      switch (difficulty) {
        case 1: return 'Easy';
        case 2: return 'Medium';
        case 3: return 'Hard';
        default: return 'N/A';
      }
    }

    // Fallback
    final s = difficulty.toString().trim();
    if (s.isEmpty) return 'N/A';
    final tail = s.contains('.') ? s.split('.').last : s;
    return tail[0].toUpperCase() + tail.substring(1);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Challenge>>(
      future: _future,
      builder: (context, snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const SizedBox(height: 380, child: Center(child: CircularProgressIndicator()));
        }
        if (snap.hasError) {
          return SizedBox(
            height: 380,
            child: Center(child: Text('Failed to load challenges', style: TextStyle(color: Colors.red.shade300))),
          );
        }

        final items = snap.data ?? const <Challenge>[];
        if (items.isEmpty) {
          return const SizedBox(
            height: 380,
            child: Center(child: Text('No challenges right now', style: TextStyle(color: Colors.white70))),
          );
        }

        return LayoutBuilder(
          builder: (_, c) {
            final height = (c.maxWidth < 420) ? 370.0 : 390.0;

            return SizedBox(
              height: height,
              child: PageView.builder(
                controller: _ctrl,
                padEnds: true,
                physics: const BouncingScrollPhysics(),
                clipBehavior: Clip.none,
                // Remove itemCount for infinite scrolling
                itemBuilder: (context, index) {
                  // Use modulo to loop through the actual items
                  final actualIndex = index % items.length;
                  final challenge = items[actualIndex];
                  final grad = _grads[actualIndex % _grads.length];
                  final accent = grad.first;

                  final title = (challenge.title ?? '').trim().isEmpty
                      ? 'Untitled'
                      : challenge.title!;
                  final difficulty = _difficultyLabel(challenge.difficulty);


                  return AnimatedBuilder(
                    animation: _ctrl,
                    builder: (_, __) {
                      double t = 0;
                      if (_ctrl.position.haveDimensions) {
                        final page = _ctrl.page ?? _ctrl.initialPage.toDouble();
                        t = page - index.toDouble();
                      }

                      // Enhanced depth curve - centered card is at center
                      final scale = (1 - (t.abs() * 0.20)).clamp(0.80, 1.0);
                      final lift = (1 - t.abs()) * 20.0;
                      final fade = (1 - (t.abs() * 0.55)).clamp(0.45, 1.0);
                      final isMain = t.abs() < 0.20;

                      return Transform.translate(
                        offset: Offset(0, -lift),
                        child: Transform.scale(
                          scale: scale,
                          alignment: Alignment.center,
                          child: Opacity(
                            opacity: fade,
                            child: _MissionCard(
                              title: title,
                              difficulty: difficulty,
                              gradient: grad,
                              accent: accent,
                              isMain: isMain,
                              challenge: challenge,
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            );
          },
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
  final Challenge challenge;

  const _MissionCard({
    required this.title,
    required this.difficulty,
    required this.gradient,
    required this.accent,
    required this.isMain,
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

    return Stack(
      children: [
        // Glow bloom BEHIND
        Positioned.fill(
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: accent.withOpacity(isMain ? 0.6 : 0.25),
                    blurRadius: isMain ? 100 : 40,
                    spreadRadius: isMain ? 10 : 4,
                    offset: const Offset(0, 20),
                  ),
                ],
              ),
            ),
          ),
        ),

        // Card container
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            borderRadius: radius,
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: gradient,
            ),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Colors.black.withOpacity(0.4),
                blurRadius: isMain ? 30 : 20,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: radius,
            child: Stack(
              children: [
                // Dark vignette overlay for depth
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        radius: 1.2,
                        center: const Alignment(-0.3, -0.4),
                        colors: [
                          Colors.black.withOpacity(0.00),
                          Colors.black.withOpacity(0.12),
                          Colors.black.withOpacity(0.25),
                        ],
                        stops: const [0.3, 0.7, 1.0],
                      ),
                    ),
                  ),
                ),
                
                // Subtle highlight in top corner
                Positioned(
                  left: -50,
                  top: -70,
                  child: Container(
                    width: 200,
                    height: 200,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: RadialGradient(
                        colors: [
                          Colors.white.withOpacity(0.15),
                          Colors.white.withOpacity(0.00),
                        ],
                      ),
                    ),
                  ),
                ),

                // Content
                Padding(
                  padding: pad,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(
                        title,
                        style: TextStyle(
                          fontFamily: 'Epoch',
                          fontWeight: FontWeight.w400,
                          fontSize: isMain ? 42 : 32,
                          height: isMain ? 1.05 : 1.1,
                          letterSpacing: isMain ? -0.9 : -0.7,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Difficulty pill
                      _DifficultyPill(
                        label: difficulty,
                        color: accent,
                        isMain: isMain,
                      ),

                      const Spacer(),

                      // CTA button
                      _CTA(isMain: isMain, accentColor: accent, challenge: challenge),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
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
        color: Colors.white.withOpacity(0.08),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: dotSize,
            height: dotSize,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
          ),
          SizedBox(width: isMain ? 10 : 8),
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Urbanist',
              fontWeight: FontWeight.w600,
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
    required this.challenge,});

  @override
  Widget build(BuildContext context) {
    final h = isMain ? 50.0 : 40.0;
    final r = BorderRadius.circular(isMain ? 14 : 12);
    final textSize = isMain ? 16.0 : 14.0;

    return SizedBox(
      height: h,
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
          shape: RoundedRectangleBorder(borderRadius: r),
          padding: EdgeInsets.zero,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'See details',
              style: TextStyle(
                fontFamily: 'Urbanist',
                fontWeight: FontWeight.w500,
                fontSize: textSize,
                height: 1.2,
                letterSpacing: -0.34,
              ),
            ),
            const SizedBox(width: 8),
            Icon(
              Icons.arrow_forward,
              size: isMain ? 22 : 20,
              color: accentColor,
            ),
          ],
        ),
      ),
    );
  }
}