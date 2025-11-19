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
  Map<String, dynamic>? _userProfile;
  List<dynamic>? _completedProofs;
  bool _isLoading = true;
  String? _error;
  
  // User editable fields (loaded from backend)
  String _userBio = '';
  String _userMajor = '';
  String _userClass = '';
  String _profilePictureUrl = '';

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
      // Load user stats, info, profile, and completed proofs in parallel
      final stats = await AuthenticatedApiService.getUserStats();
      final info = await AuthenticatedApiService.getCurrentUser();
      final profile = await AuthenticatedApiService.getUserProfile();
      final proofs = await AuthenticatedApiService.getUserProofs();
      
      setState(() {
        _userStats = stats;
        _userInfo = info;
        _userProfile = profile;
        _completedProofs = proofs.where((p) => p['status'] == 'approved').toList();
        
        // Load profile fields from backend
        _userBio = profile['bio'] ?? 'No bio yet';
        _userMajor = profile['major'] ?? 'Not specified';
        _userClass = profile['class_year'] ?? 'Not specified';
        _profilePictureUrl = profile['profile_picture'] ?? '';
        
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
      try {
        // Call API to update profile
        final updatedProfile = await AuthenticatedApiService.updateUserProfile(
          bio: result['bio'],
          major: result['major'],
          classYear: result['class'],
        );
        
        setState(() {
          _userProfile = updatedProfile;
          _userBio = updatedProfile['bio'] ?? 'No bio yet';
          _userMajor = updatedProfile['major'] ?? 'Not specified';
          _userClass = updatedProfile['class_year'] ?? 'Not specified';
        });
        
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Profile updated!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to update profile: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  void _viewID() {
    final username = _userInfo?['username'] ?? 'User';
    showDialog(
      context: context,
      builder: (context) => ViewIDCard(
        username: username,
        handle: '@${username.toLowerCase()}',
        profilePictureUrl: _profilePictureUrl,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF000000), // Pure black background
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
      color: const Color(0xFF4FC3F7),
      backgroundColor: Colors.black,
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            // Profile Header Section - All Black Background
            Container(
              color: Colors.black,
              padding: const EdgeInsets.fromLTRB(20, 30, 20, 20),
              child: Column(
                children: [
                  // Profile Picture and Info Row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Profile Picture on the left
                      CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.grey[800],
                        backgroundImage: _profilePictureUrl.isNotEmpty
                            ? NetworkImage(_profilePictureUrl)
                            : null,
                        child: _profilePictureUrl.isEmpty
                            ? Icon(Icons.person, size: 50, color: Colors.grey[600])
                            : null,
                      ),
                      
                      const SizedBox(width: 16),
                      
                      // Username, Handle, and Bio on the right
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Username
                            Text(
                              username,
                              style: GoogleFonts.epilogue(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            
                            const SizedBox(height: 4),
                            
                            // Handle
                            Text(
                              '@${username.toLowerCase()}',
                              style: GoogleFonts.urbanist(
                                color: Colors.grey[500],
                                fontSize: 14,
                              ),
                            ),
                            
                            const SizedBox(height: 12),
                            
                            // Bio
                            Text(
                              _userBio,
                              style: GoogleFonts.urbanist(
                                color: Colors.grey[300],
                                fontSize: 13,
                                height: 1.4,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // University - Centered
                  Center(
                    child: Text(
                      'queensu 🎓🏫',
                      style: GoogleFonts.urbanist(
                        color: Colors.grey[400],
                        fontSize: 13,
                      ),
                    ),
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Rank, Major, Class badges
                  Wrap(
                    alignment: WrapAlignment.start,
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      _buildBadge('Rank #$leaderboardPosition', Colors.red),
                      _buildBadge(_userMajor, Colors.blue),
                      _buildBadge(_userClass, Colors.purple),
                    ],
                  ),
                  
                  const SizedBox(height: 20),
                  
                  // Edit Profile and View ID buttons with gradient background
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.grey[900]!.withOpacity(0.3),
                          Colors.grey[900]!.withOpacity(0.1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            onPressed: _editProfile,
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.white,
                              side: BorderSide(color: Colors.grey[700]!, width: 1),
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                            child: Text(
                              'Edit profile',
                              style: GoogleFonts.urbanist(
                                fontSize: 14,
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
                              side: BorderSide(color: Colors.white, width: 1.5),
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(20),
                              ),
                            ),
                            child: Text(
                              'View ID',
                              style: GoogleFonts.urbanist(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
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
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            text,
            style: GoogleFonts.urbanist(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.2,
            ),
          ),
        ],
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
