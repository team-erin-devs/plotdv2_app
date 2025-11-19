import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:team_erin_app/widgets/missions_carousel.dart';
import 'package:team_erin_app/widgets/leaderboard_section.dart';


class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

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
              const _HeaderSection(),
              const SizedBox(height: 32),
              const Text(
                'Your missions for the week...',
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
  const _HeaderSection();

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
        ShaderMask(
          shaderCallback: (bounds) => const LinearGradient(
            colors: [Color(0xFF23B2CA), Color(0xFFA621ED), Color(0xFFED2190)],
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
          ).createShader(bounds),
          child: const Text(
            '24d 12h 19m',
            style: TextStyle(
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
