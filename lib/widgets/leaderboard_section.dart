import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../models/leaderboard_entry.dart';
import '../services/api_service.dart';

class LeaderboardSection extends StatefulWidget {
  const LeaderboardSection({super.key});

  @override
  State<LeaderboardSection> createState() => _LeaderboardSectionState();
}

class _LeaderboardSectionState extends State<LeaderboardSection> {
  late Future<List<LeaderboardEntry>> _leaderboardFuture;

  @override
  void initState() {
    super.initState();
    _leaderboardFuture = ApiService.fetchLeaderboard(limit: 3);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<LeaderboardEntry>>(
      future: _leaderboardFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
            height: 216, // height to match the cards
            child: Center(
              child: CircularProgressIndicator(color: Colors.white),
            ),
          );
        }

        if (snapshot.hasError) {
          return SizedBox(
            height: 216,
            child: Center(
              child: Text(
                'Failed to load leaderboard',
                style: TextStyle(color: Colors.red.shade300),
              ),
            ),
          );
        }

        final entries = snapshot.data ?? [];
        
        if (entries.isEmpty) {
          return const SizedBox(
            height: 216,
            child: Center(
              child: Text(
                'No leaderboard data yet',
                style: TextStyle(color: Colors.white70),
              ),
            ),
          );
        }

        // Ensure we have at least 3 entries, pad with empty if needed
        final leaderEntries = <LeaderEntry>[];
        for (int i = 0; i < 3; i++) {
          if (i < entries.length) {
            final entry = entries[i];
            leaderEntries.add(LeaderEntry(
              place: entry.rank,
              name: entry.username,
              handle: '@${entry.username.toLowerCase().replaceAll(' ', '')}',
              score: entry.totalPoints,
              avatar: null, // Will use fallback avatar
            ));
          } else {
            // Pad with empty entries if less than 3
            leaderEntries.add(LeaderEntry(
              place: i + 1,
              name: 'No data',
              handle: '@tbd',
              score: 0,
              avatar: null,
            ));
          }
        }

        // Sort by place to ensure correct order
        leaderEntries.sort((a, b) => a.place.compareTo(b.place));

        return _LeaderboardDisplay(entries: leaderEntries);
      },
    );
  }
}

class _LeaderboardDisplay extends StatelessWidget {
  final List<LeaderEntry> entries;

  const _LeaderboardDisplay({required this.entries});

  @override
  Widget build(BuildContext context) {
    final first = entries.firstWhere((e) => e.place == 1);
    final second = entries.firstWhere((e) => e.place == 2);
    final third = entries.firstWhere((e) => e.place == 3);

    return LayoutBuilder(
      builder: (context, c) {
        final w = c.maxWidth;
        const gap = 14.0;
        final cardW = (w - gap * 2) / 3;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _PodiumCard(
              width: cardW,
              height: 162, // 2nd
              entry: second,
              ringColor: const Color(0xFFA621ED), // purple
              trend: _Trend.flat,
            ),
            const SizedBox(width: gap),
            _PodiumCard(
              width: cardW,
              height: 180, // 1st (tallest)
              entry: first,
              ringColor: const Color(0xFF23B2CA), // cyan
              crown: true,
              trend: _Trend.up,
            ),
            const SizedBox(width: gap),
            _PodiumCard(
              width: cardW,
              height: 132, // 3rd (shortest)
              entry: third,
              ringColor: const Color(0xFFED2190), // pink
              trend: _Trend.down,
            ),
          ],
        );
      },
    );
  }
}

class LeaderEntry {
  final int place; // 1,2,3
  final String name;
  final String handle;
  final int score;
  final ImageProvider? avatar;
  const LeaderEntry({
    required this.place,
    required this.name,
    required this.handle,
    required this.score,
    this.avatar,
  });
}

enum _Trend { up, down, flat }

class _PodiumCard extends StatelessWidget {
  final double width;
  final double height;
  final LeaderEntry entry;
  final Color ringColor;
  final bool crown;
  final _Trend trend;

  const _PodiumCard({
    required this.width,
    required this.height,
    required this.entry,
    required this.ringColor,
    this.crown = false,
    this.trend = _Trend.flat,
  });

  @override
  Widget build(BuildContext context) {
    final card = Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: const Color(0xFF2D2D2D),
        border: Border.all(color: const Color(0xFF030303), width: 1),
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.fromLTRB(14, 44, 14, 14),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Flexible(
                child: Text(
                  entry.name,
                  style: const TextStyle(
                    fontFamily: 'Urbanist',
                    fontWeight: FontWeight.w400,
                    fontSize: 16,
                    height: 19 / 16,
                    letterSpacing: -0.023,
                    color: Colors.white,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              _TrendGlyph(
                trend: trend,
                color: trend == _Trend.up
                    ? const Color(0xFF23B2CA)
                    : trend == _Trend.down
                        ? const Color(0xFFED2190)
                        : const Color(0xFFA621ED),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            entry.handle,
            style: const TextStyle(
              fontFamily: 'Urbanist',
              fontWeight: FontWeight.w400,
              fontSize: 14,
              height: 17 / 14,
              letterSpacing: -0.023,
              color: Colors.white,
            ),
            overflow: TextOverflow.ellipsis,
          ),
          const Spacer(),
          Text(
            '${entry.score}',
            style: const TextStyle(
              fontFamily: 'Epoch',
              fontWeight: FontWeight.w400,
              fontSize: 24,
              height: 22 / 24,
              letterSpacing: -0.023,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );

    final avatar = _AvatarWithBadge(
      ringColor: ringColor,
      place: entry.place,
      name: entry.name,
      image: entry.avatar,
      crown: crown,
    );

    return SizedBox(
      width: width,
      height: height + 36,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned.fill(child: card),
          Positioned(
            top: -36,
            left: (width - 60) / 2,
            child: avatar,
          ),
        ],
      ),
    );
  }
}

class _AvatarWithBadge extends StatelessWidget {
  final Color ringColor;
  final int place;
  final String name;
  final ImageProvider? image;
  final bool crown;

  const _AvatarWithBadge({
    required this.ringColor,
    required this.place,
    required this.name,
    required this.image,
    this.crown = false,
  });

  @override
  Widget build(BuildContext context) {
    Widget avatarInner;
    if (image == null) {
      // Fallback: Show first letter of name with gradient background
      avatarInner = Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [ringColor.withOpacity(0.8), ringColor.withOpacity(0.4)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: Colors.white, width: 2),
        ),
        child: Center(
          child: Text(
            name.isNotEmpty ? name[0].toUpperCase() : '?',
            style: const TextStyle(
              fontFamily: 'Epoch',
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      );
    } else {
      avatarInner = Container(
        width: 50,
        height: 50,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          image: DecorationImage(image: image!, fit: BoxFit.cover),
          border: Border.all(color: Colors.white, width: 2),
        ),
      );
    }

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            color: ringColor,
            shape: BoxShape.circle,
            border: Border.all(color: Colors.white, width: 1),
          ),
        ),
        avatarInner,
        Positioned(
          bottom: -8,
          child: Transform.rotate(
            angle: -math.pi / 4,
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                color: ringColor,
                border: Border.all(color: Colors.white, width: 1),
              ),
              alignment: Alignment.center,
              child: Transform.rotate(
                angle: math.pi / 4,
                child: Text(
                  '$place',
                  style: const TextStyle(
                    fontFamily: 'Urbanist',
                    fontWeight: FontWeight.w500,
                    fontSize: 14,
                    height: 17 / 14,
                    letterSpacing: -0.023,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ),
        ),
        if (crown)
          Positioned(
            top: -16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF23B2CA), width: 2),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.emoji_events_rounded, size: 14, color: Color(0xFF23B2CA)),
                  SizedBox(width: 4),
                  Text('1',
                      style: TextStyle(
                        fontFamily: 'Urbanist',
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                        color: Color(0xFF23B2CA),
                      )),
                ],
              ),
            ),
          ),
      ],
    );
  }
}

class _TrendGlyph extends StatelessWidget {
  final _Trend trend;
  final Color color;
  const _TrendGlyph({required this.trend, required this.color});

  @override
  Widget build(BuildContext context) {
    if (trend == _Trend.flat) {
      return Container(width: 10, height: 2, color: color);
    }
    return Transform.rotate(
      angle: trend == _Trend.down ? math.pi : 0,
      child: CustomPaint(size: const Size(10, 8), painter: _TrianglePainter(color)),
    );
  }
}

class _TrianglePainter extends CustomPainter {
  final Color color;
  _TrianglePainter(this.color);
  @override
  void paint(Canvas c, Size s) {
    final p = Paint()..color = color;
    final path = Path()
      ..moveTo(s.width / 2, 0)
      ..lineTo(0, s.height)
      ..lineTo(s.width, s.height)
      ..close();
    c.drawPath(path, p);
  }
  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}