import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:team_erin_app/widgets/missions_carousel.dart';
import 'package:team_erin_app/widgets/leaderboard_section.dart';
import 'package:team_erin_app/services/api_service.dart';
import 'package:team_erin_app/models/season.dart';


class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Season? _season;
  bool _isLoading = true;
  String? _errorMessage;
  Timer? _countdownTimer;
  double _localTimeRemaining = 0;

  @override
  void initState() {
    super.initState();
    _loadSeason();
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadSeason() async {
    try {
      print('🟢 Starting to fetch season...');
      final season = await ApiService.fetchSeason();
      print('🟢 Season fetched successfully!');
      print('🟢 Season name: ${season.name}');
      print('🟢 Time remaining: ${season.timeRemaining}');
      print('🟢 End date: ${season.endDate}');
      
      setState(() {
        _season = season;
        _localTimeRemaining = season.timeRemaining;
        _isLoading = false;
        _errorMessage = null;
      });
      _startCountdown();
    } catch (e, stackTrace) {
      print('🔴 Error fetching season: $e');
      print('🔴 Stack trace: $stackTrace');
      
      // Check if it's a 500 error (season ended) or a real error
      final errorString = e.toString();
      final is500Error = errorString.contains('500');
      
      setState(() {
        if (is500Error) {
          // Treat 500 as season ended
          _localTimeRemaining = 0;
          _errorMessage = null;
        } else {
          // Real error - show error message
          _errorMessage = errorString;
        }
        _isLoading = false;
      });
    }
  }

  void _startCountdown() {
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_localTimeRemaining > 0) {
        setState(() {
          _localTimeRemaining--;
        });
      } else {
        timer.cancel();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _HeaderSection(
                timeRemaining: _localTimeRemaining,
                isLoading: _isLoading,
                errorMessage: _errorMessage,
              ),
              const SizedBox(height: 32),
              const Text(
                'Your missions for the season...',
                style: TextStyle(
                  fontFamily: 'Epoch',
                  fontWeight: FontWeight.w700,
                  fontSize: 22,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 32),
              const MissionsCarousel(),
              const SizedBox(height: 32),
              const Text(
                'Current leaderboard',
                style: TextStyle(
                  fontFamily: 'Epoch',
                  fontWeight: FontWeight.w700,
                  fontSize: 22,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              const LeaderboardSection(),
            ],
          ),
        ),
      ),
    );
  }
}

class _HeaderSection extends StatelessWidget {
  final double timeRemaining;
  final bool isLoading;
  final String? errorMessage;

  const _HeaderSection({
    required this.timeRemaining,
    required this.isLoading,
    this.errorMessage,
  });

  String _getTimeRemaining() {
    if (timeRemaining <= 0) return 'Season ended';

    final duration = Duration(seconds: timeRemaining.toInt());
    final days = duration.inDays;
    final hours = duration.inHours % 24;
    final minutes = duration.inMinutes % 60;

    return '${days}d ${hours}h ${minutes}m';
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Welcome to Plotd',
          style: TextStyle(
            fontFamily: 'Epoch',
            fontSize: 28,
            fontWeight: FontWeight.w400,
            color: Colors.white,
            letterSpacing: -0.023,
          ),
        ),
        const SizedBox(height: 8),
        const Text(
          'Time remaining for the season...',
          style: TextStyle(
            fontFamily: 'Urbanist',
            fontSize: 16,
            fontWeight: FontWeight.w400,
            color: Color(0xFFACACAC),
          ),
        ),
        const SizedBox(height: 12),
        if (isLoading)
          const SizedBox(
            height: 80,
            child: Center(
              child: CircularProgressIndicator(
                color: Colors.white,
              ),
            ),
          )
        else if (errorMessage != null)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Error loading season',
                style: TextStyle(
                  fontFamily: 'Epoch',
                  fontSize: 24,
                  color: Colors.red.shade300,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                errorMessage!,
                style: const TextStyle(
                  fontFamily: 'Urbanist',
                  fontSize: 14,
                  color: Color(0xFFACACAC),
                ),
              ),
            ],
          )
        else
          ShaderMask(
            shaderCallback: (bounds) => const LinearGradient(
              colors: [Color(0xFF23B2CA), Color(0xFFA621ED), Color(0xFFED2190)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ).createShader(bounds),
            child: Text(
              _getTimeRemaining(),
              style: const TextStyle(
                fontFamily: 'Epoch',
                fontSize: 72,
                fontWeight: FontWeight.w400,
                height: 0.9,
                color: Colors.white,
                letterSpacing: -0.023 * 72,
              ),
            ),
          ),
      ],
    );
  }
}