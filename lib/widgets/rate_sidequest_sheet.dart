import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';

import '../screens/past_sidequest_screen.dart';
import 'bouncing_button.dart';

class RateSidequestSheet extends StatefulWidget {
  final int sidequestId;
  final String sidequestTitle;
  final String hostName;
  final bool isOwnQuest; // True if the user hosted it

  const RateSidequestSheet({
    super.key,
    required this.sidequestId,
    required this.sidequestTitle,
    required this.hostName,
    required this.isOwnQuest,
  });

  @override
  State<RateSidequestSheet> createState() => _RateSidequestSheetState();
}

class _RateSidequestSheetState extends State<RateSidequestSheet> with SingleTickerProviderStateMixin {
  int _selectedRating = 0;
  
  // XP Animation controllers
  late AnimationController _xpAnimController;
  late Animation<double> _xpFillAnimation;
  
  // 45 starting XP, adding 30 XP to reach 75 XP out of 100 for level 8
  final double _startFraction = 0.45;
  final double _endFraction = 0.75;
  
  @override
  void initState() {
    super.initState();
    _xpAnimController = AnimationController(
       vsync: this,
       duration: const Duration(milliseconds: 1500),
    );
    
    _xpFillAnimation = Tween<double>(begin: _startFraction, end: _startFraction).animate(
      CurvedAnimation(parent: _xpAnimController, curve: Curves.easeOutCubic)
    );
  }
  
  @override
  void dispose() {
    _xpAnimController.dispose();
    super.dispose();
  }

  void _handleRatingSelected(int rating) {
    if (_selectedRating == rating) return; 
    setState(() {
      _selectedRating = rating;
      
      // Animate the XP bar filling when rating is tapped!
      _xpFillAnimation = Tween<double>(begin: _startFraction, end: _endFraction).animate(
        CurvedAnimation(parent: _xpAnimController, curve: Curves.easeOutCubic)
      );
      _xpAnimController.forward(from: 0.0);
    });
  }

  void _navigateToPastQuest() {
    Navigator.pop(context); // Close the bottom sheet
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PastSidequestScreen(sidequestId: widget.sidequestId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hostDisplayName = widget.isOwnQuest ? 'your' : "${widget.hostName}'s";

    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFF8F4F0),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min, // Wrap to content
          children: [
            const SizedBox(height: 12),
            // Grab handle
            Container(
              width: 48,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2.5),
              ),
            ),
            
            const SizedBox(height: 40),
            
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text.rich(
                TextSpan(
                  text: 'How was ',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 22,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF1E1E1E),
                    height: 1.2,
                  ),
                  children: [
                    TextSpan(
                      text: hostDisplayName,
                      style: const TextStyle(fontWeight: FontWeight.w800, fontStyle: FontStyle.italic),
                    ),
                    const TextSpan(text: ' '),
                    TextSpan(
                      text: widget.sidequestTitle,
                      style: const TextStyle(fontWeight: FontWeight.w800, fontStyle: FontStyle.italic),
                    ),
                    const TextSpan(text: '?'),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
            ),
            
            const SizedBox(height: 8),
            
            Text(
              'log your plot!',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF888888),
              ),
            ),
            
            const SizedBox(height: 32),
            
            // Interactive SVG Stars
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(5, (index) {
                final starValue = index + 1;
                final isSelected = starValue <= _selectedRating;
                
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4.0),
                  child: BouncingButton(
                    onPressed: () => _handleRatingSelected(starValue),
                    scaleFactor: 0.8,
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      curve: Curves.easeOutCirc,
                      width: 48,
                      height: 48,
                      
                      // Using SvgPicture since the asterik.svg is hollow naturally with a white stroke.
                      child: isSelected 
                        ? SvgPicture.asset(
                            'assets/images/asterik.svg',
                            width: 48,
                            theme: const SvgTheme(currentColor: Color(0xFFFFB300)), // Yellow fill
                          )
                        : SvgPicture.asset(
                            'assets/images/asterik.svg',
                            width: 48,
                            theme: const SvgTheme(currentColor: Colors.transparent), // Transparent fill keeps the white outline, but mockup shows yellow outline
                            colorFilter: const ColorFilter.mode(Color(0xFFFFB300), BlendMode.srcATop), 
                          ),
                    ),
                  ),
                );
              }),
            ),
            
            const SizedBox(height: 40),
            
            // Actions
            Container(color: const Color(0xFFE8E0D8), height: 1), // Top separator
            
            _buildActionRow(
              icon: Icons.camera_alt_outlined,
              label: 'add photos',
              onTap: _navigateToPastQuest,
            ),
            
            Container(color: const Color(0xFFE8E0D8), height: 1), // Middle separator
            
            _buildActionRow(
              icon: Icons.local_offer_outlined,
              label: 'tag friends',
              onTap: _navigateToPastQuest,
            ),
            
            Container(color: const Color(0xFFE8E0D8), height: 1), // Bottom separator
            
            const SizedBox(height: 32),
            
            // Animated XP Bar Footer
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Row(
                children: [
                  // XP Badge
                  Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFFB300),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      'XP',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF1E1E1E),
                      ),
                    ),
                  ),
                  
                  const SizedBox(width: 12),
                  
                  // Progress Bar
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Container(
                          height: 14,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE5E5E5), // Light gray track
                            borderRadius: BorderRadius.circular(7),
                          ),
                          child: Stack(
                            children: [
                              AnimatedBuilder(
                                animation: _xpFillAnimation,
                                builder: (context, child) {
                                  return FractionallySizedBox(
                                    alignment: Alignment.centerLeft,
                                    widthFactor: _xpFillAnimation.value,
                                    child: Container(
                                      decoration: BoxDecoration(
                                        color: const Color(0xFFFFB300), // Yellow fill
                                        borderRadius: BorderRadius.circular(7),
                                      ),
                                    ),
                                  );
                                }
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 6),
                        // Subtitle texts
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            AnimatedBuilder(
                              animation: _xpFillAnimation,
                              builder: (context, _) {
                                // Fade in the +30 when animation starts
                                final val = _xpAnimController.value;
                                return Opacity(
                                  opacity: val > 0 ? Curves.easeIn.transform(val) : 0.0,
                                  child: Text(
                                    '+30 XP',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF1E1E1E),
                                    ),
                                  ),
                                );
                              }
                            ),
                            Text(
                              '45/70', // Static for mockup
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF888888),
                              ),
                            ),
                          ],
                        )
                      ],
                    ),
                  ),
                  
                  const SizedBox(width: 12),
                  
                  // Level Badge
                  Container(
                    width: 32,
                    height: 32,
                    decoration: const BoxDecoration(
                      color: Color(0xFFFFB300),
                      shape: BoxShape.circle,
                    ),
                    alignment: Alignment.center,
                    child: Text(
                      '8',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF1E1E1E),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildActionRow({required IconData icon, required String label, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Row(
          children: [
            Icon(icon, size: 24, color: const Color(0xFF1E1E1E)),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1E1E1E),
                ),
              ),
            ),
            const Icon(Icons.arrow_forward_ios, size: 16, color: Color(0xFF888888)),
          ],
        ),
      ),
    );
  }
}
