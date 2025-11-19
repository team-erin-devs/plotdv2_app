import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/authenticated_api_service.dart';
import '../services/auth_service.dart';
import '../widgets/view_id_card.dart';
import '../widgets/edit_profile_dialog.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  Map<String, dynamic>? _userStats;
  Map<String, dynamic>? _userInfo;
  List<dynamic>? _completedProofs;
  bool _isLoading = true;
  String? _error;
  
  // User editable fields
  String _userBio = 'trying to figure life out 🏆✨\ntech | fitness | lifestyle';
  String _userMajor = 'Commerce';
  String _userClass = 'Class of \'27';

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
      // Load user stats, info, and completed proofs in parallel
      final stats = await AuthenticatedApiService.getUserStats();
      final info = await AuthenticatedApiService.getCurrentUser();
      final proofs = await AuthenticatedApiService.getUserProofs();
      
      setState(() {
        _userStats = stats;
        _userInfo = info;
        _completedProofs = proofs.where((p) => p['status'] == 'approved').toList();
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

  Future<void> _editProfile() async {
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => EditProfileDialog(
        currentBio: _userBio,
        currentMajor: _userMajor,
        currentClass: _userClass,
      ),
    );
    
    if (result != null) {
      setState(() {
        _userBio = result['bio'] ?? _userBio;
        _userMajor = result['major'] ?? _userMajor;
        _userClass = result['class'] ?? _userClass;
      });
      
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated!'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  void _viewID() {
    final username = _userInfo?['username'] ?? 'User';
    showDialog(
      context: context,
      builder: (context) => ViewIDCard(
        username: username,
        handle: '@${username.toLowerCase()}',
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
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
    final leaderboardPosition = _userStats?['leaderboard_position'] ?? 0;
    final challengesCompleted = _userStats?['challenges_completed'] ?? 0;
    final totalPoints = _userStats?['total_points'] ?? 0;

    return RefreshIndicator(
      onRefresh: _loadProfileData,
      color: Colors.blue,
      backgroundColor: Colors.white,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            // Profile Header Section
            Container(
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(40),
                  bottomRight: Radius.circular(40),
                ),
                color: Colors.grey[900],
              ),
              padding: const EdgeInsets.fromLTRB(20, 30, 20, 30),
              child: Column(
                children: [
                  // Profile Picture
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.grey[800],
                    child: Text(
                      username[0].toUpperCase(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 48,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Username
                  Text(
                    username,
                    style: GoogleFonts.epilogue(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 0.5,
                    ),
                  ),
                  
                  const SizedBox(height: 4),
                  
                  // Handle
                  Text(
                    '@${username.toLowerCase()}',
                    style: GoogleFonts.urbanist(
                      color: Colors.grey[400],
                      fontSize: 16,
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Bio
                  Text(
                    _userBio,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.urbanist(
                      color: Colors.grey[300],
                      fontSize: 14,
                      height: 1.5,
                    ),
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // University
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Center(
                      child: Text(
                        'queensu 🎓🏫',
                        style: GoogleFonts.urbanist(
                          color: Colors.white,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Rank, Major, Class badges
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _buildBadge('Rank #$leaderboardPosition', Colors.red),
                        _buildBadge(_userMajor, Colors.blue),
                        _buildBadge(_userClass, Colors.purple),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 24),
                  
                  // Edit Profile and View ID buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _editProfile,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white, width: 1.5),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'Edit profile',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _viewID,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: const BorderSide(color: Colors.white, width: 1.5),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text(
                            'View ID',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Badges Earned Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Badges earned',
                        style: GoogleFonts.epilogue(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Icon(
                        Icons.arrow_forward_ios,
                        color: Colors.grey[400],
                        size: 20,
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Badge icons with gradients
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: _buildBadgeIcons(challengesCompleted, totalPoints),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            
            // Completed Missions Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Completed Missions - ${_getSampleMissionCount()}',
                    style: GoogleFonts.epilogue(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Mission image grid
                  _buildMissionGrid(),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildBadge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.transparent,
        border: Border.all(color: color, width: 1.5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(
        text,
        style: GoogleFonts.urbanist(
          color: Colors.white,
          fontSize: 12,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.2,
        ),
      ),
    );
  }
  
  int _getSampleMissionCount() {
    // Show sample count of 67 if no real proofs
    return _completedProofs?.length ?? 67;
  }

  List<Widget> _buildBadgeIcons(int completed, int points) {
    // Colorful gradient badges - always show 5 with different colors
    final badgeData = [
      {
        'colors': [const Color(0xFF00D4FF), const Color(0xFF9C27B0)], // Blue to Purple
        'icon': Icons.military_tech,
      },
      {
        'colors': [const Color(0xFF9C27B0), const Color(0xFFE91E63)], // Purple to Pink
        'icon': Icons.emoji_events,
      },
      {
        'colors': [const Color(0xFFE91E63), const Color(0xFFFF5722)], // Pink to Red
        'icon': Icons.local_fire_department,
      },
      {
        'colors': [const Color(0xFF00D4FF), const Color(0xFF00BCD4)], // Cyan to Light Blue
        'icon': Icons.star,
      },
      {
        'colors': [const Color(0xFF9C27B0), const Color(0xFF673AB7)], // Purple variant
        'icon': Icons.workspace_premium,
      },
    ];
    
    return badgeData.map((badge) {
      return Container(
        width: 70,
        height: 70,
        margin: const EdgeInsets.only(right: 14),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: badge['colors'] as List<Color>,
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: (badge['colors'] as List<Color>)[0].withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Icon(
          badge['icon'] as IconData,
          color: Colors.white,
          size: 36,
        ),
      );
    }).toList();
  }

  Widget _buildMissionGrid() {
    // Show sample mission placeholders (always show 6 items for demo)
    final sampleMissions = List.generate(6, (index) => index);
    
    // Create a grid of mission images (3 columns, 2 rows)
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        crossAxisSpacing: 6,
        mainAxisSpacing: 6,
        childAspectRatio: 1,
      ),
      itemCount: 6,
      itemBuilder: (context, index) {
        // Check if we have real proofs
        if (_completedProofs != null && index < _completedProofs!.length) {
          final proof = _completedProofs![index];
          final fileUrl = proof['file'] as String?;
          
          if (fileUrl != null && fileUrl.isNotEmpty) {
            return ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                fileUrl,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return _buildPlaceholderMission(index);
                },
              ),
            );
          }
        }
        
        // Show sample placeholder
        return _buildPlaceholderMission(index);
      },
    );
  }

  Widget _buildPlaceholderMission(int index) {
    // Colorful gradient placeholders to show sample completed missions
    final gradientColors = [
      [const Color(0xFF667eea), const Color(0xFF764ba2)],
      [const Color(0xFFf093fb), const Color(0xFFf5576c)],
      [const Color(0xFF4facfe), const Color(0xFF00f2fe)],
      [const Color(0xFF43e97b), const Color(0xFF38f9d7)],
      [const Color(0xFFfa709a), const Color(0xFFfee140)],
      [const Color(0xFF30cfd0), const Color(0xFF330867)],
    ];
    
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: gradientColors[index % gradientColors.length],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Icon(
          Icons.check_circle,
          color: Colors.white.withOpacity(0.7),
          size: 40,
        ),
      ),
    );
  }
}
