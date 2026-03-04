import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../services/authenticated_api_service.dart';
import '../widgets/sidequest_card.dart';
import 'sidequest_detail_screen.dart';

// ─── Data Model ──────────────────────────────────────────────────────────────

class SidequestItem {
  final int id;
  final String title;
  final String description;
  final String creatorUsername;
  final String creatorFirstName; // new
  final String vibe;
  final String status;
  final DateTime eventDatetime;
  final DateTime? endDatetime;
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
    required this.creatorFirstName, // new
    required this.vibe,
    required this.status,
    required this.eventDatetime,
    this.endDatetime,
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
      creatorFirstName: json['creator']?['first_name']?.isNotEmpty == true
          ? json['creator']['first_name']
          : (json['creator']?['username'] ?? 'friend'),
      vibe: json['vibe'] ?? 'chill',
      status: json['status'] ?? 'upcoming',
      eventDatetime: DateTime.parse(json['event_datetime']),
      endDatetime: json['end_datetime'] != null ? DateTime.parse(json['end_datetime']) : null,
      location: json['location'] ?? 'Location TBD',
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
  
  // Date navigation state
  late DateTime _selectedDate;

  @override
  void initState() {
    super.initState();
    // Start with today at midnight
    final now = DateTime.now();
    _selectedDate = DateTime(now.year, now.month, now.day);
    _fetchSidequests();
  }

  void _changeDate(int offsetDays) {
    setState(() {
      _selectedDate = DateTime(
        _selectedDate.year,
        _selectedDate.month,
        _selectedDate.day + offsetDays,
      );
    });
  }

  String _getDateDisplayText() {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final tomorrow = today.add(const Duration(days: 1));
    final yesterday = today.subtract(const Duration(days: 1));

    if (_selectedDate == today) return 'Today';
    if (_selectedDate == tomorrow) return 'Tomorrow';
    if (_selectedDate == yesterday) return 'Yesterday';

    return DateFormat('MMM d').format(_selectedDate);
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
    return _allSidequests.where((sq) {
      // Check if event is on the selected date (local time)
      final eventLocal = sq.eventDatetime.toLocal();
      final eventDate = DateTime(eventLocal.year, eventLocal.month, eventLocal.day);
      return eventDate == _selectedDate;
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
                                const Icon(Icons.add, color: Colors.black, size: 28),
                                Image.asset(
                                  'assets/images/plotd-title.png',
                                  height: 32,
                                ),
                                const Icon(Icons.notifications_outlined, color: Colors.black, size: 28),
                              ],
                            ),
                            const SizedBox(height: 32),

                            // ── Date Navigation ──
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                IconButton(
                                  onPressed: () => _changeDate(-1),
                                  icon: const Icon(Icons.arrow_back_ios, size: 18, color: Color(0xFF888888)),
                                ),
                                const SizedBox(width: 8),
                                SizedBox(
                                  width: 140,
                                  child: Text(
                                    _getDateDisplayText(),
                                    textAlign: TextAlign.center,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w800,
                                      color: const Color(0xFF1E1E1E),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  onPressed: () => _changeDate(1),
                                  icon: const Icon(Icons.arrow_forward_ios, size: 18, color: Color(0xFF1E1E1E)),
                                ),
                              ],
                            ),
                            const SizedBox(height: 24),

                            // ── Quest Cards ──
                            if (_filteredSidequests.isEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 60),
                                child: Center(
                                  child: Column(
                                    children: [
                                      Image.asset('assets/images/asterik.png', width: 48, color: const Color(0xFF1E1E1E)),
                                      const SizedBox(height: 12),
                                      Text(
                                        'No quests on this day',
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.black54,
                                        ),
                                      ),
                                      const SizedBox(height: 6),
                                      Text(
                                        'Swipe back or check tomorrow!',
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
                                SidequestType type = SidequestType.own;
                                if (sq.isFriendsOnly) type = SidequestType.friend;
                                if (sq.isPublic) type = SidequestType.community;

                                return Padding(
                                  padding: const EdgeInsets.only(bottom: 16),
                                  child: SidequestCard(
                                    creatorName: sq.isOwn ? 'You' : sq.creatorFirstName,
                                    creatorUsername: sq.isOwn ? 'you' : sq.creatorUsername,
                                    title: sq.title,
                                    eventDatetime: sq.eventDatetime,
                                    location: sq.location,
                                    type: type,
                                    onTap: () {
                                      Navigator.push(
                                        context,
                                        MaterialPageRoute(
                                          builder: (context) => SidequestDetailScreen(sidequestId: sq.id),
                                        ),
                                      ).then((_) {
                                        // Reload the feed when returning to pick up any joins/leaves
                                        _fetchSidequests();
                                      });
                                    }
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


