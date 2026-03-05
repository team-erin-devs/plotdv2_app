import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/api_service.dart';
import '../models/leaderboard_entry.dart';

class RankingScreen extends StatefulWidget {
  const RankingScreen({super.key});

  @override
  State<RankingScreen> createState() => _RankingScreenState();
}

class _RankingScreenState extends State<RankingScreen> {
  late Future<List<LeaderboardEntry>> _leaderboardFuture;
  bool _isIndividual = true; // Toggle between Individual and Faculty

  @override
  void initState() {
    super.initState();
    _leaderboardFuture = ApiService.fetchLeaderboard();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.only(top: 24, bottom: 20),
              child: Center(
                child: Text(
                  'Rankings',
                  style: GoogleFonts.epilogue(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),

            // Individual/Faculty Toggle
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(25),
                ),
                padding: const EdgeInsets.all(4),
                child: Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _isIndividual = true;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: _isIndividual ? Colors.black : Colors.transparent,
                            borderRadius: BorderRadius.circular(25),
                          ),
                          child: Center(
                            child: Text(
                              'Individual',
                              style: GoogleFonts.urbanist(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: _isIndividual ? Colors.white : Colors.grey[500],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    Expanded(
                      child: GestureDetector(
                        onTap: () {
                          setState(() {
                            _isIndividual = false;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: !_isIndividual ? Colors.black : Colors.transparent,
                            borderRadius: BorderRadius.circular(25),
                          ),
                          child: Center(
                            child: Text(
                              'Faculty',
                              style: GoogleFonts.urbanist(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: !_isIndividual ? Colors.white : Colors.grey[500],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 20),

            // Leaderboard Content
            Expanded(
              child: FutureBuilder<List<LeaderboardEntry>>(
                future: _leaderboardFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Color(0xFF4FC3F7),
                      ),
                    );
                  }

                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Failed to load rankings',
                        style: GoogleFonts.urbanist(
                          color: Colors.grey[400],
                          fontSize: 16,
                        ),
                      ),
                    );
                  }

                  final entries = snapshot.data ?? [];

                  if (entries.isEmpty) {
                    return Center(
                      child: Text(
                        'No rankings available yet',
                        style: GoogleFonts.urbanist(
                          color: Colors.grey[400],
                          fontSize: 16,
                        ),
                      ),
                    );
                  }

                  // Split into top 3 and rest
                  final top3 = entries.take(3).toList();
                  final rest = entries.skip(3).toList();

                  return RefreshIndicator(
                    color: const Color(0xFF4FC3F7),
                    backgroundColor: Colors.black,
                    onRefresh: () async {
                      setState(() {
                        _leaderboardFuture = ApiService.fetchLeaderboard();
                      });
                    },
                    child: ListView(
                      padding: EdgeInsets.zero,
                      children: [
                        // Top 3 Podium
                        if (top3.isNotEmpty) _buildTopThree(top3),
                        const SizedBox(height: 30),

                        // Rest of rankings
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 20),
                          child: Container(
                            decoration: BoxDecoration(
                              color: Colors.black,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: Colors.grey[900]!,
                                width: 1,
                              ),
                            ),
                            child: Column(
                              children: [
                                ...rest.asMap().entries.map((entry) {
                                  final index = entry.key;
                                  final data = entry.value;
                                  return Column(
                                    children: [
                                      _buildRankingRow(data, index == rest.length - 1),
                                      if (index < rest.length - 1)
                                        Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 20),
                                          child: Divider(
                                            height: 1,
                                            thickness: 1,
                                            color: Colors.grey[900],
                                          ),
                                        ),
                                    ],
                                  );
                                }).toList(),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 100),
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopThree(List<LeaderboardEntry> top3) {
    // Get the three entries (2nd, 1st, 3rd for display order)
    LeaderboardEntry? first = top3.length > 0 ? top3[0] : null;
    LeaderboardEntry? second = top3.length > 1 ? top3[1] : null;
    LeaderboardEntry? third = top3.length > 2 ? top3[2] : null;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // 2nd place (left)
          if (second != null)
            Expanded(
              child: _buildPodiumCard(
                second,
                2,
                const Color(0xFF9C27B0), // Purple
                220,
              ),
            ),
          const SizedBox(width: 12),
          
          // 1st place (center, tallest)
          if (first != null)
            Expanded(
              child: _buildPodiumCard(
                first,
                1,
                const Color(0xFF00BCD4), // Cyan
                270,
              ),
            ),
          const SizedBox(width: 12),
          
          // 3rd place (right)
          if (third != null)
            Expanded(
              child: _buildPodiumCard(
                third,
                3,
                const Color(0xFFE91E63), // Pink
                200,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildPodiumCard(
      LeaderboardEntry entry, int position, Color borderColor, double height) {
    // Get gender icon
    IconData genderIcon = Icons.minimize;
    Color genderColor = Colors.grey;
    
    // You can customize this based on actual gender data if available
    if (position == 1) {
      genderIcon = Icons.arrow_drop_up;
      genderColor = const Color(0xFF4FC3F7);
    } else if (position == 2) {
      genderIcon = Icons.minimize;
      genderColor = const Color(0xFF9C27B0);
    } else if (position == 3) {
      genderIcon = Icons.arrow_drop_down;
      genderColor = const Color(0xFFE91E63);
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Crown for 1st place
        if (position == 1)
          Container(
            margin: const EdgeInsets.only(bottom: 8),
            child: const Icon(
              Icons.emoji_events,
              color: Color(0xFF00BCD4),
              size: 28,
            ),
          ),
        
        // Avatar with position badge
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: borderColor,
                  width: 3,
                ),
              ),
              child: CircleAvatar(
                radius: position == 1 ? 45 : 40,
                backgroundColor: Colors.grey[850],
                backgroundImage: const NetworkImage(
                  'https://images.unsplash.com/photo-1522075469751-3a6694fb2f61?w=100&h=100&fit=crop',
                ),
              ),
            ),
            // Position badge
            Positioned(
              bottom: -5,
              right: -5,
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: borderColor,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.black,
                    width: 2,
                  ),
                ),
                child: Center(
                  child: Text(
                    position.toString(),
                    style: GoogleFonts.urbanist(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 12),
        
        // Card container
        Container(
          height: height,
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.grey[900]!,
              width: 1,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Name with gender icon
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                      child: Text(
                        entry.username,
                        style: GoogleFonts.urbanist(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  Icon(
                    genderIcon,
                    color: genderColor,
                    size: 20,
                  ),
                ],
              ),
              const SizedBox(height: 4),
              
              // Handle
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: Text(
                  '@${entry.username.toLowerCase()}',
                  style: GoogleFonts.urbanist(
                    fontSize: 12,
                    color: Colors.grey[500],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 16),
              
              // Points
              Text(
                entry.totalPoints.toString(),
                style: GoogleFonts.urbanist(
                  fontSize: position == 1 ? 40 : 36,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRankingRow(LeaderboardEntry entry, bool isLast) {
    // Highlight the 6th position (index 2 in the rest list) with white border
    final bool isHighlighted = entry.rank == 6;
    
    return Container(
      decoration: BoxDecoration(
        border: isHighlighted 
          ? Border.all(color: Colors.white, width: 2)
          : null,
        borderRadius: isHighlighted 
          ? BorderRadius.circular(24)
          : (isLast ? const BorderRadius.vertical(bottom: Radius.circular(24)) : null),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            // Rank number
            SizedBox(
              width: 30,
              child: Text(
                entry.rank.toString(),
                style: GoogleFonts.urbanist(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            const SizedBox(width: 16),
            
            // Avatar
            CircleAvatar(
              radius: 24,
              backgroundColor: Colors.grey[850],
              backgroundImage: const NetworkImage(
                'https://images.unsplash.com/photo-1522075469751-3a6694fb2f61?w=100&h=100&fit=crop',
              ),
            ),
            const SizedBox(width: 16),
            
            // Name and handle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    entry.username,
                    style: GoogleFonts.urbanist(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '@${entry.username.toLowerCase()}',
                    style: GoogleFonts.urbanist(
                      fontSize: 13,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
            
            // Gender icon
            Icon(
              Icons.arrow_drop_up,
              color: const Color(0xFF4FC3F7),
              size: 24,
            ),
            const SizedBox(width: 8),
            
            // Points
            Text(
              entry.totalPoints.toString(),
              style: GoogleFonts.urbanist(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
