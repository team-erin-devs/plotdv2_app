import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'dart:convert';

class ViewIDCard extends StatefulWidget {
  final String username;
  final String handle;
  final String? profilePictureUrl;
  
  const ViewIDCard({
    super.key,
    required this.username,
    required this.handle,
    this.profilePictureUrl,
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
      _dragOffset += details.delta * 0.5; // Reduce sensitivity
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
    // Convert username to base64
    final base64Username = base64Encode(utf8.encode(widget.username));
    return 'https://plotd.com/join/referral-$base64Username';
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    
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
              maxWidth: 400,
              maxHeight: 600,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF1a1a2e),
                  Color(0xFF16213e),
                  Color(0xFF0f3460),
                ],
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.5),
                  blurRadius: 30,
                  spreadRadius: 5,
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: Stack(
                children: [
                  // Animated shine effect
                  Positioned.fill(
                    child: CustomPaint(
                      painter: ShinePainter(offset: _dragOffset),
                    ),
                  ),
                  
                  // Content
                  SafeArea(
                    child: SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // Back button
                            Align(
                              alignment: Alignment.topRight,
                              child: IconButton(
                                icon: const Icon(Icons.close, color: Colors.white, size: 24),
                                onPressed: () => Navigator.pop(context),
                              ),
                            ),
                            
                            const SizedBox(height: 10),
                            
                            // Profile picture placeholder
                            Container(
                              width: 100,
                              height: 100,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 3),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.purple.withOpacity(0.5),
                                    blurRadius: 20,
                                    spreadRadius: 5,
                                  ),
                                ],
                              ),
                              child: CircleAvatar(
                                radius: 50,
                                backgroundColor: Colors.grey[800],
                                backgroundImage: widget.profilePictureUrl != null && widget.profilePictureUrl!.isNotEmpty
                                    ? (widget.profilePictureUrl!.startsWith('images/') || widget.profilePictureUrl!.startsWith('assets/images/')
                                        ? AssetImage(widget.profilePictureUrl!.startsWith('images/') ? 'assets/${widget.profilePictureUrl}' : widget.profilePictureUrl!)
                                        : NetworkImage(widget.profilePictureUrl!)) as ImageProvider
                                    : null,
                                child: widget.profilePictureUrl == null || widget.profilePictureUrl!.isEmpty
                                    ? Icon(
                                        Icons.person,
                                        size: 50,
                                        color: Colors.grey[400],
                                      )
                                    : null,
                              ),
                            ),
                            
                            const SizedBox(height: 20),
                            
                            // Name
                            Text(
                              widget.username,
                              style: GoogleFonts.epilogue(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.2,
                              ),
                            ),
                            
                            const SizedBox(height: 30),
                            
                            // QR Code
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(16),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withOpacity(0.3),
                                    blurRadius: 15,
                                    spreadRadius: 3,
                                  ),
                                ],
                              ),
                              child: QrImageView(
                                data: _generateQRData(),
                                version: QrVersions.auto,
                                size: 200,
                                backgroundColor: Colors.white,
                                errorCorrectionLevel: QrErrorCorrectLevel.M,
                              ),
                            ),
                            
                            const SizedBox(height: 20),
                            
                            // URL text
                            Text(
                              'plotd.com/join',
                              style: GoogleFonts.urbanist(
                                color: Colors.grey[300],
                                fontSize: 14,
                                letterSpacing: 0.5,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 20),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class ShinePainter extends CustomPainter {
  final Offset offset;
  
  ShinePainter({required this.offset});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = LinearGradient(
        begin: Alignment(-1.0 + offset.dx * 0.01, -1.0 + offset.dy * 0.01),
        end: Alignment(1.0 + offset.dx * 0.01, 1.0 + offset.dy * 0.01),
        colors: [
          Colors.white.withOpacity(0.0),
          Colors.white.withOpacity(0.05),
          Colors.purple.withOpacity(0.15),
          Colors.blue.withOpacity(0.1),
          Colors.white.withOpacity(0.0),
        ],
        stops: const [0.0, 0.3, 0.5, 0.7, 1.0],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
  }

  @override
  bool shouldRepaint(ShinePainter oldDelegate) => offset != oldDelegate.offset;
}
