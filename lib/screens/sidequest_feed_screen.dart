import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../services/authenticated_api_service.dart';

// ─── Data Model ──────────────────────────────────────────────────────────────

class SidequestItem {
  final int id;
  final String title;
  final String description;
  final String creatorUsername;
  final String vibe;
  final String status;
  final DateTime eventDatetime;
  final String location;
  final int maxPeople;
  final int participantCount;
  final int spotsLeft;
  final bool isFull;
  final bool postToCampusBoard;
  final String? userStatus; // 'creator', 'going', 'declined', null

  SidequestItem({
    required this.id,
    required this.title,
    required this.description,
    required this.creatorUsername,
    required this.vibe,
    required this.status,
    required this.eventDatetime,
    required this.location,
    required this.maxPeople,
    required this.participantCount,
    required this.spotsLeft,
    required this.isFull,
    required this.postToCampusBoard,
    this.userStatus,
  });

  factory SidequestItem.fromJson(Map<String, dynamic> json) {
    return SidequestItem(
      id: json['id'],
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      creatorUsername: json['creator']?['username'] ?? 'unknown',
      vibe: json['vibe'] ?? 'chill',
      status: json['status'] ?? 'upcoming',
      eventDatetime: DateTime.parse(json['event_datetime']),
      location: json['location'] ?? '',
      maxPeople: json['max_people'] ?? 5,
      participantCount: json['participant_count'] ?? 0,
      spotsLeft: json['spots_left'] ?? 0,
      isFull: json['is_full'] ?? false,
      postToCampusBoard: json['post_to_campus_board'] ?? false,
      userStatus: json['user_status'],
    );
  }

  bool get isOwn => userStatus == 'creator';
  bool get isFriendsOnly => !postToCampusBoard && !isOwn;
  bool get isPublic => postToCampusBoard && !isOwn;
}

// ─── Screen ──────────────────────────────────────────────────────────────────

class SidequestFeedScreen extends StatefulWidget {
  const SidequestFeedScreen({super.key});

  @override
  State<SidequestFeedScreen> createState() => _SidequestFeedScreenState();
}

class _SidequestFeedScreenState extends State<SidequestFeedScreen> {
  List<SidequestItem> _allSidequests = [];
  bool _isLoading = true;
  String? _error;
  int? _expandedId;
  Set<String> _activeFilters = {'friends-only'};

  final List<String> _filterOptions = [
    'friends-only',
    'public',
    'chill',
    'active',
    'social',
    'fun',
    'productive',
  ];

  @override
  void initState() {
    super.initState();
    _fetchSidequests();
  }

  Future<void> _fetchSidequests() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final List<SidequestItem> combined = [];
      final Set<int> seenIds = {};

      // Fetch friend board
      try {
        print('🔵 [Feed] Fetching /api/sidequests/ ...');
        final friendsResponse =
            await AuthenticatedApiService.authenticatedGet('/api/sidequests/');
        print('🔵 [Feed] Friends response: ${friendsResponse.statusCode}');
        if (friendsResponse.statusCode == 200) {
          final decoded = jsonDecode(friendsResponse.body);
          final List data = decoded is List ? decoded : (decoded['results'] ?? []);
          print('🔵 [Feed] Friends: ${data.length} sidequests');
          for (final item in data) {
            final sq = SidequestItem.fromJson(item);
            if (seenIds.add(sq.id)) combined.add(sq);
          }
        } else {
          print('🔴 [Feed] Friends non-200: ${friendsResponse.body}');
        }
      } catch (e) {
        print('🔴 [Feed] Friends fetch error: $e');
      }

      // Fetch campus board
      try {
        print('🔵 [Feed] Fetching /api/sidequests/campus/ ...');
        final campusResponse =
            await AuthenticatedApiService.authenticatedGet('/api/sidequests/campus/');
        print('🔵 [Feed] Campus response: ${campusResponse.statusCode}');
        if (campusResponse.statusCode == 200) {
          final decoded = jsonDecode(campusResponse.body);
          final List data = decoded is List ? decoded : (decoded['results'] ?? []);
          print('🔵 [Feed] Campus: ${data.length} sidequests');
          for (final item in data) {
            final sq = SidequestItem.fromJson(item);
            if (seenIds.add(sq.id)) combined.add(sq);
          }
        } else {
          print('🔴 [Feed] Campus non-200: ${campusResponse.body}');
        }
      } catch (e) {
        print('🔴 [Feed] Campus fetch error: $e');
      }

      // Sort by event date
      combined.sort((a, b) => a.eventDatetime.compareTo(b.eventDatetime));
      print('🟢 [Feed] Total sidequests loaded: ${combined.length}');

      setState(() {
        _allSidequests = combined;
        _isLoading = false;
      });
    } catch (e) {
      print('🔴 [Feed] Fatal error: $e');
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  List<SidequestItem> get _filteredSidequests {
    if (_activeFilters.isEmpty) return _allSidequests;

    final sourceFilters = _activeFilters.intersection({'friends-only', 'public'});
    final vibeFilters = _activeFilters.intersection(
        {'chill', 'active', 'social', 'fun', 'productive'});

    return _allSidequests.where((sq) {
      // Source filter check
      bool sourceMatch = sourceFilters.isEmpty; // no source filter = match all
      if (sourceFilters.contains('friends-only') && sq.isFriendsOnly) sourceMatch = true;
      if (sourceFilters.contains('public') && sq.postToCampusBoard) sourceMatch = true;
      // Always include own sidequests when a source filter is active
      if (sourceFilters.isNotEmpty && sq.isOwn) sourceMatch = true;

      // Vibe filter check
      bool vibeMatch = vibeFilters.isEmpty; // no vibe filter = match all
      if (vibeFilters.contains(sq.vibe)) vibeMatch = true;

      // Must pass BOTH source AND vibe filters
      return sourceMatch && vibeMatch;
    }).toList();
  }

  Future<void> _joinSidequest(int id) async {
    try {
      final response = await AuthenticatedApiService.authenticatedPost(
        '/api/sidequests/$id/join/',
        {},
      );
      if (response.statusCode == 200) {
        _fetchSidequests(); // Refresh
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('you\'re in! 🎉',
                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
              backgroundColor: const Color(0xFFE8837C),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      } else {
        final body = jsonDecode(response.body);
        throw Exception(body['detail'] ?? 'Failed to join');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('$e',
                style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600)),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
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
              ? const Center(
                  child: CircularProgressIndicator(color: Color(0xFFE8837C)))
              : _error != null
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text('something went wrong',
                              style: GoogleFonts.plusJakartaSans(
                                  fontSize: 16, fontWeight: FontWeight.w700)),
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: _fetchSidequests,
                            child: Text('try again',
                                style: GoogleFonts.plusJakartaSans(
                                    color: const Color(0xFFE8837C),
                                    fontWeight: FontWeight.w700)),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _fetchSidequests,
                      color: const Color(0xFFE8837C),
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 16),
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
                                      TextSpan(
                                        children: [
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
                                          TextSpan(
                                            text: '✳',
                                            style: TextStyle(
                                              fontSize: 18,
                                              color: const Color(0xFFE8837C),
                                            ),
                                          ),
                                        ],
                                      ),
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
                                // Notification bell
                                Container(
                                  decoration: BoxDecoration(
                                    color: Colors.black,
                                    shape: BoxShape.circle,
                                  ),
                                  padding: const EdgeInsets.all(10),
                                  child: Stack(
                                    children: [
                                      const Icon(Icons.notifications_outlined,
                                          color: Colors.white, size: 22),
                                      Positioned(
                                        right: 0,
                                        top: 0,
                                        child: Container(
                                          width: 8,
                                          height: 8,
                                          decoration: const BoxDecoration(
                                            color: Color(0xFFE8837C),
                                            shape: BoxShape.circle,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),

                            // ── Filter Pills ──
                            SizedBox(
                              height: 36,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: _filterOptions.length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(width: 8),
                                itemBuilder: (context, index) {
                                  final filter = _filterOptions[index];
                                  final isActive =
                                      _activeFilters.contains(filter);
                                  return GestureDetector(
                                    onTap: () {
                                      setState(() {
                                        if (isActive) {
                                          _activeFilters.remove(filter);
                                        } else {
                                          // friends-only and public are mutually exclusive
                                          if (filter == 'friends-only') {
                                            _activeFilters.remove('public');
                                          } else if (filter == 'public') {
                                            _activeFilters.remove('friends-only');
                                          }
                                          _activeFilters.add(filter);
                                        }
                                      });
                                    },
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 16, vertical: 8),
                                      decoration: BoxDecoration(
                                        color: isActive
                                            ? (filter == 'public'
                                                ? const Color(0xFF90CAF9)
                                                : filter == 'friends-only'
                                                    ? const Color(0xFFF8BBB1)
                                                    : const Color(0xFFE0E0E0))
                                            : Colors.white,
                                        borderRadius:
                                            BorderRadius.circular(20),
                                        border: Border.all(
                                          color: isActive
                                              ? Colors.transparent
                                              : const Color(0xFFD0D0D0),
                                          width: 1,
                                        ),
                                      ),
                                      child: Text(
                                        filter,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.black87,
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                            const SizedBox(height: 20),

                            // ── Quest Cards ──
                            if (_filteredSidequests.isEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 60),
                                child: Center(
                                  child: Column(
                                    children: [
                                      const Text('✳',
                                          style: TextStyle(
                                              fontSize: 48,
                                              color: Color(0xFFE8837C))),
                                      const SizedBox(height: 12),
                                      Text(
                                        'no quests yet',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.black54,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        'post one or add some friends!',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 14,
                                          fontWeight: FontWeight.w500,
                                          color: Colors.black38,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              )
                            else
                              ..._filteredSidequests.map((sq) {
                                final isExpanded = _expandedId == sq.id;
                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 16),
                                  child: _SidequestCard(
                                    sidequest: sq,
                                    isExpanded: isExpanded,
                                    onToggle: () {
                                      setState(() {
                                        _expandedId =
                                            isExpanded ? null : sq.id;
                                      });
                                    },
                                    onJoin: () => _joinSidequest(sq.id),
                                  ),
                                );
                              }),
                          ],
                        ),
                      ),
                    ),
        ),
      ),
    );
  }
}

// ─── Quest Card Widget ───────────────────────────────────────────────────────

class _SidequestCard extends StatelessWidget {
  final SidequestItem sidequest;
  final bool isExpanded;
  final VoidCallback onToggle;
  final VoidCallback onJoin;

  const _SidequestCard({
    required this.sidequest,
    required this.isExpanded,
    required this.onToggle,
    required this.onJoin,
  });

  // Own = yellow, Friends = pink, Public = blue
  Color get _cardColor {
    if (sidequest.isOwn) return const Color(0xFFFDE08B);
    if (sidequest.isFriendsOnly) return const Color(0xFFFDE4E1);
    return const Color(0xFFDDE9F7);
  }

  Color get _accentColor {
    if (sidequest.isOwn) return const Color(0xFFFFB300);
    if (sidequest.isFriendsOnly) return const Color(0xFFE8837C);
    return const Color(0xFF64A8DB);
  }

  Color get _tagBgColor {
    if (sidequest.isOwn) return const Color(0xFFFFB300);
    if (sidequest.isFriendsOnly) return const Color(0xFFE8837C);
    return const Color(0xFF64A8DB);
  }

  @override
  Widget build(BuildContext context) {
    final dateStr =
        DateFormat('MMMM d, yyyy').format(sidequest.eventDatetime.toLocal()).toLowerCase();
    final timeStr =
        DateFormat('h:mm a').format(sidequest.eventDatetime.toLocal()).toLowerCase();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: _cardColor,
        borderRadius: BorderRadius.circular(16),
      ),
      child: InkWell(
        onTap: onToggle,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Header row: avatar + username + chevron ──
              Row(
                children: [
                  // Color dot
                  Container(
                    width: 14,
                    height: 14,
                    decoration: BoxDecoration(
                      color: _accentColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '${sidequest.creatorUsername}\'s',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black54,
                      ),
                    ),
                  ),
                  Icon(
                    isExpanded
                        ? Icons.keyboard_arrow_up
                        : Icons.keyboard_arrow_down,
                    color: Colors.black54,
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // ── Title ──
              Text(
                sidequest.title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: Colors.black,
                ),
              ),
              const SizedBox(height: 10),

              // ── Tags ──
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _buildTag(sidequest.vibe, const Color(0xFF607D8B)),
                  _buildTag(
                    sidequest.isOwn
                        ? 'yours'
                        : sidequest.isFriendsOnly
                            ? 'friends-only'
                            : 'public',
                    _tagBgColor,
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // ── Expanded Content ──
              if (isExpanded) ...[
                // Description
                if (sidequest.description.isNotEmpty) ...[
                  Container(
                    width: double.infinity,
                    height: 1,
                    color: Colors.black.withOpacity(0.08),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    sidequest.description,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.black87,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // Date / Time / Location
                _buildInfoRow(Icons.calendar_today, dateStr),
                if (sidequest.location.isNotEmpty)
                  _buildInfoRow(Icons.location_on_outlined, sidequest.location),
                const SizedBox(height: 8),
                _buildInfoRow(Icons.access_time, timeStr),
                const SizedBox(height: 14),

                // Participant dots + spots
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Participant dots
                    Row(
                      children: List.generate(
                        sidequest.maxPeople.clamp(0, 6),
                        (i) => Container(
                          width: 18,
                          height: 18,
                          margin: const EdgeInsets.only(right: 3),
                          decoration: BoxDecoration(
                            color: i < sidequest.participantCount
                                ? _accentColor.withOpacity(0.7)
                                : _accentColor.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                    Text(
                      '${sidequest.participantCount}/${sidequest.maxPeople} spots filled',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Colors.black87,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Join button (only if not already going or creator)
                if (sidequest.userStatus == null ||
                    sidequest.userStatus == 'declined')
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: sidequest.isFull ? null : onJoin,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _accentColor,
                        disabledBackgroundColor: _accentColor.withOpacity(0.3),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(24),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        sidequest.isFull ? 'quest is full' : 'join the plot!',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  )
                else if (sidequest.userStatus == 'going' ||
                    sidequest.userStatus == 'creator')
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: BoxDecoration(
                      color: _accentColor.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Center(
                      child: Text(
                        sidequest.userStatus == 'creator'
                            ? 'your quest ✳'
                            : 'you\'re going! ✓',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: _accentColor,
                        ),
                      ),
                    ),
                  ),
              ] else ...[
                // ── Collapsed: just date + participant dots ──
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.calendar_today,
                            size: 14, color: Colors.black45),
                        const SizedBox(width: 6),
                        Text(
                          dateStr,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.black54,
                          ),
                        ),
                      ],
                    ),
                    // Small participant dots
                    Row(
                      children: List.generate(
                        sidequest.maxPeople.clamp(0, 5),
                        (i) => Container(
                          width: 14,
                          height: 14,
                          margin: const EdgeInsets.only(right: 2),
                          decoration: BoxDecoration(
                            color: i < sidequest.participantCount
                                ? _accentColor.withOpacity(0.7)
                                : _accentColor.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTag(String text, Color bgColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        text,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Icon(icon, size: 15, color: Colors.black45),
          const SizedBox(width: 8),
          Text(
            text,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }
}
