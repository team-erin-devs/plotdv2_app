import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'dart:math' as math;
import '../services/authenticated_api_service.dart';

class PostSidequestScreen extends StatefulWidget {
  const PostSidequestScreen({super.key});

  @override
  State<PostSidequestScreen> createState() => _PostSidequestScreenState();
}

class _PostSidequestScreenState extends State<PostSidequestScreen> {
  final TextEditingController _titleController = TextEditingController();
  String selectedVibe = 'active';
  String selectedTime = '2:00 pm';
  String selectedDate = 'tomorrow';
  int numPeople = 3;
  bool postToBoard = false;
  bool _isPosting = false;

  final Map<String, int> _timeHourMap = {
    '9:00 am': 9, '10:00 am': 10, '11:00 am': 11, '12:00 pm': 12,
    '1:00 pm': 13, '2:00 pm': 14, '3:00 pm': 15, '4:00 pm': 16,
    '5:00 pm': 17, '6:00 pm': 18, '7:00 pm': 19, '8:00 pm': 20,
  };

  DateTime _resolveDateTime() {
    final now = DateTime.now();
    DateTime date;
    switch (selectedDate) {
      case 'today':
        date = now;
        break;
      case 'tomorrow':
        date = now.add(const Duration(days: 1));
        break;
      case 'this weekend':
        // Next Saturday
        int daysUntilSaturday = (DateTime.saturday - now.weekday) % 7;
        if (daysUntilSaturday == 0) daysUntilSaturday = 7;
        date = now.add(Duration(days: daysUntilSaturday));
        break;
      case 'next week':
        date = now.add(const Duration(days: 7));
        break;
      default:
        date = now.add(const Duration(days: 1));
    }

    final hour = _timeHourMap[selectedTime] ?? 14;
    return DateTime(date.year, date.month, date.day, hour, 0);
  }

  Future<void> _postSidequest() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('give your quest a name!',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600)),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    setState(() => _isPosting = true);

    try {
      final eventDatetime = _resolveDateTime();

      final response = await AuthenticatedApiService.authenticatedPost(
        '/api/sidequests/',
        {
          'title': title,
          'event_datetime': eventDatetime.toUtc().toIso8601String(),
          'vibe': selectedVibe,
          'max_people': numPeople,
          'post_to_campus_board': postToBoard,
        },
      );

      if (response.statusCode == 201) {
        if (mounted) {
          Navigator.pushNamed(context, '/sidequest-confirmation');
          // Reset form
          _titleController.clear();
          setState(() {
            selectedVibe = 'active';
            selectedTime = '2:00 pm';
            selectedDate = 'tomorrow';
            numPeople = 3;
            postToBoard = false;
          });
        }
      } else {
        final errorBody = jsonDecode(response.body);
        throw Exception(errorBody.toString());
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('something went wrong: $e',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600)),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isPosting = false);
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData.light().copyWith(
        scaffoldBackgroundColor: Colors.white,
        textTheme: GoogleFonts.plusJakartaSansTextTheme(),
      ),
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.close, color: Colors.black, size: 28),
            onPressed: () {
              Navigator.pop(context);
            },
          ),
          title: Text(
            'post a sidequest',
            style: GoogleFonts.plusJakartaSans(
              color: Colors.black,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
          centerTitle: true,
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Yellow Card ──
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFFFDE08B),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Stack(
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'what\'s the quest?',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(height: 1.5, color: Colors.black54),
                        const SizedBox(height: 12),
                        TextField(
                          controller: _titleController,
                          maxLines: 2,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF988A68),
                            height: 1.2,
                          ),
                          decoration: InputDecoration(
                            hintText: 'coffee run and study\nsession',
                            hintStyle: GoogleFonts.plusJakartaSans(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF988A68).withOpacity(0.4),
                              height: 1.2,
                            ),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                            isDense: true,
                          ),
                        ),
                        const SizedBox(height: 32),
                        Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'time',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFFB59D71),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: DropdownButtonHideUnderline(
                                      child: DropdownButton<String>(
                                        value: selectedTime,
                                        icon: const Icon(Icons.keyboard_arrow_down, color: Colors.black87),
                                        isExpanded: true,
                                        isDense: true,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.black,
                                        ),
                                        onChanged: (String? newValue) {
                                          if (newValue != null) {
                                            setState(() => selectedTime = newValue);
                                          }
                                        },
                                        items: _timeHourMap.keys
                                            .map<DropdownMenuItem<String>>((String value) {
                                          return DropdownMenuItem<String>(
                                            value: value,
                                            child: Text(value),
                                          );
                                        }).toList(),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'date',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFFB59D71),
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: DropdownButtonHideUnderline(
                                      child: DropdownButton<String>(
                                        value: selectedDate,
                                        icon: const Icon(Icons.keyboard_arrow_down, color: Colors.black87),
                                        isExpanded: true,
                                        isDense: true,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w800,
                                          color: Colors.black,
                                        ),
                                        onChanged: (String? newValue) {
                                          if (newValue != null) {
                                            setState(() => selectedDate = newValue);
                                          }
                                        },
                                        items: <String>['today', 'tomorrow', 'this weekend', 'next week']
                                            .map<DropdownMenuItem<String>>((String value) {
                                          return DropdownMenuItem<String>(
                                            value: value,
                                            child: Text(value),
                                          );
                                        }).toList(),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    // Decorative star/asterisk
                    Positioned(
                      right: -10,
                      top: 40,
                      child: _buildDecorativeStar(),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // ── Vibes ──
              Text(
                'what\'s the vibe?',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  _buildVibePill('chill', selectedVibe == 'chill'),
                  _buildVibePill('active', selectedVibe == 'active'),
                  _buildVibePill('social', selectedVibe == 'social'),
                  _buildVibePill('fun', selectedVibe == 'fun'),
                  _buildVibePill('productive', selectedVibe == 'productive'),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFAF5E6),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: const Icon(Icons.add, color: Colors.black, size: 20),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // ── Who's coming ──
              Text(
                'who\'s coming?',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'small group. good vibes.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFFC7A77D),
                ),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF9F5EC), Color(0xFFFEE18C)],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  ),
                  borderRadius: BorderRadius.circular(30),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    GestureDetector(
                      onTap: () {
                        if (numPeople > 1) setState(() => numPeople--);
                      },
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Color(0xFFFFB300),
                          shape: BoxShape.circle,
                        ),
                        padding: const EdgeInsets.all(8),
                        child: const Icon(Icons.remove, color: Colors.black, size: 24),
                      ),
                    ),
                    Column(
                      children: [
                        Text(
                          numPeople.toString(),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: Colors.black,
                          ),
                        ),
                        Text(
                          numPeople == 1 ? 'person' : 'people',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFFB59D71),
                          ),
                        ),
                      ],
                    ),
                    GestureDetector(
                      onTap: () => setState(() => numPeople++),
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Color(0xFFFFB300),
                          shape: BoxShape.circle,
                        ),
                        padding: const EdgeInsets.all(8),
                        child: const Icon(Icons.add, color: Colors.black, size: 24),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // ── Campus Board Toggle ──
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'post to campus board?',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Colors.black,
                    ),
                  ),
                  Switch(
                    value: postToBoard,
                    onChanged: (val) => setState(() => postToBoard = val),
                    activeColor: const Color(0xFFFFB300),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // ── Post Button ──
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isPosting ? null : _postSidequest,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFFB300),
                    disabledBackgroundColor: const Color(0xFFFFB300).withOpacity(0.5),
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(30),
                    ),
                    elevation: 0,
                  ),
                  child: _isPosting
                      ? const SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            color: Colors.black,
                            strokeWidth: 2.5,
                          ),
                        )
                      : Text(
                          'post sidequest',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Colors.black,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 16),

              // ── Bottom disclaimer ──
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Text(
                    'don\'t worry, you can always edit or cancel the\nquest before it starts',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: const Color(0xFFC7A77D),
                      height: 1.4,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVibePill(String text, bool isSelected) {
    return GestureDetector(
      onTap: () => setState(() => selectedVibe = text),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFFB300) : const Color(0xFFFAF5E6),
          borderRadius: BorderRadius.circular(24),
        ),
        child: Text(
          text,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: Colors.black,
          ),
        ),
      ),
    );
  }

  Widget _buildDecorativeStar() {
    return SizedBox(
      width: 100,
      height: 100,
      child: CustomPaint(
        painter: _StarPainter(),
      ),
    );
  }
}

class _StarPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Shadow/outline star (slightly offset, light gray)
    final shadowPaint = Paint()
      ..color = const Color(0xFFE0D8C8)
      ..style = PaintingStyle.fill;
    _drawStar(canvas, Offset(center.dx + 4, center.dy + 4), radius, shadowPaint);

    // Main gold star
    final mainPaint = Paint()
      ..color = const Color(0xFFFFB300)
      ..style = PaintingStyle.fill;
    _drawStar(canvas, center, radius, mainPaint);
  }

  void _drawStar(Canvas canvas, Offset center, double radius, Paint paint) {
    final path = Path();
    const int points = 4;
    final innerRadius = radius * 0.38;

    for (int i = 0; i < points * 2; i++) {
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
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
