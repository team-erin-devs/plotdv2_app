import 'package:flutter/material.dart';
import '../models/challenge.dart';
import '../models/user_profile.dart';
import '../services/api_service.dart';
import '../widgets/mission_card.dart';

class ChallengesScreen extends StatefulWidget {
  const ChallengesScreen({super.key});

  @override
  State<ChallengesScreen> createState() => _ChallengesScreenState();
}

class _ChallengesScreenState extends State<ChallengesScreen> {
  late Future<List<Challenge>> _challengesFuture;
  late Future<UserProfile> _userFuture;

  @override
  void initState() {
    super.initState();
    _challengesFuture = ApiService.fetchChallenge();
    _userFuture = ApiService.fetchUserProfile();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: FutureBuilder<UserProfile>(
          future: _userFuture,
          builder: (context, userSnap) {
            if (userSnap.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: Colors.white));
            }
            if (userSnap.hasError || !userSnap.hasData) {
              return Center(
                child: Text(
                  'Failed to load user info',
                  style: TextStyle(color: Colors.red.shade300),
                ),
              );
            }

            final userProfile = userSnap.data!;

            return FutureBuilder<List<Challenge>>(
              future: _challengesFuture,
              builder: (context, challengeSnap) {
                if (challengeSnap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Colors.white));
                }
                if (challengeSnap.hasError) {
                  return Center(
                    child: Text('Failed to load missions',
                        style: TextStyle(color: Colors.red.shade300)),
                  );
                }

                final challenges = challengeSnap.data ?? [];
                if (challenges.isEmpty) {
                  return const Center(
                    child: Text(
                      'No missions available right now',
                      style: TextStyle(color: Colors.white70),
                    ),
                  );
                }

                return SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 30),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // 👤 Username header
                      Text(
                        'Welcome, ${userProfile.user.username}',
                        style: const TextStyle(
                          fontFamily: 'Urbanist',
                          fontWeight: FontWeight.w700,
                          fontSize: 26,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'You have ${challenges.length} missions remaining this week',
                        style: TextStyle(
                          fontFamily: 'Urbanist',
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                          color: Colors.white.withOpacity(0.8),
                        ),
                      ),
                      const SizedBox(height: 30),

                      // 🪪 Mission cards list
                      Column(
                        children: challenges.map((c) {
                          // Pick color gradient by difficulty
                          List<Color> gradient;
                          switch (c.difficulty.toString().toLowerCase()) {
                            case 'hard':
                              gradient = [const Color(0xFFED2190), const Color(0xFF871352)];
                              break;
                            case 'medium':
                              gradient = [const Color(0xFFA621ED), const Color(0xFF5E1387)];
                              break;
                            default:
                              gradient = [const Color(0xFF23B2CA), const Color(0xFF126C87)];
                          }

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 22),
                            child: MissionCard(
                              title: c.title,
                              difficulty: c.difficulty,
                              gradient: gradient,
                              points: c.points,
                              challenge: c,
                              // timeRemaining: c.timeRemaining ?? 'N/A',
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}