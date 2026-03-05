import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:convert';

class ViewIDCard extends StatefulWidget {
  final String displayName;
  final String username;
  final String? profilePictureUrl;
  final int sidequestsCompleted;
  final int sidequestsHosted;
  
  const ViewIDCard({
    super.key,
    required this.displayName,
    required this.username,
    this.profilePictureUrl,
    required this.sidequestsCompleted,
    required this.sidequestsHosted,
  });

  @override
  State<ViewIDCard> createState() => _ViewIDCardState();
}

class _ViewIDCardState extends State<ViewIDCard> with SingleTickerProviderStateMixin {
  Offset _dragOffset = Offset.zero;
  late AnimationController _animationController;
  Animation<Offset>? _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    
    _animationController.addListener(() {
      if (_animation != null) {
        setState(() {
          _dragOffset = _animation!.value;
        });
      }
    });
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onPanUpdate(DragUpdateDetails details) {
    setState(() {
      _dragOffset += details.delta * 0.5;
      _dragOffset = Offset(
        _dragOffset.dx.clamp(-40.0, 40.0),
        _dragOffset.dy.clamp(-40.0, 40.0),
      );
    });
  }

  void _onPanEnd(DragEndDetails details) {
    _animation = Tween<Offset>(
      begin: _dragOffset,
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.elasticOut,
    ));
    _animationController.forward(from: 0);
  }

  String _generateQRData() {
    final base64Username = base64Encode(utf8.encode(widget.username));
    return 'https://plotd.com/join/referral-$base64Username';
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: GestureDetector(
        onPanUpdate: _onPanUpdate,
        onPanEnd: _onPanEnd,
        child: Transform(
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.002) // Perspective
            ..rotateY(_dragOffset.dx * 0.008)
            ..rotateX(-_dragOffset.dy * 0.008),
          alignment: Alignment.center,
          child: Container(
            constraints: const BoxConstraints(
              maxWidth: 340,
              maxHeight: 520,
            ),
            // The 4px gradient border is achieved by wrapping the main white card
            // in a slightly larger container with a gradient background
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFFFFB300), // Yellow
                  Color(0xFFE8837C), // Pink/Red
                  Color(0xFF64A8DB), // Blue
                  Color(0xFFFFB300), // Yellow
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 20,
                  spreadRadius: 2,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            // Inner white card
            child: Container(
              margin: const EdgeInsets.all(4), // Thickness of the gradient border
              decoration: BoxDecoration(
                color: const Color(0xFFF8F4F0), // Off-white matched to app bg
                borderRadius: BorderRadius.circular(4),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: Stack(
                  children: [
                    // Close button overlay
                    Positioned(
                      top: 4,
                      right: 4,
                      child: IconButton(
                        icon: const Icon(Icons.close, color: Colors.black54, size: 22),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ),
                    SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            const SizedBox(height: 12),
                            // Profile picture with asterisk
                            Stack(
                              clipBehavior: Clip.none,
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.white, width: 3),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withValues(alpha: 0.1),
                                        blurRadius: 10,
                                        spreadRadius: 2,
                                      ),
                                    ],
                                  ),
                                  child: CircleAvatar(
                                    radius: 46,
                                    backgroundColor: const Color(0xFFE0E0E0),
                                    backgroundImage: widget.profilePictureUrl != null && widget.profilePictureUrl!.isNotEmpty
                                        ? (widget.profilePictureUrl!.startsWith('images/') || widget.profilePictureUrl!.startsWith('assets/images/')
                                            ? AssetImage(widget.profilePictureUrl!.startsWith('images/') ? 'assets/${widget.profilePictureUrl}' : widget.profilePictureUrl!)
                                            : NetworkImage(widget.profilePictureUrl!)) as ImageProvider
                                        : null,
                                    child: widget.profilePictureUrl == null || widget.profilePictureUrl!.isEmpty
                                        ? const Icon(Icons.person, size: 46, color: Colors.white)
                                        : null,
                                  ),
                                ),
                                // Golden asterisk overlapping
                                Positioned(
                                  bottom: -10,
                                  left: -20,
                                  child: SvgPicture.asset(
                                    'assets/images/asterik.svg',
                                    width: 52,
                                    theme: const SvgTheme(currentColor: Color(0xFFFFB300)),
                                  ),
                                ),
                              ],
                            ),
                            
                            const SizedBox(height: 16),
                            
                            // Names
                            Text(
                              widget.displayName,
                              style: GoogleFonts.plusJakartaSans(
                                color: const Color(0xFF1E1E1E),
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            Text(
                              '@${widget.username}',
                              style: GoogleFonts.plusJakartaSans(
                                color: const Color(0xFF5F5F5F),
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            
                            const SizedBox(height: 24),
                            
                            // Stats Notes Row
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: _buildStatStickyNote(
                                    label: 'Sidequests\ncompleted',
                                    value: widget.sidequestsCompleted.toString(),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildStatStickyNote(
                                    label: 'Sidequests\nhosted',
                                    value: widget.sidequestsHosted.toString(),
                                  ),
                                ),
                              ],
                            ),
                            
                            const SizedBox(height: 24),
                            
                            // QR Code
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: const Color(0xFFFFB300), width: 1),
                              ),
                              child: QrImageView(
                                data: _generateQRData(),
                                version: QrVersions.auto,
                                size: 100,
                                backgroundColor: Colors.white,
                                errorCorrectionLevel: QrErrorCorrectLevel.M,
                              ),
                            ),
                            
                            const Spacer(),
                            
                            // Bottom join text
                            Text.rich(
                              TextSpan(
                                text: 'Join ',
                                style: GoogleFonts.plusJakartaSans(
                                  color: const Color(0xFF1E1E1E),
                                  fontSize: 14,
                                  fontWeight: FontWeight.w400,
                                ),
                                children: [
                                  TextSpan(
                                    text: widget.displayName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w800,
                                      fontStyle: FontStyle.italic,
                                    ),
                                  ),
                                  const TextSpan(text: ' on Plotd!'),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatStickyNote({required String label, required String value}) {
    return Stack(
      children: [
        ClipPath(
          clipper: _NoteClipper(),
          child: Container(
            height: 90,
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(10, 14, 10, 10),
            decoration: const BoxDecoration(
              color: Color(0xFFFFF3D4), // Light yellow
            ),
            child: Column(
              children: [
                Text(
                  label,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: const Color(0xFF888888),
                    fontWeight: FontWeight.w500,
                    height: 1.1,
                  ),
                ),
                const Spacer(),
                Text(
                  value,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1E1E1E),
                  ),
                ),
              ],
            ),
          ),
        ),
        Positioned(
          top: 0,
          right: 0,
          child: CustomPaint(
            size: const Size(18, 18),
            painter: _FoldPainter(),
          ),
        ),
      ],
    );
  }
}

class _NoteClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    var path = Path();
    path.lineTo(size.width - 18, 0); // leave room for corner fold
    path.lineTo(size.width, 18);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _FoldPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0xFFFFB300) // Deep yellow fold
      ..style = PaintingStyle.fill;
      
    final path = Path();
    path.moveTo(0, 0);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
