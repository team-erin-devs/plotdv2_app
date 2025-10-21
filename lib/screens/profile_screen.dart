import 'package:flutter/material.dart';
import '../services/authenticated_api_service.dart';
import '../services/auth_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _userStats;
  Map<String, dynamic>? _userInfo;
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      // Load user stats and info in parallel
      final stats = await AuthenticatedApiService.getUserStats();
      final info = await AuthenticatedApiService.getCurrentUser();
      
      setState(() {
        _userStats = stats;
        _userInfo = info;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _handleLogout() async {
    try {
      await AuthService.logout();
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/login');
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error logging out: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: Colors.white),
              )
            : _error != null
                ? _buildError()
                : _buildProfile(),
      ),
    );
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.error_outline, color: Colors.red, size: 60),
          const SizedBox(height: 16),
          const Text(
            'Failed to load profile',
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
          const SizedBox(height: 8),
          Text(
            _error ?? '',
            style: const TextStyle(color: Colors.white70, fontSize: 12),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: _loadProfileData,
            child: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildProfile() {
    final username = _userInfo?['username'] ?? 'User';
    final email = _userInfo?['email'] ?? '';
    final totalPoints = _userStats?['total_points'] ?? 0;
    final leaderboardPosition = _userStats?['leaderboard_position'] ?? 0;
    final challengesCompleted = _userStats?['challenges_completed'] ?? 0;
    final approvedProofs = _userStats?['approved_proofs'] ?? 0;
    final pendingProofs = _userStats?['pending_proofs'] ?? 0;
    final rejectedProofs = _userStats?['rejected_proofs'] ?? 0;

    return RefreshIndicator(
      onRefresh: _loadProfileData,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            const SizedBox(height: 20),
            
            // Profile Header
            _buildProfileHeader(username, email),
            
            const SizedBox(height: 30),
            
            // Stats Cards
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Total Points',
                    totalPoints.toString(),
                    Icons.stars,
                    Colors.amber,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Rank',
                    '#$leaderboardPosition',
                    Icons.emoji_events,
                    Colors.orange,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            Row(
              children: [
                Expanded(
                  child: _buildStatCard(
                    'Completed',
                    challengesCompleted.toString(),
                    Icons.check_circle,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildStatCard(
                    'Pending',
                    pendingProofs.toString(),
                    Icons.pending,
                    Colors.blue,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 30),
            
            // Detailed Stats
            _buildDetailedStats(approvedProofs, pendingProofs, rejectedProofs),
            
            const SizedBox(height: 30),
            
            // Achievement Badges
            _buildAchievements(challengesCompleted, totalPoints),
            
            const SizedBox(height: 30),
            
            // Logout Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _handleLogout,
                icon: const Icon(Icons.logout),
                label: const Text('Logout'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red.shade900,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(String username, String email) {
    return Column(
      children: [
        // Avatar
        CircleAvatar(
          radius: 50,
          backgroundColor: Colors.grey.shade800,
          child: Text(
            username[0].toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        const SizedBox(height: 16),
        
        // Username
        Text(
          username,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        
        const SizedBox(height: 4),
        
        // Email
        Text(
          email,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 14,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white70,
              fontSize: 12,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildDetailedStats(int approved, int pending, int rejected) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Challenge Submissions',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          
          _buildStatRow('Approved', approved, Colors.green),
          const SizedBox(height: 12),
          _buildStatRow('Pending Review', pending, Colors.blue),
          const SizedBox(height: 12),
          _buildStatRow('Rejected', rejected, Colors.red),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, int value, Color color) {
    final total = _userStats?['total_proofs'] ?? 1;
    final percentage = total > 0 ? (value / total * 100).toInt() : 0;
    
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: Text(
            label,
            style: const TextStyle(color: Colors.white70, fontSize: 14),
          ),
        ),
        Expanded(
          flex: 3,
          child: Stack(
            children: [
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: Colors.grey.shade800,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              FractionallySizedBox(
                widthFactor: percentage / 100,
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        SizedBox(
          width: 40,
          child: Text(
            value.toString(),
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.bold,
            ),
            textAlign: TextAlign.right,
          ),
        ),
      ],
    );
  }

  Widget _buildAchievements(int completed, int points) {
    final achievements = [
      if (completed >= 1) {'icon': Icons.flag, 'title': 'First Steps', 'color': Colors.blue},
      if (completed >= 5) {'icon': Icons.local_fire_department, 'title': 'On Fire!', 'color': Colors.orange},
      if (completed >= 10) {'icon': Icons.star, 'title': 'Rising Star', 'color': Colors.yellow},
      if (points >= 100) {'icon': Icons.emoji_events, 'title': 'Century Club', 'color': Colors.purple},
      if (points >= 500) {'icon': Icons.military_tech, 'title': 'Elite', 'color': Colors.amber},
    ];

    if (achievements.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Achievements',
          style: TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: achievements.map((achievement) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.grey.shade900,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: (achievement['color'] as Color).withOpacity(0.5),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    achievement['icon'] as IconData,
                    color: achievement['color'] as Color,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    achievement['title'] as String,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }
}
