import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/authenticated_api_service.dart';
import '../widgets/sidequest_card.dart';
import 'profile_screen.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isLoadingDiscover = true;
  bool _isSearching = false;

  // Discover data
  List<Map<String, dynamic>> _topUsers = [];
  List<Map<String, dynamic>> _suggestedSidequests = [];
  List<Map<String, dynamic>> _trendingTags = [];

  // Search results
  List<Map<String, dynamic>> _searchResults = [];

  @override
  void initState() {
    super.initState();
    _loadDiscoverData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchTopUsers() async {
    try {
      final res =
          await AuthenticatedApiService.authenticatedGet('/api/search/top-users/?limit=6');
      if (mounted && res.statusCode == 200) {
        setState(() {
          _topUsers = List<Map<String, dynamic>>.from(jsonDecode(res.body));
        });
      }
    } catch (e) {
      debugPrint('Error fetching top users: $e');
    }
  }

  Future<void> _fetchDiscoverFeed() async {
    try {
      final res =
          await AuthenticatedApiService.authenticatedGet('/api/search/discover/');
      if (mounted && res.statusCode == 200) {
        final data = jsonDecode(res.body);
        setState(() {
          _suggestedSidequests =
              List<Map<String, dynamic>>.from(data['suggested_sidequests'] ?? []);
          _trendingTags =
              List<Map<String, dynamic>>.from(data['trending_tags'] ?? []);
        });
      }
    } catch (e) {
      debugPrint('Error fetching discover feed: $e');
    }
  }

  Future<void> _handleFollowUser(String username, int index, bool isSearchList) async {
    try {
      final res = await AuthenticatedApiService.authenticatedPost(
        '/api/friends/request/',
        {'username': username},
      );
      if (mounted && res.statusCode == 201) {
        setState(() {
          if (isSearchList) {
            _searchResults[index]['pending_sent'] = true;
          } else {
            _topUsers[index]['pending_sent'] = true;
          }
        });
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
  }

  Future<void> _handleAcceptUser(int pendingReceivedId, int index, bool isSearchList) async {
    try {
      final res = await AuthenticatedApiService.authenticatedPost(
        '/api/friends/request/$pendingReceivedId/respond/',
        {'action': 'accept'},
      );
      if (mounted && res.statusCode == 200) {
        setState(() {
          if (isSearchList) {
            _searchResults[index]['is_friend'] = true;
            _searchResults[index]['pending_received_id'] = null;
          } else {
            _topUsers[index]['is_friend'] = true;
            _topUsers[index]['pending_received_id'] = null;
          }
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
  }

  Future<void> _loadDiscoverData() async {
    try {
      await Future.wait([
        _fetchTopUsers(),
        _fetchDiscoverFeed(),
      ]);
    } finally {
      if (mounted) setState(() => _isLoadingDiscover = false);
    }
  }

  Future<void> _performSearch(String query) async {
    if (query.trim().isEmpty) {
      setState(() {
        _searchResults = [];
        _isSearching = false;
      });
      return;
    }

    setState(() => _isSearching = true);

    try {
      final res = await AuthenticatedApiService.authenticatedGet(
          '/api/search/users/?q=${Uri.encodeComponent(query.trim())}');
      if (mounted && res.statusCode == 200) {
        setState(() {
          _searchResults =
              List<Map<String, dynamic>>.from(jsonDecode(res.body));
          _isSearching = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Search error: $e');
      if (mounted) setState(() => _isSearching = false);
    }
  }

  bool get _hasSearchQuery => _searchController.text.trim().isNotEmpty;

  // Emoji map for trending tags / vibes
  static const _vibeEmojis = {
    'chill': '🧘',
    'active': '🏃',
    'social': '🍫',
    'fun': '🎉',
    'productive': '📚',
  };

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData.light().copyWith(
        scaffoldBackgroundColor: const Color(0xFFF8F4F0),
        textTheme: GoogleFonts.plusJakartaSansTextTheme(),
      ),
      child: Scaffold(
        body: SafeArea(
          child: _isLoadingDiscover
              ? const Center(
                  child: CircularProgressIndicator(color: Color(0xFFE8837C)))
              : SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // ── Plotd Header ──
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Icon(Icons.add, size: 28, color: Colors.black87),
                          Image.asset(
                            'assets/images/plotd-title.png',
                            height: 32,
                          ),
                          const Icon(Icons.notifications_none, size: 28, color: Colors.black87),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // ── Search bar ──
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEAE6E0),
                          borderRadius: BorderRadius.circular(28),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.search,
                                color: Colors.grey[500], size: 22),
                            const SizedBox(width: 10),
                            Expanded(
                              child: TextField(
                                controller: _searchController,
                                onChanged: (q) {
                                  _performSearch(q);
                                  setState(() {});
                                },
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.black87,
                                ),
                                decoration: InputDecoration(
                                  hintText: '@search',
                                  hintStyle: GoogleFonts.plusJakartaSans(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey[500],
                                  ),
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding:
                                      const EdgeInsets.symmetric(vertical: 10),
                                ),
                              ),
                            ),
                            if (_hasSearchQuery)
                              GestureDetector(
                                onTap: () {
                                  _searchController.clear();
                                  setState(() {
                                    _searchResults = [];
                                    _isSearching = false;
                                  });
                                },
                                child: Icon(Icons.close,
                                    color: Colors.grey[500], size: 20),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),

                      // Show search results or discover content
                      if (_hasSearchQuery) ...[
                        _buildSearchResults(),
                      ] else ...[
                        _buildDiscoverContent(),
                      ],
                    ],
                  ),
                ),
        ),
      ),
    );
  }

  // ── Search Results ──
  Widget _buildSearchResults() {
    if (_isSearching) {
      return const Padding(
        padding: EdgeInsets.only(top: 40),
        child: Center(
            child: CircularProgressIndicator(color: Color(0xFFE8837C))),
      );
    }

    if (_searchResults.isEmpty) {
      return Padding(
        padding: const EdgeInsets.only(top: 40),
        child: Center(
          child: Column(
            children: [
              Image.asset('assets/images/asterik.png', width: 40, color: const Color(0xFFE8837C)),
              const SizedBox(height: 10),
              Text(
                'no users found',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: Colors.black45,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: _searchResults.asMap().entries.map((entry) {
        final int index = entry.key;
        final user = entry.value;

        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => ProfileScreen(
                  userId: user['id'] as int,
                  username: user['username'] as String,
                ),
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  // Avatar
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: const Color(0xFFEAE6E0),
                    backgroundImage: user['profile_picture'] != null &&
                            (user['profile_picture'] as String).isNotEmpty
                        ? NetworkImage(user['profile_picture'])
                        : null,
                    child: user['profile_picture'] == null ||
                            (user['profile_picture'] as String).isEmpty
                        ? Text(
                            (user['username'] as String)
                                .substring(0, 1)
                                .toUpperCase(),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF455A64),
                            ),
                          )
                        : null,
                  ),
                  const SizedBox(width: 14),
                  // Name + username
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if ((user['display_name'] as String?)?.isNotEmpty == true)
                              Text(
                                user['display_name'],
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.black87,
                                ),
                              ),
                            Text(
                              '@${user['username']}',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: Colors.black45,
                              ),
                            ),
                          ],
                        ),
                        _buildRelationshipButton(user, index, true),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── Discover Content ──
  Widget _buildDiscoverContent() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Popular sidequest setters ──
        if (_topUsers.isNotEmpty) ...[
          Text(
            'popular sidequest setters',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            height: 210, // increased to fit the larger styling
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _topUsers.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, i) => _buildTopUserCard(_topUsers[i], i),
            ),
          ),
          const SizedBox(height: 28),
        ],

        if (_trendingTags.isNotEmpty) ...[
          Text(
            'Trending tags',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: _trendingTags.map((t) {
              final tag = t['tag'] as String;
              final emoji = _vibeEmojis[tag] ?? '';
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8837C).withValues(alpha: 0.7),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (emoji.isNotEmpty) ...[
                      Text(emoji, style: const TextStyle(fontSize: 13)),
                      const SizedBox(width: 6),
                    ],
                    Text(
                      tag,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
          const SizedBox(height: 36),
        ],

        if (_suggestedSidequests.isNotEmpty) ...[
          Text(
            'Sidequests you may like',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 14),
          // We only display one card in this mock layout, or side scroll. 
          // The mock shows 1 with pagination dots. Let's show the first and dots.
          _buildSuggestedCard(_suggestedSidequests.first),
          
          const SizedBox(height: 16),
          // Pagination Dots (static for mockup match)
          Row(
             mainAxisAlignment: MainAxisAlignment.center,
             children: [
                Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFFC4C4C4), shape: BoxShape.circle)),
                const SizedBox(width: 8),
                Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFF1E1E1E), shape: BoxShape.circle)),
                const SizedBox(width: 8),
                Container(width: 8, height: 8, decoration: const BoxDecoration(color: Color(0xFFC4C4C4), shape: BoxShape.circle)),
             ],
          ),
        ],

        const SizedBox(height: 40),
      ],
    );
  }

  // ── Top User Card ──
  Widget _buildTopUserCard(Map<String, dynamic> user, int index) {
    final username = user['username'] as String;
    final displayName =
        (user['display_name'] as String?)?.isNotEmpty == true
            ? user['display_name'] as String
            : username;
    final profilePic = user['profile_picture'] as String?;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => ProfileScreen(
              userId: user['id'] as int,
              username: username,
            ),
          ),
        );
      },
      child: Container(
        width: 140,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFC4D9E2), // light blue matching hi-fi
          borderRadius: BorderRadius.circular(4),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Avatar
            CircleAvatar(
              radius: 40,
              backgroundColor: Colors.white,
              backgroundImage: profilePic != null && profilePic.isNotEmpty
                  ? NetworkImage(profilePic)
                  : null,
              child: profilePic == null || profilePic.isEmpty
                  ? Text(
                      username.substring(0, 1).toUpperCase(),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 26,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF455A64),
                      ),
                    )
                  : null,
            ),
            const SizedBox(height: 12),
            // Display name
            Text(
              displayName,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF1E1E1E),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            // @username
            Text(
              '@$username',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF1E1E1E),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const Spacer(),
            // Follow button
            SizedBox(
              width: double.infinity,
              child: _buildRelationshipButton(user, index, false),
            )
          ],
        ),
      ),
    );
  }

  // ── Suggested Sidequest Card ──
  Widget _buildSuggestedCard(Map<String, dynamic> sq) {
    // Determine the type: own, friend, or community
    // For now we assume if it's suggested it's a friend (to show pink in mock)
    // You could dynamically use `postToCampusBoard` logic too if available
    SidequestType sidequestType = SidequestType.friend;
    
    // Fallbacks if location/date missing in the search object (unlikely if populated, but safe)
    DateTime eventDatetime;
    try {
      eventDatetime = DateTime.parse(sq['event_datetime'] as String);
    } catch (_) {
      eventDatetime = DateTime.now().add(const Duration(days: 1));
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 0),
      child: SidequestCard(
        creatorName: sq['creator_first_name'] ?? sq['creator_username'] ?? 'Friend',
        creatorUsername: sq['creator_username'] ?? 'username',
        title: sq['title'] ?? '',
        eventDatetime: eventDatetime,
        location: sq['location'] ?? 'Location TBD',
        type: sidequestType,
      ),
    );
  }

  Widget _buildRelationshipButton(Map<String, dynamic> user, int index, bool isSearchList) {
    final isFriend = user['is_friend'] ?? false;
    final pendingSent = user['pending_sent'] ?? false;
    final pendingReceivedId = user['pending_received_id'];

    if (isFriend) {
      return ElevatedButton(
        onPressed: null,
        style: ElevatedButton.styleFrom(
          disabledBackgroundColor: const Color(0xFFE0E0E0),
          disabledForegroundColor: Colors.black87,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          elevation: 0,
        ),
        child: Text('Friends', style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w800)),
      );
    } else if (pendingReceivedId != null) {
      return ElevatedButton(
        onPressed: () => _handleAcceptUser(pendingReceivedId, index, isSearchList),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF64A8DB), // secondary blue
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
          elevation: 0,
        ),
        child: Text('Accept', style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w800)),
      );
    } else if (pendingSent) {
      return ElevatedButton(
        onPressed: null,
        style: ElevatedButton.styleFrom(
          disabledBackgroundColor: Colors.white,
          disabledForegroundColor: Colors.black87,
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(4),
            side: const BorderSide(color: Color(0xFFE0E0E0)),
          ),
          elevation: 0,
        ),
        child: Text('Requested', style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w800)),
      );
    } else {
      return ElevatedButton(
        onPressed: () => _handleFollowUser(user['username'], index, isSearchList),
        style: ElevatedButton.styleFrom(
           backgroundColor: const Color(0xFF64A8DB), // secondary blue
           foregroundColor: Colors.white,
           padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
           shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
           elevation: 0,
        ),
        child: Text('Add', style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w800)),
      );
    }
  }
}
