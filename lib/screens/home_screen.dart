import 'dart:convert';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../services/authenticated_api_service.dart';
import '../widgets/sidequest_card.dart';
import 'sidequest_detail_screen.dart';

// ─── Sidequest model ─────────────────────────────────────────────────────────

class _HomeSidequest {
  final int id;
  final String title;
  final String creatorFirstName;
  final String creatorUsername;
  final String vibe;
  final DateTime eventDatetime;
  final String location;
  final int participantCount;
  final int maxPeople;
  final String? userStatus;
  final bool postToCampusBoard;

  _HomeSidequest({
    required this.id,
    required this.title,
    required this.creatorFirstName,
    required this.creatorUsername,
    required this.vibe,
    required this.eventDatetime,
    required this.location,
    required this.participantCount,
    required this.maxPeople,
    this.userStatus,
    required this.postToCampusBoard,
  });

  factory _HomeSidequest.fromJson(Map<String, dynamic> json) {
    return _HomeSidequest(
      id: json['id'],
      title: json['title'] ?? '',
      creatorFirstName: json['creator']?['first_name']?.isNotEmpty == true
          ? json['creator']['first_name']
          : (json['creator']?['username'] ?? 'friend'),
      creatorUsername: json['creator']?['username'] ?? 'unknown',
      vibe: json['vibe'] ?? 'chill',
      eventDatetime: DateTime.parse(json['event_datetime']),
      location: json['location'] ?? 'Location TBD',
      participantCount: json['participant_count'] ?? 0,
      maxPeople: json['max_people'] ?? 5,
      userStatus: json['user_status'],
      postToCampusBoard: json['post_to_campus_board'] ?? false,
    );
  }

  bool get isOwn => userStatus == 'creator';
  bool get isFriend => !isOwn && !postToCampusBoard;
  bool get isPublic => postToCampusBoard && !isOwn;
}

// ─── Sidequest idea templates ────────────────────────────────────────────────

final List<Map<String, String>> _sidequestIdeas = [
  {'title': 'coffee run and study session', 'vibe': 'productive'},
  {'title': 'sunset walk at the park', 'vibe': 'chill'},
  {'title': 'pickup basketball game', 'vibe': 'active'},
  {'title': 'boba and board games', 'vibe': 'social'},
  {'title': 'late night ramen run', 'vibe': 'fun'},
  {'title': 'morning yoga on the quad', 'vibe': 'active'},
  {'title': 'thrift shopping trip', 'vibe': 'fun'},
  {'title': 'group cooking night', 'vibe': 'social'},
];

// ─── Home Screen ─────────────────────────────────────────────────────────────

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _firstName;
  String? _username;
  List<_HomeSidequest> _activeQuests = [];
  bool _isLoading = true;
  late final PageController _carouselCtrl;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _carouselCtrl = PageController(viewportFraction: 0.65, initialPage: 0);
    _loadData();
  }

  @override
  void dispose() {
    _carouselCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      // Fetch profile
      try {
        final profileRes = await AuthenticatedApiService.authenticatedGet('/api/user/profile/');
        if (profileRes.statusCode == 200) {
          final data = jsonDecode(profileRes.body);
          _firstName = data['user']?['first_name'];
          _username = data['user']?['username'];
          if (_firstName == null || _firstName!.isEmpty) _firstName = _username;
        }
      } catch (_) {}

      // Fetch my created + joined quests
      final List<_HomeSidequest> allQuests = [];
      final Set<int> seenIds = {};

      try {
        final mineRes = await AuthenticatedApiService.authenticatedGet('/api/sidequests/mine/');
        if (mineRes.statusCode == 200) {
          for (final item in jsonDecode(mineRes.body)) {
            final sq = _HomeSidequest.fromJson(item);
            if (seenIds.add(sq.id)) allQuests.add(sq);
          }
        }
      } catch (_) {}

      try {
        final joinedRes = await AuthenticatedApiService.authenticatedGet('/api/sidequests/joined/');
        if (joinedRes.statusCode == 200) {
          for (final item in jsonDecode(joinedRes.body)) {
            final sq = _HomeSidequest.fromJson(item);
            if (seenIds.add(sq.id)) allQuests.add(sq);
          }
        }
      } catch (_) {}

      allQuests.sort((a, b) => a.eventDatetime.compareTo(b.eventDatetime));

      setState(() {
        _activeQuests = allQuests;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
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
                  onRefresh: _loadData,
                  color: const Color(0xFFE8837C),
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Plotd Header ──
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

                        // ── Greeting ──
                        Text(
                          'Hi ${_firstName ?? 'friend'}!',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: const Color(0xFF888888),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              'Today\'s quests',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 26,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF1E1E1E),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(bottom: 4),
                              child: Text(
                                'See All',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: const Color(0xFF888888),
                                  decoration: TextDecoration.underline,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 20),

                        // ── Active Quest Cards ──
                        if (_activeQuests.isEmpty)
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(28),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(color: const Color(0xFFE8E0D8)),
                            ),
                            child: Column(
                              children: [
                                Image.asset('assets/images/asterik.png', width: 36, color: const Color(0xFFE8837C)),
                                const SizedBox(height: 10),
                                Text(
                                  'no active quests!',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.black54,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'join or post one below',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.black38,
                                  ),
                                ),
                              ],
                            ),
                          )
                        else
                          ..._activeQuests.map((sq) {
                            SidequestType type = SidequestType.own;
                            if (sq.isFriend) type = SidequestType.friend;
                            if (sq.isPublic) type = SidequestType.community;

                            return Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: SidequestCard(
                                creatorName: sq.isOwn ? (_firstName ?? 'You') : sq.creatorFirstName,
                                creatorUsername: sq.isOwn ? (_username ?? 'you') : sq.creatorUsername,
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
                                  );
                                },
                              ),
                            );
                          }),

                        const SizedBox(height: 40),

                        // ── Inspo Section ──
                        Center(
                          child: Text(
                            'Wanna host a sidequest?',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 22,
                              fontWeight: FontWeight.w800,
                              color: Colors.black,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Center(
                          child: Text(
                            'Here\'s some inspo',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: Colors.black45,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),

                        // ── Carousel ──
                        SizedBox(
                          height: 200,
                          child: PageView.builder(
                            controller: _carouselCtrl,
                            padEnds: true,
                            physics: const BouncingScrollPhysics(),
                            itemCount: _sidequestIdeas.length,
                            onPageChanged: (i) => setState(() => _currentPage = i),
                            itemBuilder: (context, index) {
                              final idea = _sidequestIdeas[index];
                              return AnimatedBuilder(
                                animation: _carouselCtrl,
                                builder: (_, __) {
                                  double t = 0;
                                  if (_carouselCtrl.position.haveDimensions) {
                                    final page = _carouselCtrl.page ?? 0;
                                    t = (page - index).abs();
                                  }
                                  final scale = (1 - (t * 0.12)).clamp(0.88, 1.0);
                                  final opacity = (1 - (t * 0.3)).clamp(0.5, 1.0);

                                  return Transform.scale(
                                    scale: scale,
                                    child: Opacity(
                                      opacity: opacity,
                                      child: _InspoCard(
                                        title: idea['title']!,
                                        vibe: idea['vibe']!,
                                      ),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 14),

                        // ── Page Dots ──
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: List.generate(
                            _sidequestIdeas.length.clamp(0, 6),
                            (i) => Container(
                              width: i == _currentPage ? 10 : 7,
                              height: i == _currentPage ? 10 : 7,
                              margin: const EdgeInsets.symmetric(horizontal: 3),
                              decoration: BoxDecoration(
                                color: i == _currentPage
                                    ? const Color(0xFF455A64)
                                    : const Color(0xFFD0D0D0),
                                shape: BoxShape.circle,
                              ),
                            ),
                          ),
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
}

// ─── Inspo Card ──────────────────────────────────────────────────────────────

class _InspoCard extends StatelessWidget {
  final String title;
  final String vibe;

  const _InspoCard({required this.title, required this.vibe});

  @override
  Widget build(BuildContext context) {
    // Capitalize first letter
    final displayTitle = title.isNotEmpty 
        ? '${title[0].toUpperCase()}${title.substring(1)}' 
        : title;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 6),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFFFDE08B),
          width: 3.0,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            displayTitle,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF1E1E1E),
              height: 1.2,
            ),
          ),
          const Spacer(),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('tap the Post tab to create this quest!',
                        style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600)),
                    backgroundColor: const Color(0xFF455A64),
                    behavior: SnackBarBehavior.floating,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFFFB300),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              child: Text(
                'Create Sidequest',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

