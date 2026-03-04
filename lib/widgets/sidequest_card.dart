import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

enum SidequestType { own, friend, community }

class SidequestCard extends StatelessWidget {
  final String creatorName;
  final String creatorUsername;
  final String title;
  final DateTime eventDatetime;
  final DateTime? endDatetime;
  final String location;
  final SidequestType type;
  final VoidCallback? onTap;

  const SidequestCard({
    super.key,
    required this.creatorName,
    required this.creatorUsername,
    required this.title,
    required this.eventDatetime,
    this.endDatetime,
    required this.location,
    required this.type,
    this.onTap,
  });

  Color get _mainColor {
    switch (type) {
      case SidequestType.own:
        return const Color(0xFFFDE08B); // yellow
      case SidequestType.friend:
        return const Color(0xFFFDE4E1); // pink
      case SidequestType.community:
        return const Color(0xFFDDE9F7); // blue
    }
  }

  Color get _accentColor {
    switch (type) {
      case SidequestType.own:
        return const Color(0xFFFFB300); // dark yellow
      case SidequestType.friend:
        return const Color(0xFFE8837C); // dark pink
      case SidequestType.community:
        return const Color(0xFF64A8DB); // dark blue
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('MMMM d, yyyy').format(eventDatetime.toLocal());
    
    final startTimeStr = DateFormat('h:mm').format(eventDatetime.toLocal());
    final endT = endDatetime ?? eventDatetime.add(const Duration(hours: 1));
    final endTimeStr = DateFormat('h:mma').format(endT.toLocal()).toLowerCase();
    final timeRangeStr = '$startTimeStr - $endTimeStr';

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
        // Main sticky note body
        ClipPath(
          clipper: _StickyNoteClipper(),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 26),
            decoration: BoxDecoration(
              color: _mainColor,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header (Avatar + Name/Username)
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Hosted by $creatorName',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF2D2D2D),
                          ),
                        ),
                        Text(
                          '@$creatorUsername',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF5F5F5F),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Title
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    fontStyle: FontStyle.italic,
                    color: const Color(0xFF1E1E1E),
                    height: 1.2,
                  ),
                ),
                
                const SizedBox(height: 16),
                
                // Divider line
                Container(
                  height: 1,
                  color: const Color(0xFF2D2D2D).withOpacity(0.5),
                  margin: const EdgeInsets.only(bottom: 16),
                ),

                // Date & Time
                Row(
                  children: [
                    const Icon(Icons.calendar_today_outlined, size: 16, color: Color(0xFF5F5F5F)),
                    const SizedBox(width: 6),
                    Text(
                      dateStr,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF5F5F5F),
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Icon(Icons.access_time_outlined, size: 16, color: Color(0xFF5F5F5F)),
                    const SizedBox(width: 6),
                    Text(
                      timeRangeStr,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF5F5F5F),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Location
                Row(
                  children: [
                    const Icon(Icons.location_on_outlined, size: 16, color: Color(0xFF5F5F5F)),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        location.isNotEmpty ? location : 'Location TBD',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF5F5F5F),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),

        // Folded corner (top right)
        Positioned(
          top: 0,
          right: 0,
          child: CustomPaint(
            size: const Size(40, 40),
            painter: _FoldPainter(color: _accentColor),
          ),
        ),

        // Decorative star (bottom right)
        Positioned(
          bottom: 12,
          right: 12,
          child: Container(
            decoration: BoxDecoration(
               boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
               ],
               shape: BoxShape.circle,
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Image.asset(
                  'assets/images/asterik.png',
                  width: 50,
                  color: Colors.white,
                ),
                Image.asset(
                  'assets/images/asterik.png',
                  width: 44,
                  color: _accentColor,
                ),
              ],
            ),
          ),
        ),
      ],
    ),
  );
}
}

// ─── Clippers and Painters ──────────────────────────────────────────────────

class _StickyNoteClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    const foldSize = 40.0;
    
    path.lineTo(size.width - foldSize, 0); // Top edge to fold start
    path.lineTo(size.width, foldSize); // Diagonal down for fold
    path.lineTo(size.width, size.height); // Right edge down
    path.lineTo(0, size.height); // Bottom edge
    path.close(); // Back to top left

    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _FoldPainter extends CustomPainter {
  final Color color;
  _FoldPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, 0); // Top Left of the 40x40 box
    path.lineTo(0, size.height); // Bottom Left
    path.lineTo(size.width, size.height); // Bottom Right
    path.close(); // Cut diagonal

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ThickStarPainter extends CustomPainter {
  final Color fillColor;
  final Color borderColor;
  final double borderWidth;

  _ThickStarPainter({
    required this.fillColor,
    required this.borderColor,
    required this.borderWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    // For a thicker medical-cross style star like the hi-fi
    final innerRadius = radius * 0.45; 

    final path = Path();
    const int points = 4;
    
    // Add slightly rounded corners
    final fillPaint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill
      ..strokeJoin = StrokeJoin.round;
      
    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = borderWidth
      ..strokeJoin = StrokeJoin.round;

    for (int i = 0; i < points * 2; i++) {
      // Start from top, go clockwise
      final angle = (i * math.pi / points) - math.pi / 2;
      final r = i.isEven ? radius : innerRadius;
      final x = center.dx + r * math.cos(angle);
      final y = center.dy + r * math.sin(angle);

      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();

    canvas.drawPath(path, fillPaint);
    canvas.drawPath(path, borderPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
