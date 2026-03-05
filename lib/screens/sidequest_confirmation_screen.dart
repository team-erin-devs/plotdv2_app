import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

class SidequestConfirmationScreen extends StatefulWidget {
  final String title;
  final String? hostName;
  final bool isJoin;
  final Color accentColor;

  const SidequestConfirmationScreen({
    super.key,
    required this.title,
    this.hostName,
    required this.isJoin,
    required this.accentColor,
  });

  @override
  State<SidequestConfirmationScreen> createState() => _SidequestConfirmationScreenState();
}

class _SidequestConfirmationScreenState extends State<SidequestConfirmationScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<double> _fadeAnimation;
  late Animation<double> _delayedScaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _scaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.6, curve: Curves.elasticOut),
      ),
    );
    
    _delayedScaleAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.15, 0.75, curve: Curves.elasticOut),
      ),
    );

    _rotationAnimation = Tween<double>(begin: -0.2, end: 0.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.8, curve: Curves.easeOutBack),
      ),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.3, 1.0, curve: Curves.easeIn),
      ),
    );

    _controller.forward();
    
    // Auto-dismiss after providing time to read
    Future.delayed(const Duration(milliseconds: 3500), () {
      if (mounted) {
        Navigator.pop(context);
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final topText = widget.isJoin
        ? (widget.hostName != null && widget.hostName!.isNotEmpty
            ? "You've joined ${widget.hostName}'s"
            : "You've joined a")
        : "Your sidequest";
        
    final bottomText = widget.isJoin
        ? "successfully!!"
        : "has been posted successfully!!";

    return Theme(
      data: ThemeData.light().copyWith(
        scaffoldBackgroundColor: const Color(0xFFF9F9F9),
        textTheme: GoogleFonts.plusJakartaSansTextTheme(),
      ),
      child: Scaffold(
        body: GestureDetector(
          onTap: () => Navigator.pop(context),
          behavior: HitTestBehavior.opaque,
          child: Stack(
            children: [
              // Top Right Asterisk
              Positioned(
                top: -120,
                right: -100,
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _scaleAnimation.value,
                      child: Transform.rotate(
                        angle: _rotationAnimation.value * math.pi,
                        child: _buildAsterisk(size: 280),
                      ),
                    );
                  },
                ),
              ),

              // Bottom Left Asterisk
              Positioned(
                bottom: -150,
                left: -150,
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    return Transform.scale(
                      scale: _delayedScaleAnimation.value,
                      child: Transform.rotate(
                        angle: -_rotationAnimation.value * math.pi,
                        child: _buildAsterisk(size: 360),
                      ),
                    );
                  },
                ),
              ),

              // Center Content
              SafeArea(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32.0),
                  child: Center(
                    child: FadeTransition(
                      opacity: _fadeAnimation,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            topText,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 22,
                              fontWeight: FontWeight.w400,
                              color: const Color(0xFF757575),
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 20),
                          Text(
                            widget.title,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 34,
                              fontWeight: FontWeight.w800,
                              fontStyle: FontStyle.italic,
                              color: Colors.black,
                              height: 1.15,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 20),
                          Text(
                            bottomText,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 22,
                              fontWeight: FontWeight.w400,
                              color: const Color(0xFF757575),
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAsterisk({required double size}) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02), // Subtler shadow
            blurRadius: 2,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: SvgPicture.asset(
        'assets/images/asterik.svg',
        width: size,
        height: size,
        theme: SvgTheme(currentColor: widget.accentColor),
        fit: BoxFit.contain,
      ),
    );
  }
}
