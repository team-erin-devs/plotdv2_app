import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../services/authenticated_api_service.dart';
import '../services/auth_service.dart';

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

  // Follow state (for other user profiles)
  bool _isFriend = false;
  bool _pendingSent = false;
  bool _isFollowLoading = false;

  bool get _isOwnProfile => widget.userId == null;

  // Placeholder interests (would come from backend in a real setup)
  final List<Map<String, String>> _interests = [
    {'emoji': '🏀', 'label': 'basketball'},
    {'emoji': '🎸', 'label': 'guitar'},
    {'emoji': '🔨', 'label': 'building'},
    {'emoji': '🍴', 'label': 'food'},
    {'emoji': '🏋️', 'label': 'powerlift'},
  ];

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
    }

    if (results[1].statusCode == 200) {
      final stats = jsonDecode(results[1].body);
      _friendsCount = stats['friends_count'] ?? 0;
      _sidequestsCompleted = stats['sidequests_joined'] ?? 0;
      _sidequestsHosted = stats['sidequests_created'] ?? 0;
    }

    final Set<int> seenIds = {};
    _activeSidequests = [];
    for (int i = 2; i <= 3; i++) {
      if (results[i].statusCode == 200) {
        final decoded = jsonDecode(results[i].body);
        final List items = decoded is List ? decoded : (decoded['results'] ?? []);
        for (final item in items) {
          final id = item['id'] as int;
          if (seenIds.add(id)) {
            _activeSidequests.add(item as Map<String, dynamic>);
          }
        }
      }
    }
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

      _isFriend = data['is_friend'] ?? false;
      _pendingSent = data['pending_sent'] ?? false;
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
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text.rich(
                                  TextSpan(children: [
                                    TextSpan(
                                      text: 'Plot',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 32,
                                        fontWeight: FontWeight.w800,
                                        color: const Color(0xFF455A64),
                                      ),
                                    ),
                                    TextSpan(
                                      text: 'd',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 32,
                                        fontWeight: FontWeight.w800,
                                        color: const Color(0xFFFFB300),
                                      ),
                                    ),
                                    const TextSpan(
                                      text: '✳',
                                      style: TextStyle(fontSize: 20, color: Color(0xFFE8837C)),
                                    ),
                                  ]),
                                ),
                                Text(
                                  '*do it for the plot',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFFFFB300),
                                  ),
                                ),
                              ],
                            ),
                            // Hamburger menu (only on own profile)
                            if (_isOwnProfile)
                              PopupMenuButton<String>(
                                icon: const Icon(Icons.menu, color: Colors.black, size: 28),
                                onSelected: (value) {
                                  if (value == 'logout') _handleLogout();
                                },
                                itemBuilder: (context) => [
                                  PopupMenuItem(
                                    value: 'logout',
                                    child: Row(
                                      children: [
                                        const Icon(Icons.logout, size: 18, color: Colors.redAccent),
                                        const SizedBox(width: 8),
                                        Text('Log out',
                                            style: GoogleFonts.plusJakartaSans(
                                                fontWeight: FontWeight.w600)),
                                      ],
                                    ),
                                  ),
                                ],
                              )
                            else
                              IconButton(
                                onPressed: () => Navigator.pop(context),
                                icon: const Icon(Icons.close, size: 26),
                              ),
                          ],
                        ),
                        const SizedBox(height: 28),

                        // ── Profile Section ──
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            // Profile picture
                            CircleAvatar(
                              radius: 44,
                              backgroundColor: const Color(0xFFE0E0E0),
                              backgroundImage: _profilePictureUrl.isNotEmpty
                                  ? NetworkImage(_profilePictureUrl)
                                  : null,
                              child: _profilePictureUrl.isEmpty
                                  ? Icon(Icons.person, size: 44, color: Colors.grey[500])
                                  : null,
                            ),
                            const SizedBox(width: 16),
                            // Name + @username
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
                            const Spacer(),
                            // Following + followers inline
                            _buildStatColumn('$_friendsCount', 'following'),
                            const SizedBox(width: 16),
                            _buildStatColumn('$_friendsCount', 'followers'),
                          ],
                        ),
                        const SizedBox(height: 16),

                        // ── Buttons ──
                        if (_isOwnProfile)
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () {},
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.black,
                                    side: const BorderSide(color: Color(0xFFD0D0D0)),
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  child: Text(
                                    'edit profile',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () {},
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: Colors.black,
                                    side: const BorderSide(color: Color(0xFFD0D0D0)),
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                  child: Text(
                                    'share profile',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          )
                        else
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: (_isFriend || _pendingSent || _isFollowLoading)
                                  ? null
                                  : _handleFollow,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: _isFriend
                                    ? const Color(0xFF66BB6A)
                                    : _pendingSent
                                        ? const Color(0xFF90A4AE)
                                        : const Color(0xFF64A8DB),
                                disabledBackgroundColor: _isFriend
                                    ? const Color(0xFF66BB6A).withOpacity(0.7)
                                    : const Color(0xFF90A4AE).withOpacity(0.7),
                                foregroundColor: Colors.white,
                                disabledForegroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                elevation: 0,
                              ),
                              child: _isFollowLoading
                                  ? const SizedBox(
                                      width: 20,
                                      height: 20,
                                      child: CircularProgressIndicator(
                                        color: Colors.white,
                                        strokeWidth: 2,
                                      ),
                                    )
                                  : Text(
                                      _isFriend
                                          ? 'friends ✓'
                                          : _pendingSent
                                              ? 'request sent'
                                              : 'follow',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                          ),
                        const SizedBox(height: 32),

                        // ── Today's Sidequest ──
                        Text(
                          'today\'s sidequest',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 12),
                        if (_activeSidequests.isEmpty)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(24),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: const Color(0xFFE8E0D8)),
                            ),
                            child: Text(
                              'no quests today — go post one!',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.black38,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          )
                        else
                          _buildTodayQuestCard(_activeSidequests.first),

                        const SizedBox(height: 20),

                        // ── Stats Cards ──
                        IntrinsicHeight(
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Expanded(
                                child: _buildBigStatCard(
                                  'sidequests completed',
                                  '$_sidequestsCompleted',
                                  const Color(0xFFF8BBB1), // pink
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: _buildBigStatCard(
                                  'sidequests hosted',
                                  '$_sidequestsHosted',
                                  const Color(0xFFFFB300), // yellow/amber
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),

                        // ── Interests ──
                        Text(
                          'interests',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: _interests.map((interest) {
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: const Color(0xFFD0D0D0)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(interest['emoji']!,
                                      style: const TextStyle(fontSize: 16)),
                                  const SizedBox(width: 6),
                                  Text(
                                    interest['label']!,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                        ),
                        const SizedBox(height: 32),

                        // ── Sidequest Gallery ──
                        Text(
                          'sidequest gallery',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.black,
                          ),
                        ),
                        const SizedBox(height: 12),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 3,
                            crossAxisSpacing: 8,
                            mainAxisSpacing: 8,
                            childAspectRatio: 0.85,
                          ),
                          itemCount: 9,
                          itemBuilder: (context, index) {
                            return Container(
                              decoration: BoxDecoration(
                                color: const Color(0xFFFDE08B).withOpacity(0.5),
                                borderRadius: BorderRadius.circular(12),
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
            fontSize: 16,
            fontWeight: FontWeight.w800,
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

  Widget _buildTodayQuestCard(Map<String, dynamic> quest) {
    final creatorUsername = quest['creator']?['username'] ?? 'unknown';
    final title = quest['title'] ?? '';
    final vibe = quest['vibe'] ?? '';
    final eventDatetime = quest['event_datetime'] != null
        ? DateTime.parse(quest['event_datetime'])
        : DateTime.now();
    final dateStr = DateFormat('MMM d').format(eventDatetime.toLocal()).toLowerCase();
    final timeStr = DateFormat('h:mm a').format(eventDatetime.toLocal()).toLowerCase();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFF64A8DB),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Creator
          Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: const BoxDecoration(
                  color: Color(0xFF90CAF9),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '@$creatorUsername\'s',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white70,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Title
          Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          // Info
          Text(
            '$dateStr · $timeStr · $vibe',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: Colors.white60,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBigStatCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 52,
              fontWeight: FontWeight.w800,
              color: Colors.white,
              height: 1.0,
            ),
          ),
        ],
      ),
    );
  }
}
