import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import '../services/authenticated_api_service.dart';
import '../services/auth_service.dart';
import '../widgets/bouncing_button.dart';
import 'past_sidequest_screen.dart';

class ProfileScreen extends StatefulWidget {
  final int? userId;
  final String? username;

  const ProfileScreen({super.key, this.userId, this.username});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  bool _isLoading = true;
  String _displayName = '';
  String _username = '';
  String _profilePictureUrl = '';
  int _friendsCount = 0;
  int _sidequestsCompleted = 0;
  int _sidequestsHosted = 0;
  List<Map<String, dynamic>> _activeSidequests = [];
  List<Map<String, dynamic>> _pastSidequests = [];

  // Follow state (for other user profiles)
  bool _isFriend = false;
  bool _pendingSent = false;
  int? _pendingReceivedId;
  bool _isFollowLoading = false;

  bool get _isOwnProfile => widget.userId == null;

  List<Map<String, dynamic>> _interests = [];

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  Future<void> _loadProfileData() async {
    setState(() => _isLoading = true);

    try {
      if (_isOwnProfile) {
        await _loadOwnProfile();
      } else {
        await _loadOtherProfile();
      }
    } catch (e) {
      print('🔴 [Profile] Error: $e');
    }

    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _loadOwnProfile() async {
    final profileFuture = AuthenticatedApiService.authenticatedGet('/api/user/profile/');
    final statsFuture = AuthenticatedApiService.authenticatedGet('/api/user/stats/');
    final mineFuture = AuthenticatedApiService.authenticatedGet('/api/sidequests/mine/');
    final joinedFuture = AuthenticatedApiService.authenticatedGet('/api/sidequests/joined/');

    final results = await Future.wait([profileFuture, statsFuture, mineFuture, joinedFuture]);

    if (results[0].statusCode == 200) {
      final data = jsonDecode(results[0].body);
      _displayName = (data['display_name'] != null && data['display_name'].toString().isNotEmpty)
          ? data['display_name']
          : data['user']?['first_name'] ?? data['user']?['username'] ?? 'User';
      _username = data['user']?['username'] ?? 'user';
      _profilePictureUrl = data['profile_picture'] ?? '';
      _interests = List<Map<String, dynamic>>.from(data['interests'] ?? []);
    }

    if (results[1].statusCode == 200) {
      final stats = jsonDecode(results[1].body);
      _friendsCount = stats['friends_count'] ?? 0;
      _sidequestsCompleted = stats['sidequests_joined'] ?? 0;
      _sidequestsHosted = stats['sidequests_created'] ?? 0;
    }

    final Set<int> seenIds = {};
    _activeSidequests = [];
    _pastSidequests = [];
    
    final now = DateTime.now();
    for (int i = 2; i <= 3; i++) {
      if (results[i].statusCode == 200) {
        final decoded = jsonDecode(results[i].body);
        final List items = decoded is List ? decoded : (decoded['results'] ?? []);
        for (final item in items) {
          final id = item['id'] as int;
          if (seenIds.add(id)) {
            final sq = item as Map<String, dynamic>;
            final eventTime = DateTime.tryParse(sq['event_datetime'] ?? '');
            if (eventTime != null && eventTime.isBefore(now)) {
              _pastSidequests.add(sq);
            } else {
              _activeSidequests.add(sq);
            }
          }
        }
      }
    }
    
    // Sort past sidequests by most recent
    _pastSidequests.sort((a, b) {
      final timeA = DateTime.tryParse(a['event_datetime'] ?? '') ?? DateTime(2000);
      final timeB = DateTime.tryParse(b['event_datetime'] ?? '') ?? DateTime(2000);
      return timeB.compareTo(timeA);
    });
  }

  Future<void> _loadOtherProfile() async {
    debugPrint('🔵 [Profile] Loading other user: ${widget.userId}');
    final res = await AuthenticatedApiService.authenticatedGet(
        '/api/user/profile/${widget.userId}/');

    debugPrint('🔵 [Profile] Response: ${res.statusCode} ${res.body.substring(0, res.body.length.clamp(0, 300))}');
    if (res.statusCode == 200 && mounted) {
      final data = jsonDecode(res.body);

      // display_name can be empty string from backend, so check .isNotEmpty
      final rawDisplayName = data['display_name']?.toString() ?? '';
      final rawUsername = data['user']?['username']?.toString() ?? '';

      _displayName = rawDisplayName.isNotEmpty
          ? rawDisplayName
          : (widget.username ?? 'User');
      _username = rawUsername.isNotEmpty
          ? rawUsername
          : (widget.username ?? 'user');
      _profilePictureUrl = data['profile_picture'] ?? '';

      debugPrint('🔵 [Profile] Parsed: name=$_displayName, user=$_username');

      final stats = data['stats'] ?? {};
      _friendsCount = stats['friends_count'] ?? 0;
      _sidequestsCompleted = stats['sidequests_joined'] ?? 0;
      _sidequestsHosted = stats['sidequests_created'] ?? 0;

      _activeSidequests = List<Map<String, dynamic>>.from(
          data['active_sidequests'] ?? []);
      _pastSidequests = List<Map<String, dynamic>>.from(
          data['past_sidequests'] ?? []);

      _isFriend = data['is_friend'] ?? false;
      _pendingSent = data['pending_sent'] ?? false;
      _pendingReceivedId = data['pending_received_id'];
      
      _interests = List<Map<String, dynamic>>.from(data['interests'] ?? []);
    }
  }

  Future<void> _handleFollow() async {
    setState(() => _isFollowLoading = true);
    try {
      final res = await AuthenticatedApiService.authenticatedPost(
        '/api/friends/request/',
        {'username': _username},
      );
      if (mounted && res.statusCode == 201) {
        setState(() => _pendingSent = true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('friend request sent! 🎉',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
            backgroundColor: const Color(0xFFE8837C),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      debugPrint('🔴 Follow error: $e');
    }
    if (mounted) setState(() => _isFollowLoading = false);
  }

  Future<void> _handleAccept() async {
    if (_pendingReceivedId == null) return;
    setState(() => _isFollowLoading = true);
    try {
      final res = await AuthenticatedApiService.authenticatedPost(
        '/api/friends/request/$_pendingReceivedId/respond/',
        {'action': 'accept'},
      );
      if (mounted && res.statusCode == 200) {
        setState(() {
          _isFriend = true;
          _pendingReceivedId = null;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('friend request accepted! 🎉',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
            backgroundColor: const Color(0xFF66BB6A), // green
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      debugPrint('🔴 Accept error: $e');
    }
    if (mounted) setState(() => _isFollowLoading = false);
  }

  Future<void> _handleLogout() async {
    try {
      await AuthService.logout();
      if (mounted) Navigator.of(context).pushReplacementNamed('/login');
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error logging out: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData.light().copyWith(
        scaffoldBackgroundColor: const Color(0xFFF8F4F0),
        textTheme: GoogleFonts.plusJakartaSansTextTheme(),
      ),
      child: Scaffold(
        body: SafeArea(
          child: _isLoading
              ? const Center(child: CircularProgressIndicator(color: Color(0xFFE8837C)))
              : RefreshIndicator(
                  onRefresh: _loadProfileData,
                  color: const Color(0xFFE8837C),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Header ──
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            if (_isOwnProfile)
                              const Icon(Icons.add, size: 28, color: Colors.black87)
                            else
                              IconButton(
                                icon: const Icon(Icons.arrow_back_ios, color: Colors.black87, size: 24),
                                onPressed: () => Navigator.pop(context),
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                              ),
                            Image.asset(
                              'assets/images/plotd-title.png',
                              height: 32,
                            ),
                            const Icon(Icons.notifications_none, size: 28, color: Colors.black87),
                          ],
                        ),
                        const SizedBox(height: 28),

                        // ── Profile Section ──
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Profile picture
                            Stack(
                              clipBehavior: Clip.none,
                              children: [
                                CircleAvatar(
                                  radius: 44,
                                  backgroundColor: const Color(0xFFE0E0E0),
                                  backgroundImage: _profilePictureUrl.isNotEmpty
                                      ? (_profilePictureUrl.startsWith('images/') || _profilePictureUrl.startsWith('assets/images/')
                                          ? AssetImage(_profilePictureUrl.startsWith('images/') ? 'assets/$_profilePictureUrl' : _profilePictureUrl)
                                          : NetworkImage(_profilePictureUrl)) as ImageProvider
                                      : null,
                                  child: _profilePictureUrl.isEmpty
                                      ? Icon(Icons.person, size: 44, color: Colors.grey[500])
                                      : null,
                                ),
                                Positioned(
                                  bottom: -4,
                                  right: -4,
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFFFB300),
                                      shape: BoxShape.circle,
                                      border: Border.all(color: const Color(0xFFF8F4F0), width: 3),
                                    ),
                                    child: Text(
                                      '7',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                        color: Colors.white,
                                        height: 1.0,
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 16),
                            // Right side stats and buttons
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Stats Row
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            _displayName,
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 22,
                                              fontWeight: FontWeight.w800,
                                              color: Colors.black,
                                            ),
                                          ),
                                          Text(
                                            '@$_username',
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w500,
                                              color: Colors.black38,
                                            ),
                                          ),
                                        ],
                                      ),
                                      _buildStatColumn('$_friendsCount', 'friends'),
                                    ],
                                  ),
                                  const SizedBox(height: 16),
                                  // Buttons Row
                                  Row(
                                    children: [
                                      if (_isOwnProfile)
                                        Expanded(
                                          child: BouncingButton(
                                            child: OutlinedButton(
                                              onPressed: () {},
                                              style: OutlinedButton.styleFrom(
                                                foregroundColor: Colors.black,
                                                side: const BorderSide(color: Color(0xFF2D2D2D)),
                                                padding: const EdgeInsets.symmetric(vertical: 8),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(4),
                                                ),
                                              ),
                                              child: Text(
                                                'Edit Profile',
                                                style: GoogleFonts.plusJakartaSans(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w800,
                                                ),
                                              ),
                                            ),
                                          ),
                                        )
                                      else
                                        Expanded(
                                          child: _buildRelationshipButton(),
                                        ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: OutlinedButton(
                                          onPressed: () {},
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: Colors.black,
                                            side: const BorderSide(color: Color(0xFF2D2D2D)),
                                            padding: const EdgeInsets.symmetric(vertical: 8),
                                            shape: RoundedRectangleBorder(
                                              borderRadius: BorderRadius.circular(4),
                                            ),
                                          ),
                                          child: Text(
                                            'Share profile',
                                            style: GoogleFonts.plusJakartaSans(
                                              fontSize: 13,
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
                          ],
                        ),
                        const SizedBox(height: 32),

                        // ── Interests ──
                        Text(
                          'Interests',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Colors.black,
                          ),
                        ),
                        // Interests list
                      if (_interests.isNotEmpty)
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            alignment: WrapAlignment.start,
                            children: _interests.map((interest) {
                              return Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 14,
                                  vertical: 8,
                                ),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFFF3D4), // light yellow
                                  border: Border.all(
                                    color: const Color(0xFFFFB300), // dark yellow edge
                                    width: 1,
                                  ),
                                  borderRadius: BorderRadius.circular(4), // Slightly sharper corners matching mockup
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Text(
                                      interest['emoji']?.toString() ?? '',
                                      style: const TextStyle(fontSize: 16),
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      interest['label']?.toString() ?? '',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.black87,
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }).toList(),
                          ),
                        )
                      else
                        Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            'no interests listed yet.',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w400,
                              color: Colors.black45,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),  
                        const SizedBox(height: 32),

                        // ── Sidequest Gallery ──
                        Text(
                          'Sidequest Gallery',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 16),
                        if (_pastSidequests.isEmpty)
                          Container(
                            height: 120, // Explicit height, outside of GridView
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFE8E0D8)),
                            ),
                            alignment: Alignment.center,
                            child: Text(
                              'no past quests yet!',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Colors.black38,
                              ),
                            ),
                          )
                        else
                          MasonryGridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: const SliverSimpleGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                            ),
                            mainAxisSpacing: 10,
                            crossAxisSpacing: 10,
                            itemCount: _pastSidequests.length,
                            itemBuilder: (context, index) {

                            final quest = _pastSidequests[index];
                            final title = quest['title'] ?? 'untitled';
                            final creatorUsername = quest['creator']?['username'] ?? 'unknown';
                            final vibe = quest['vibe']?.toString() ?? 'chill';
                            final isPublic = quest['post_to_campus_board'] == true;
                            
                            // Check for images
                            final List<dynamic> images = quest['images'] ?? [];
                            final hasImage = images.isNotEmpty;

                            final tags = <String>[
                              isPublic ? 'community' : 'friends-only',
                            ];

                            String typeEmoji = '📌$vibe';
                            if (vibe == 'productive') typeEmoji = '☕coffee';
                            else if (vibe == 'social') typeEmoji = '🗣️social';
                            else if (vibe == 'chill') typeEmoji = '🛋️chill';
                            else if (vibe == 'fun') typeEmoji = '🎉fun';
                            else if (vibe == 'active') typeEmoji = '🏃active';

                            // Determine colors for sticky notes
                            final colors = [
                               const Color(0xFFFFF3D4), // yellow
                               const Color(0xFFDDE9F7), // light blue
                               const Color(0xFFFDE4E1), // salmon 
                               const Color(0xFFDDE9F7), // light blue
                            ];
                            final accentColors = [
                               const Color(0xFFFFB300), // dark yellow
                               const Color(0xFF64A8DB), // dark blue
                               const Color(0xFFE8837C), // dark pink
                               const Color(0xFF64A8DB), // dark blue
                            ];

                            return BouncingButton(
                              onPressed: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => PastSidequestScreen(
                                      sidequestId: quest['id'],
                                    ),
                                  ),
                                );
                              },
                              child: hasImage
                                ? GalleryImageCard(
                                    imageUrl: images.first.toString(),
                                    title: title,
                                  )
                                : GalleryStickyNote(
                                    color: colors[index % colors.length],
                                    accentColor: accentColors[index % accentColors.length],
                                    title: title,
                                    hostedBy: creatorUsername == _username ? 'you' : creatorUsername,
                                    tags: tags,
                                    typeEmoji: typeEmoji,
                                  ),
                            );
                          },
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }

  Widget _buildStatColumn(String value, String label) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 20,
            fontWeight: FontWeight.w400,
            color: Colors.black,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.black45,
          ),
        ),
      ],
    );
  }

  Widget _buildRelationshipButton() {
    if (_isFriend) {
      return BouncingButton(
        child: ElevatedButton(
          onPressed: null,
          style: ElevatedButton.styleFrom(
            disabledBackgroundColor: const Color(0xFFE0E0E0),
            disabledForegroundColor: Colors.black87,
            padding: const EdgeInsets.symmetric(vertical: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            elevation: 0,
          ),
          child: Text('Friends', style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w800)),
        ),
      );
    } else if (_pendingReceivedId != null) {
      return BouncingButton(
        child: ElevatedButton(
          onPressed: _isFollowLoading ? null : _handleAccept,
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF64A8DB), // secondary blue
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 8),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
            elevation: 0,
          ),
          child: _isFollowLoading
              ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : Text('Accept', style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w800)),
        ),
      );
    } else if (_pendingSent) {
      return BouncingButton(
        child: ElevatedButton(
          onPressed: null,
          style: ElevatedButton.styleFrom(
            disabledBackgroundColor: Colors.white,
            disabledForegroundColor: Colors.black87,
            padding: const EdgeInsets.symmetric(vertical: 8),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(4),
              side: const BorderSide(color: Color(0xFFE0E0E0)),
            ),
            elevation: 0,
          ),
          child: Text('Requested', style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w800)),
        ),
      );
    } else {
      return BouncingButton(
        child: ElevatedButton(
          onPressed: _isFollowLoading ? null : _handleFollow,
          style: ElevatedButton.styleFrom(
             backgroundColor: const Color(0xFF64A8DB), // secondary blue matching search screen
             foregroundColor: Colors.white,
             padding: const EdgeInsets.symmetric(vertical: 8),
             shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
             elevation: 0,
          ),
          child: _isFollowLoading
              ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
              : Text('Add', style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w800)),
        ),
      );
    }
  }
}

// ─── Custom Gallery Sticky Note Widget ──────────────────────────────────────

class GalleryStickyNote extends StatelessWidget {
  final Color color;
  final Color accentColor;
  final String title;
  final String hostedBy;
  final List<String> tags;
  final String typeEmoji;
  
  const GalleryStickyNote({
    super.key,
    required this.color,
    required this.accentColor,
    required this.title,
    required this.hostedBy,
    required this.tags,
    required this.typeEmoji,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        ClipPath(
          clipper: _GalleryNoteClipper(),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    fontStyle: FontStyle.italic,
                    color: const Color(0xFF1E1E1E),
                    height: 1.1,
                  ),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text.rich(
                  TextSpan(
                     text: 'hosted by ',
                     style: GoogleFonts.plusJakartaSans(
                       fontSize: 11,
                       fontWeight: FontWeight.w500,
                       fontStyle: FontStyle.italic,
                       color: const Color(0xFF1E1E1E),
                     ),
                     children: [
                        TextSpan(
                           text: hostedBy,
                           style: const TextStyle(fontWeight: FontWeight.w800),
                        )
                     ]
                  )
                ),
                const SizedBox(height: 8),
                Container(height: 1, color: const Color(0xFF1E1E1E).withOpacity(0.1)),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 4,
                  runSpacing: 4,
                  children: tags.map((tag) => Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                    decoration: BoxDecoration(
                      color: accentColor,
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: Text(
                      tag,
                      style: GoogleFonts.plusJakartaSans(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w500),
                    )
                  )).toList(),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                      decoration: BoxDecoration(
                        color: accentColor, 
                        borderRadius: BorderRadius.circular(2),
                      ),
                      child: Text(
                        typeEmoji,
                        style: GoogleFonts.plusJakartaSans(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w500),
                      )
                    ),
                    const Icon(Icons.remove_red_eye_outlined, size: 16, color: Color(0xFF1E1E1E)),
                  ],
                ),
              ],
            ),
          ),
        ),
        Positioned(
          top: 0,
          right: 0, 
          child: CustomPaint(
              size: const Size(20,20),
              painter: _FoldPainter(color: accentColor),
          )
        ),
      ],
    );
  }
}

class _GalleryNoteClipper extends CustomClipper<Path> {
  @override
  Path getClip(Size size) {
    final path = Path();
    path.lineTo(size.width - 20, 0); 
    path.lineTo(size.width, 20); 
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    return path;
  }
  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => false;
}

class _FoldPainter extends CustomPainter {
  final Color color;
  _FoldPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final path = Path();
    path.moveTo(0, 0); 
    path.lineTo(0, size.height); 
    path.lineTo(size.width, size.height); 
    path.close();

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// ─── Custom Gallery Image Card Widget ───────────────────────────────────────

class GalleryImageCard extends StatelessWidget {
  final String imageUrl;
  final String title;

  const GalleryImageCard({
    super.key,
    required this.imageUrl,
    required this.title,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: const Color(0xFFE0E0E0),
      ),
      clipBehavior: Clip.hardEdge,
      child: Stack(
        children: [
          // Background Image
          // Background Image
          (imageUrl.startsWith('images/') || imageUrl.startsWith('assets/images/'))
              ? Image.asset(
                  imageUrl.startsWith('images/') ? 'assets/$imageUrl' : imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: const Color(0xFFE0E0E0),
                      height: 150,
                      alignment: Alignment.center,
                      child: const Icon(Icons.broken_image, color: Colors.black38),
                    );
                  },
                )
              : Image.network(
                  imageUrl,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      color: const Color(0xFFE0E0E0),
                      height: 150,
                      alignment: Alignment.center,
                      child: const Icon(Icons.broken_image, color: Colors.black38),
                    );
                  },
                ),
          
          // Gradient Overlay
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withOpacity(0.7),
                    Colors.black.withOpacity(0.0),
                    Colors.black.withOpacity(0.0),
                    Colors.black.withOpacity(0.3),
                  ],
                ),
              ),
            ),
          ),
          
          // Visibility Icon (Top Right)
          const Positioned(
            top: 8,
            right: 8,
            child: CircleAvatar(
              radius: 12,
              backgroundColor: Colors.white,
              child: Icon(Icons.remove_red_eye_outlined, size: 14, color: Colors.black),
            ),
          ),

          // Title Text (Bottom Left)
          Positioned(
            bottom: 12,
            left: 12,
            right: 12,
            child: Text(
              title,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                height: 1.1,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
