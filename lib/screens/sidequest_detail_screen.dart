import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../services/authenticated_api_service.dart';


// Data Model matching detailed view requirements
class SidequestDetail {
  final int id;
  final String title;
  final String description;
  final String creatorUsername;
  final String creatorFirstName;
  final String vibe;
  final String status;
  final DateTime eventDatetime;
  final DateTime? endDatetime;
  final String location;
  final int maxPeople;
  final int participantCount;
  final bool isFull;
  final bool postToCampusBoard;
  final String? userStatus; // 'creator', 'going', 'declined', null

  SidequestDetail({
    required this.id,
    required this.title,
    required this.description,
    required this.creatorUsername,
    required this.creatorFirstName,
    required this.vibe,
    required this.status,
    required this.eventDatetime,
    this.endDatetime,
    required this.location,
    required this.maxPeople,
    required this.participantCount,
    required this.isFull,
    required this.postToCampusBoard,
    this.userStatus,
  });

  factory SidequestDetail.fromJson(Map<String, dynamic> json) {
    return SidequestDetail(
      id: json['id'],
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      creatorUsername: json['creator']?['username'] ?? 'unknown',
      creatorFirstName: json['creator']?['first_name']?.isNotEmpty == true
          ? json['creator']['first_name']
          : (json['creator']?['username'] ?? 'friend'),
      vibe: json['vibe'] ?? 'chill',
      status: json['status'] ?? 'upcoming',
      eventDatetime: DateTime.parse(json['event_datetime']),
      endDatetime: json['end_datetime'] != null ? DateTime.parse(json['end_datetime']) : null,
      location: json['location'] ?? 'Location TBD',
      maxPeople: json['max_people'] ?? 5,
      participantCount: json['participant_count'] ?? 0,
      isFull: json['is_full'] ?? false,
      postToCampusBoard: json['post_to_campus_board'] ?? false,
      userStatus: json['user_status'],
    );
  }

  bool get isOwn => userStatus == 'creator';
  bool get isFriendsOnly => !postToCampusBoard && !isOwn;
  bool get isPublic => postToCampusBoard && !isOwn;
  bool get isGoing => userStatus == 'going';
}

class SidequestDetailScreen extends StatefulWidget {
  final int sidequestId;

  const SidequestDetailScreen({
    super.key,
    required this.sidequestId,
  });

  @override
  State<SidequestDetailScreen> createState() => _SidequestDetailScreenState();
}

class _SidequestDetailScreenState extends State<SidequestDetailScreen> {
  bool _isLoading = true;
  String? _error;
  SidequestDetail? _sq;

  @override
  void initState() {
    super.initState();
    _fetchDetails();
  }

  Future<void> _fetchDetails() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await AuthenticatedApiService.authenticatedGet(
        '/api/sidequests/${widget.sidequestId}/',
      );
      
      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        setState(() {
          _sq = SidequestDetail.fromJson(decoded);
          _isLoading = false;
        });
      } else {
        setState(() {
          _error = 'Failed to load sidequest. Status: ${response.statusCode}';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _joinOrLeave() async {
    if (_sq == null) return;
    final isGoing = _sq!.isGoing;
    final endpoint = isGoing
        ? '/api/sidequests/${_sq!.id}/leave/'
        : '/api/sidequests/${_sq!.id}/join/';

    try {
      final response = await AuthenticatedApiService.authenticatedPost(endpoint, {});
      if (response.statusCode == 200) {
        _fetchDetails(); // Reload data
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(isGoing ? 'You left the sidequest.' : 'You joined the plot! 🎉',
                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
              backgroundColor: const Color(0xFF455A64),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      } else {
        final body = jsonDecode(response.body);
        throw Exception(body['detail'] ?? 'Failed to update status');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$e', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600)),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  Color get _mainColor {
    if (_sq!.isOwn) return const Color(0xFFFDE08B);
    if (_sq!.isFriendsOnly) return const Color(0xFFFDE4E1);
    return const Color(0xFFDDE9F7);
  }

  Color get _accentColor {
    if (_sq!.isOwn) return const Color(0xFFFFB300);
    if (_sq!.isFriendsOnly) return const Color(0xFFE8837C);
    return const Color(0xFF64A8DB);
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData.light().copyWith(
        scaffoldBackgroundColor: const Color(0xFFF8F4F0),
      ),
      child: Scaffold(
        body: SafeArea(
          child: Column(
            children: [
              // ── AppBar ──
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  children: [
                    IconButton(
                      icon: const Icon(Icons.arrow_back, color: Colors.black, size: 28),
                      onPressed: () => Navigator.pop(context),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    Expanded(
                      child: Text.rich(
                        TextSpan(children: [
                          TextSpan(
                            text: 'Plot',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF1E1E1E),
                            ),
                          ),
                          TextSpan(
                            text: 'd',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 28,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF1E1E1E),
                            ),
                          ),
                          WidgetSpan(
                            alignment: PlaceholderAlignment.top,
                            child: Image.asset(
                              'assets/images/asterik.png',
                              width: 20,
                              color: const Color(0xFF1E1E1E),
                            ),
                          ),
                        ]),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(width: 28), // balance the back button
                  ],
                ),
              ),

              // ── Content ──
              Expanded(
                child: _isLoading
                    ? const Center(child: CircularProgressIndicator(color: Color(0xFFE8837C)))
                    : _error != null
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text('Failed to load details',
                                    style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w700)),
                                const SizedBox(height: 8),
                                TextButton(
                                  onPressed: _fetchDetails,
                                  child: Text('Retry',
                                      style: GoogleFonts.plusJakartaSans(color: const Color(0xFFE8837C))),
                                ),
                              ],
                            ),
                          )
                        : _buildDetailCard(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailCard() {
    final dateStr = DateFormat('MMMM d, yyyy').format(_sq!.eventDatetime.toLocal());
    final startTimeStr = DateFormat('h:mm').format(_sq!.eventDatetime.toLocal());
    final endDateTime = _sq!.endDatetime ?? _sq!.eventDatetime.add(const Duration(hours: 1));
    final endTimeStr = DateFormat('h:mma').format(endDateTime.toLocal()).toLowerCase();
    final timeRangeStr = '$startTimeStr - $endTimeStr';
    
    // Is the user joined or creator? Show star + fold
    final bool isJoined = _sq!.isGoing || _sq!.isOwn;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // Main sticky note body
          Container(
             width: double.infinity,
             // Minimum height to look like a large paper sheet if content is short
             constraints: BoxConstraints(minHeight: MediaQuery.of(context).size.height * 0.7),
             decoration: BoxDecoration(
                color: _mainColor,
             ),
             child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   // The top fold cut out (using ClipPath or just drawing over it)
                   // Actually, standard Container is fine, we'll draw the FoldPainter over the top right.
                   // The original SidequestCard uses a ClipPath for the fold. We'll do the same here to be exact.
                ],
             ),
          ),
          
          // Actually, let's wrap the content in ClipPath
          Positioned.fill(
             child: ClipPath(
                clipper: FoldClipper(),
                child: Container(
                   color: _mainColor,
                ),
             )
          ),

          // And now the actual content padding
          Padding(
             padding: const EdgeInsets.only(left: 20, right: 20, top: 32, bottom: 32),
             child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   // Header
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
                                  'Hosted by ${_sq!.creatorFirstName}',
                                  style: GoogleFonts.plusJakartaSans(
                                     fontSize: 16,
                                     fontWeight: FontWeight.w800,
                                     color: const Color(0xFF1E1E1E),
                                  ),
                               ),
                               Text(
                                  '@${_sq!.creatorUsername}',
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
                   const SizedBox(height: 24),

                   // Title
                   Text(
                      _sq!.title,
                      style: GoogleFonts.plusJakartaSans(
                         fontSize: 24,
                         fontWeight: FontWeight.w800,
                         fontStyle: FontStyle.italic,
                         color: const Color(0xFF1E1E1E),
                         height: 1.2,
                      ),
                   ),
                   const SizedBox(height: 20),

                   // Divider line
                   Container(
                      height: 1,
                      color: const Color(0xFF1E1E1E).withValues(alpha: 0.15),
                      margin: const EdgeInsets.only(bottom: 20),
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
                   const SizedBox(height: 10),

                   // Location
                   Row(
                      children: [
                         const Icon(Icons.location_on_outlined, size: 16, color: Color(0xFF5F5F5F)),
                         const SizedBox(width: 6),
                         Expanded(
                            child: Text(
                               _sq!.location.isNotEmpty ? _sq!.location : 'Location TBD',
                               style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF5F5F5F),
                               ),
                            ),
                         ),
                      ],
                   ),
                   const SizedBox(height: 24),

                   // Description
                   Text(
                      _sq!.description,
                      style: GoogleFonts.plusJakartaSans(
                         fontSize: 16,
                         fontWeight: FontWeight.w500,
                         color: const Color(0xFF1E1E1E),
                         height: 1.4,
                      ),
                   ),
                   const SizedBox(height: 24),

                   // Tags
                   Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                         _buildTag(_sq!.vibe),
                         _buildTag(_sq!.isOwn ? 'yours' : _sq!.isFriendsOnly ? 'friends-only' : 'public'),
                      ],
                   ),

                   const SizedBox(height: 48),

                   // Star (if joined/creator)
                   if (isJoined)
                      Align(
                         alignment: Alignment.centerRight,
                         child: Container(
                            decoration: BoxDecoration(
                               boxShadow: [
                                  BoxShadow(
                                     color: Colors.black.withValues(alpha: 0.1),
                                     blurRadius: 4,
                                     offset: const Offset(0, 2),
                                  ),
                               ],
                               shape: BoxShape.circle,
                            ),
                            child: SizedBox(
                               width: 100,
                               height: 100,
                               child: CustomPaint(
                                  painter: ThickStarPainter(
                                     fillColor: _accentColor,
                                     borderColor: Colors.white,
                                     borderWidth: 4.0,
                                  ),
                               ),
                            ),
                         ),
                      )
                   else
                      const SizedBox(height: 100), // maintain vertical space

                   const SizedBox(height: 48),

                   // Bottom Action Area
                   Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                         // Participants Outline
                         Row(
                            children: List.generate(
                               math.min(_sq!.maxPeople, 4), // Show up to 4 circles
                               (i) => Align(
                                  widthFactor: i == 0 ? 1.0 : 0.64,
                                  child: Container(
                                     width: 28,
                                     height: 28,
                                     decoration: BoxDecoration(
                                        color: i < _sq!.participantCount ? Colors.white : Colors.transparent,
                                        shape: BoxShape.circle,
                                        border: Border.all(color: Colors.white, width: 1.5),
                                     ),
                                  ),
                               ),
                            ),
                         ),
                         Text(
                            '${_sq!.participantCount}/${_sq!.maxPeople} spots filled',
                            style: GoogleFonts.plusJakartaSans(
                               fontSize: 15,
                               fontWeight: FontWeight.w800,
                               color: const Color(0xFF1E1E1E),
                            ),
                         ),
                      ],
                   ),
                   const SizedBox(height: 16),

                   // Buttons
                   if (_sq!.isOwn) ...[
                      SizedBox(
                         width: double.infinity,
                         child: ElevatedButton(
                            onPressed: () => Navigator.pop(context),
                            style: ElevatedButton.styleFrom(
                               backgroundColor: _accentColor,
                               padding: const EdgeInsets.symmetric(vertical: 18),
                               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                               elevation: 0,
                            ),
                            child: Text(
                               'Close',
                               style: GoogleFonts.plusJakartaSans(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                               ),
                            ),
                         ),
                      ),
                   ] else if (_sq!.isGoing) ...[
                      SizedBox(
                         width: double.infinity,
                         child: ElevatedButton(
                            onPressed: () => Navigator.pop(context),
                            style: ElevatedButton.styleFrom(
                               backgroundColor: _accentColor,
                               padding: const EdgeInsets.symmetric(vertical: 18),
                               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                               elevation: 0,
                            ),
                            child: Text(
                               'Close',
                               style: GoogleFonts.plusJakartaSans(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                               ),
                            ),
                         ),
                      ),
                      const SizedBox(height: 16),
                      Center(
                         child: TextButton(
                            onPressed: _joinOrLeave,
                            child: Text(
                               'Leave The Sidequest',
                               style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF5F5F5F),
                               ),
                            ),
                         ),
                      ),
                   ] else ...[
                      SizedBox(
                         width: double.infinity,
                         child: ElevatedButton(
                            onPressed: _sq!.isFull ? null : _joinOrLeave,
                            style: ElevatedButton.styleFrom(
                               backgroundColor: _accentColor,
                               disabledBackgroundColor: _accentColor.withValues(alpha: 0.5),
                               padding: const EdgeInsets.symmetric(vertical: 18),
                               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                               elevation: 0,
                            ),
                            child: Text(
                               _sq!.isFull ? 'Sidequest is full' : 'Join The Plot!',
                               style: GoogleFonts.plusJakartaSans(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                               ),
                            ),
                         ),
                      ),
                   ]
                ],
             ),
          ),

          // Folded corner (top right) - Only if joined
          if (isJoined)
             Positioned(
                top: 0,
                right: 0,
                child: CustomPaint(
                   size: const Size(60, 60),
                   painter: FoldPainter(color: _accentColor),
                ),
             ),
        ],
      ),
    );
  }

  Widget _buildTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: _accentColor.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        text,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }
}

// ─── Clippers and Painters locally reproduced for sizing ──────────────────────

class FoldClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    const foldSize = 60.0;
    
    path.lineTo(size.width - foldSize, 0); 
    path.lineTo(size.width, foldSize); 
    path.lineTo(size.width, size.height); 
    path.lineTo(0, size.height); 
    path.close();

    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class FoldPainter extends CustomPainter {
  final Color color;
  FoldPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, 0); 
    path.lineTo(0, size.height); 
    path.lineTo(size.width, size.height); 
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class ThickStarPainter extends CustomPainter {
  final Color fillColor;
  final Color borderColor;
  final double borderWidth;

  ThickStarPainter({
    required this.fillColor,
    required this.borderColor,
    required this.borderWidth,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final innerRadius = radius * 0.45; 

    final path = Path();
    const int points = 4;
    
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
