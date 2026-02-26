import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/authenticated_api_service.dart';
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

  Future<void> _loadDiscoverData() async {
    try {
      final topRes = await AuthenticatedApiService.authenticatedGet(
          '/api/search/top-users/?limit=10');
      final discoverRes = await AuthenticatedApiService.authenticatedGet(
          '/api/search/discover/');

      if (mounted) {
        setState(() {
          if (topRes.statusCode == 200) {
            _topUsers = List<Map<String, dynamic>>.from(jsonDecode(topRes.body));
          }
          if (discoverRes.statusCode == 200) {
            final data = jsonDecode(discoverRes.body);
            _suggestedSidequests = List<Map<String, dynamic>>.from(
                data['suggested_sidequests'] ?? []);
            _trendingTags = List<Map<String, dynamic>>.from(
                data['trending_tags'] ?? []);
          }
          _isLoadingDiscover = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Discover load error: $e');
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
                        children: [
                          Text.rich(
                            TextSpan(children: [
                              TextSpan(
                                text: 'Plot',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF455A64),
                                ),
                              ),
                              TextSpan(
                                text: 'd',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFFFFB300),
                                ),
                              ),
                              const TextSpan(
                                text: '✳',
                                style: TextStyle(
                                  fontSize: 18,
                                  color: Color(0xFFE8837C),
                                ),
                              ),
                            ]),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '*do it for the plot',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFFFFB300),
                        ),
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
              const Text('✳',
                  style: TextStyle(fontSize: 40, color: Color(0xFFE8837C))),
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
      children: _searchResults.map((user) {
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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if ((user['display_name'] as String?)
                              ?.isNotEmpty ==
                          true)
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
            height: 185,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _topUsers.length,
              separatorBuilder: (_, __) => const SizedBox(width: 12),
              itemBuilder: (context, i) => _buildTopUserCard(_topUsers[i]),
            ),
          ),
          const SizedBox(height: 28),
        ],

        // ── Trending tags ──
        if (_trendingTags.isNotEmpty) ...[
          Text(
            'trending tags',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: _trendingTags.map((t) {
              final tag = t['tag'] as String;
              final emoji = _vibeEmojis[tag] ?? '✳';
              return Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE0E0E0)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(emoji, style: const TextStyle(fontSize: 16)),
                    const SizedBox(width: 6),
                    Text(
                      tag,
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
          const SizedBox(height: 28),
        ],

        // ── Sidequests you may like ──
        if (_suggestedSidequests.isNotEmpty) ...[
          Text(
            'sidequests you may like',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 14),
          ..._suggestedSidequests.map((sq) => _buildSuggestedCard(sq)),
        ],

        const SizedBox(height: 40),
      ],
    );
  }

  // ── Top User Card ──
  Widget _buildTopUserCard(Map<String, dynamic> user) {
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Avatar
          CircleAvatar(
            radius: 32,
            backgroundColor: const Color(0xFFEAE6E0),
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
          const SizedBox(height: 10),
          // Display name
          Text(
            displayName,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          // @username
          Text(
            '@$username',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: Colors.black38,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const Spacer(),
          // Follow button
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF455A64),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: Text(
                'follow',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    ),
    );
  }

  // ── Suggested Sidequest Card ──
  Widget _buildSuggestedCard(Map<String, dynamic> sq) {
    final vibeColors = {
      'chill': const Color(0xFFDDE9F7),
      'active': const Color(0xFFFDE4E1),
      'social': const Color(0xFFFDE08B),
      'fun': const Color(0xFFE1F5E0),
      'productive': const Color(0xFFF3E8FF),
    };
    final dotColors = {
      'chill': const Color(0xFF64A8DB),
      'active': const Color(0xFFE8837C),
      'social': const Color(0xFFFFB300),
      'fun': const Color(0xFF66BB6A),
      'productive': const Color(0xFF9C7BD8),
    };

    final vibe = sq['vibe'] as String? ?? 'chill';
    final cardColor = vibeColors[vibe] ?? const Color(0xFFFDE4E1);
    final dotColor = dotColors[vibe] ?? const Color(0xFFE8837C);

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Creator
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    color: dotColor,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  '@${sq['creator_username']}\'s',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            // Title
            Text(
              sq['title'] ?? '',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Colors.black,
              ),
            ),
            if ((sq['description'] as String?)?.isNotEmpty == true) ...[
              const SizedBox(height: 4),
              Text(
                sq['description'],
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Colors.black54,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }
}
