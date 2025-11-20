import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/leaderboard_entry.dart';
import '../services/api_service.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  late Future<List<LeaderboardEntry>> _leaderboardFuture;

  @override
  void initState() {
    super.initState();
    _leaderboardFuture = ApiService.fetchLeaderboard();
  }

  void _refreshLeaderboard() {
    setState(() {
      _leaderboardFuture = ApiService.fetchLeaderboard();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: FutureBuilder<List<LeaderboardEntry>>(
          future: _leaderboardFuture,
          builder: (context, snapshot) {
            // Loading state
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(
                child: CircularProgressIndicator(color: Colors.white),
              );
            }

            // Error state
            if (snapshot.hasError) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      color: Colors.red,
                      size: 60,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Failed to load leaderboard',
                      style: GoogleFonts.urbanist(
                        color: Colors.white70,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton(
                      onPressed: _refreshLeaderboard,
                      child: const Text('Retry'),
                    ),
                  ],
                ),
              );
            }

            // Success state
            final leaderboard = snapshot.data ?? [];

            if (leaderboard.isEmpty) {
              return Center(
                child: Text(
                  'No leaderboard data available',
                  style: GoogleFonts.urbanist(
                    color: Colors.white70,
                    fontSize: 16,
                  ),
                ),
              );
            }

            // Separate top 3 and the rest
            final top3 = leaderboard.take(3).toList();
            final rest = leaderboard.skip(3).toList();

            return RefreshIndicator(
              onRefresh: () async {
                _refreshLeaderboard();
                await _leaderboardFuture;
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Column(
                    children: [
                      const SizedBox(height: 20),
                      // Title
                      Text(
                        'Rankings',
                        style: GoogleFonts.epilogue(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 32),
                      
                      // Top 3 Podium
                      if (top3.isNotEmpty) _buildPodium(top3),
                      
                      const SizedBox(height: 24),
                      
                      // Rest of the leaderboard
                      ...rest.map((entry) => _buildLeaderboardRow(entry)),
                      
                      const SizedBox(height: 80), // Bottom padding for nav bar
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildPodium(List<LeaderboardEntry> top3) {
    // Ensure we have the right order: 2nd, 1st, 3rd
    LeaderboardEntry? first = top3.length > 0 ? top3[0] : null;
    LeaderboardEntry? second = top3.length > 1 ? top3[1] : null;
    LeaderboardEntry? third = top3.length > 2 ? top3[2] : null;

    return SizedBox(
      height: 300,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          // 2nd place (left)
          if (second != null)
            Expanded(child: _buildPodiumCard(second, 2, Colors.purple, 130)),
          const SizedBox(width: 8),
          // 1st place (center, tallest)
          if (first != null)
            Expanded(child: _buildPodiumCard(first, 1, Colors.cyan, 170)),
          const SizedBox(width: 8),
          // 3rd place (right)
          if (third != null)
            Expanded(child: _buildPodiumCard(third, 3, Colors.pink, 130)),
        ],
      ),
    );
  }

  Widget _buildPodiumCard(
      LeaderboardEntry entry, int position, Color accentColor, double height) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Crown for 1st place
        if (position == 1)
          const Icon(
            Icons.emoji_events,
            color: Color(0xFF4FC3F7),
            size: 28,
          ),
        if (position == 1) const SizedBox(height: 4),
        
        // Avatar with badge
        Stack(
          clipBehavior: Clip.none,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: accentColor,
                  width: 3,
                ),
                color: Colors.grey[800],
              ),
              child: const Icon(
                Icons.person,
                color: Colors.white54,
                size: 35,
              ),
            ),
            Positioned(
              bottom: -5,
              right: -5,
              child: Container(
                width: 26,
                height: 26,
                decoration: BoxDecoration(
                  color: accentColor,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.black, width: 2),
                ),
                child: Center(
                  child: Text(
                    '$position',
                    style: GoogleFonts.epilogue(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        
        // Card container
        Container(
          height: height,
          decoration: BoxDecoration(
            color: const Color(0xFF1A1A1A),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.grey[850]!,
              width: 1,
            ),
          ),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Name
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  entry.username,
                  style: GoogleFonts.urbanist(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 2),
              // Handle (using @ prefix)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  '@${entry.username.toLowerCase()}',
                  style: GoogleFonts.urbanist(
                    color: Colors.grey[500],
                    fontSize: 10,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                ),
              ),
              const SizedBox(height: 6),
              // Gender indicator (placeholder)
              Icon(
                position == 2 ? Icons.minimize : Icons.arrow_drop_up,
                color: position == 2 ? Colors.white : accentColor,
                size: 16,
              ),
              const SizedBox(height: 2),
              // Score
              Text(
                '${entry.totalPoints}',
                style: GoogleFonts.epilogue(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLeaderboardRow(LeaderboardEntry entry) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1A1A),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey[850]!,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.grey[800],
            ),
            child: const Icon(
              Icons.person,
              color: Colors.white54,
              size: 30,
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
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  '@${entry.username.toLowerCase()}',
                  style: GoogleFonts.urbanist(
                    color: Colors.grey[500],
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          // Gender indicator
          const Icon(
            Icons.arrow_drop_up,
            color: Color(0xFF4FC3F7),
            size: 24,
          ),
          const SizedBox(width: 8),
          // Score
          Text(
            '${entry.totalPoints}',
            style: GoogleFonts.epilogue(
              color: Colors.white,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
