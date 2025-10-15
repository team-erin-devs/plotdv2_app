import 'package:flutter/material.dart';
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
      backgroundColor: Colors.black,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            children: [
              const SizedBox(height: 20),
              // Header
              const Text(
                'Leaderboard',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Top performers this week',
                style: TextStyle(color: Colors.white70, fontSize: 14),
              ),
              const SizedBox(height: 24),

              // Leaderboard List with FutureBuilder
              Expanded(
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
                              style: const TextStyle(
                                color: Colors.white70,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              '${snapshot.error}',
                              style: const TextStyle(
                                color: Colors.white38,
                                fontSize: 12,
                              ),
                              textAlign: TextAlign.center,
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
                      return const Center(
                        child: Text(
                          'No leaderboard data available',
                          style: TextStyle(color: Colors.white70, fontSize: 16),
                        ),
                      );
                    }

                    return RefreshIndicator(
                      onRefresh: () async {
                        _refreshLeaderboard();
                        await _leaderboardFuture;
                      },
                      child: ListView.builder(
                        itemCount: leaderboard.length,
                        itemBuilder: (context, index) {
                          final entry = leaderboard[index];
                          return LeaderboardCard(entry: entry);
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// Leaderboard Card Widget (like your ChallengeCard)
class LeaderboardCard extends StatelessWidget {
  final LeaderboardEntry entry;

  const LeaderboardCard({super.key, required this.entry});

  Color _getRankColor(int rank) {
    switch (rank) {
      case 1:
        return Colors.amber; // Gold
      case 2:
        return Colors.grey.shade400; // Silver
      case 3:
        return Colors.orange.shade800; // Bronze
      default:
        return Colors.white70;
    }
  }

  Widget _getRankIcon(int rank) {
    if (rank <= 3) {
      return Icon(Icons.emoji_events, color: _getRankColor(rank), size: 28);
    }
    return Text(
      '#${rank}',
      style: TextStyle(
        color: _getRankColor(rank),
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: entry.rank <= 3
              ? _getRankColor(entry.rank)
              : Colors.grey.shade800,
          width: entry.rank <= 3 ? 2 : 1,
        ),
      ),
      child: Row(
        children: [
          // Rank indicator
          SizedBox(width: 50, child: Center(child: _getRankIcon(entry.rank))),

          const SizedBox(width: 12),

          // Avatar (circular placeholder)
          CircleAvatar(
            radius: 22,
            backgroundColor: Colors.grey.shade700,
            child: Text(
              entry.username[0].toUpperCase(),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),

          const SizedBox(width: 16),

          // Username
          Expanded(
            child: Text(
              entry.username,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),

          // Score
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.black,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${entry.totalPoints} pts',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
