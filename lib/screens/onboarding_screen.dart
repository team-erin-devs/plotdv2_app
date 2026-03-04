import 'package:flutter/material.dart';
import 'dart:convert';
import '../services/authenticated_api_service.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;
  static const int _totalPages = 3;
  bool _isLoading = false;

  // Selections for each page
  final Set<String> _page1Selections = {};
  final Set<String> _page2Selections = {};
  final Set<String> _page3Selections = {};

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _goToNext() {
    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _finish();
    }
  }

  void _goBack() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _finish() async {
    setState(() => _isLoading = true);

    try {
      if (_page3Selections.isNotEmpty) {
        final List<Map<String, String>> interestsPayload = [];
        
        for (final selection in _page3Selections) {
          final parts = selection.split(':');
          if (parts.length == 2) {
             // We need emoji. We have 'category:label' in the key.
             // We must reverse-lookup the emoji, or re-structure how we save it.
             // Actually, letting string matching handle it below:
          }
        }
        
        // Let's iterate all categories to find the matching emoji for the selected labels
        // because the key is "category:label", the option 2 is label.
        final categories = <String, List<(String, String)>>{
          'arts': [('🎨', 'art'), ('📚', 'reading'), ('📸', 'photography'), ('🧩', 'puzzles')],
          'entertainments': [('🎤', 'karaoke'), ('🎵', 'concerts'), ('🎬', 'movie/ tv series')],
          'food & drinks': [('☕', 'coffee'), ('🍻', 'bar crawls'), ('🍲', 'hotpot'), ('🧋', 'bubble tea'), ('🥗', 'healthy meal prep')],
          'sports': [('🏋️', 'gym'), ('🧘', 'yoga'), ('🏃', 'run club'), ('🏀', 'basketball'), ('🏐', 'volleyball'), ('🥾', 'hiking'), ('🧗', 'climbing')],
        };
        
        for (final selection in _page3Selections) {
           final parts = selection.split(':');
           if (parts.length == 2) {
              final cat = parts[0];
              final label = parts[1];
              final options = categories[cat];
              if (options != null) {
                 final match = options.where((o) => o.$2 == label).firstOrNull;
                 if (match != null) {
                    interestsPayload.add({
                       'emoji': match.$1,
                       'label': match.$2,
                    });
                 }
              }
           }
        }

        await AuthenticatedApiService.authenticatedPatch(
          '/api/user/profile/',
          {'interests': interestsPayload},
        );
      }
    } catch (e) {
      debugPrint('Error saving onboarding data: $e');
    }

    if (mounted) {
      setState(() => _isLoading = false);
      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // ── Top bar: back, progress, skip ──
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              child: Row(
                children: [
                  // Back arrow
                  GestureDetector(
                    onTap: _currentPage > 0 ? _goBack : null,
                    child: Icon(
                      Icons.arrow_back,
                      color: _currentPage > 0
                          ? const Color(0xFF1A1A1A)
                          : Colors.grey[300],
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),

                  // Progress bar
                  Expanded(child: _buildProgressBar()),

                  const SizedBox(width: 12),

                  // Skip
                  GestureDetector(
                    onTap: _finish,
                    child: const Text(
                      'Skip',
                      style: TextStyle(
                        fontFamily: 'Urbanist',
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFF28B82),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── Pages ──
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (i) => setState(() => _currentPage = i),
                children: [
                  _buildPage1(),
                  _buildPage2(),
                  _buildPage3(),
                ],
              ),
            ),

            // ── Continue button ──
            Padding(
              padding: const EdgeInsets.fromLTRB(32, 8, 32, 24),
              child: GestureDetector(
                onTap: _goToNext,
                child: Container(
                  width: double.infinity,
                  height: 52,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(28),
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFFF5C542),
                        Color(0xFFF2A6A2),
                        Color(0xFFA8A0C8),
                      ],
                    ),
                  ),
                  child: Center(
                    child: _isLoading 
                      ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text(
                          _currentPage < _totalPages - 1 ? 'Continue' : 'Get Started',
                          style: const TextStyle(
                            fontFamily: 'Urbanist',
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Progress bar ──
  Widget _buildProgressBar() {
    return SizedBox(
      height: 5,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(3),
        child: LinearProgressIndicator(
          value: (_currentPage + 1) / _totalPages,
          backgroundColor: const Color(0xFFE8E8E8),
          valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFF28B82)),
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════
  // PAGE 1: What brings you to Plotd?
  // ══════════════════════════════════════════════
  Widget _buildPage1() {
    final options = [
      ('🎉', 'plan events'),
      ('👀', 'join spontaneous plans'),
      ('🤝', 'meet new people'),
      ('🎨', 'explore hobbies'),
      ('🏃', 'be more active'),
    ];

    return _buildQuestionPage(
      title: 'What brings you to\nPlotd?',
      options: options,
      selections: _page1Selections,
    );
  }

  // ══════════════════════════════════════════════
  // PAGE 2: What kind of sidequests are you into?
  // ══════════════════════════════════════════════
  Widget _buildPage2() {
    final options = [
      ('⚡', 'spontaneous & chaotic'),
      ('📅', 'planned & organized'),
      ('🎨', 'creative & chill'),
      ('🍫', 'social & vibey'),
      ('🧘', 'low-key & cozy'),
      ('🏔️', 'adventurous'),
    ];

    return _buildQuestionPage(
      title: 'What kind of sidequests\nare you into?',
      options: options,
      selections: _page2Selections,
    );
  }

  // ══════════════════════════════════════════════
  // PAGE 3: Interests
  // ══════════════════════════════════════════════
  Widget _buildPage3() {
    final categories = <String, List<(String, String)>>{
      'arts': [
        ('🎨', 'art'),
        ('📚', 'reading'),
        ('📸', 'photography'),
        ('🧩', 'puzzles'),
      ],
      'entertainments': [
        ('🎤', 'karaoke'),
        ('🎵', 'concerts'),
        ('🎬', 'movie/ tv series'),
      ],
      'food & drinks': [
        ('☕', 'coffee'),
        ('🍻', 'bar crawls'),
        ('🍲', 'hotpot'),
        ('🧋', 'bubble tea'),
        ('🥗', 'healthy meal prep'),
      ],
      'sports': [
        ('🏋️', 'gym'),
        ('🧘', 'yoga'),
        ('🏃', 'run club'),
        ('🏀', 'basketball'),
        ('🏐', 'volleyball'),
        ('🥾', 'hiking'),
        ('🧗', 'climbing'),
      ],
    };

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          const Text(
            'Want to get to know\nmore about you!',
            style: TextStyle(
              fontFamily: 'Urbanist',
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1A1A1A),
              height: 1.2,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'what are your interests? 20 max.',
            style: TextStyle(
              fontFamily: 'Urbanist',
              fontSize: 14,
              fontWeight: FontWeight.w400,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 16),

          // + add your own
          GestureDetector(
            onTap: () {
              // Placeholder — no action for now
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: const Color(0xFFE0E0E0), width: 1.5),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add, size: 18, color: Color(0xFF1A1A1A)),
                  SizedBox(width: 4),
                  Text(
                    'add your own',
                    style: TextStyle(
                      fontFamily: 'Urbanist',
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Color(0xFF1A1A1A),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          // Categories
          ...categories.entries.map((entry) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.key,
                  style: const TextStyle(
                    fontFamily: 'Urbanist',
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF1A1A1A),
                  ),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: entry.value.map((item) {
                    final key = '${entry.key}:${item.$2}';
                    final selected = _page3Selections.contains(key);
                    return GestureDetector(
                      onTap: () {
                        setState(() {
                          if (selected) {
                            _page3Selections.remove(key);
                          } else if (_page3Selections.length < 20) {
                            _page3Selections.add(key);
                          }
                        });
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: selected
                              ? const Color(0xFFFDE4E1)
                              : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: selected
                                ? const Color(0xFFF28B82)
                                : const Color(0xFFE0E0E0),
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(item.$1, style: const TextStyle(fontSize: 16)),
                            const SizedBox(width: 4),
                            Text(
                              item.$2,
                              style: TextStyle(
                                fontFamily: 'Urbanist',
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: selected
                                    ? const Color(0xFFF28B82)
                                    : const Color(0xFF1A1A1A),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 20),
              ],
            );
          }),

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  // ── Shared question page builder (Pages 1 & 2) ──
  Widget _buildQuestionPage({
    required String title,
    required List<(String, String)> options,
    required Set<String> selections,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Text(
            title,
            style: const TextStyle(
              fontFamily: 'Urbanist',
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: Color(0xFF1A1A1A),
              height: 1.2,
            ),
          ),
          const SizedBox(height: 28),
          ...options.map((opt) {
            final selected = selections.contains(opt.$2);
            return Padding(
              padding: const EdgeInsets.only(bottom: 14),
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    if (selected) {
                      selections.remove(opt.$2);
                    } else {
                      selections.add(opt.$2);
                    }
                  });
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 14,
                  ),
                  decoration: BoxDecoration(
                    color: selected
                        ? const Color(0xFFFDE4E1)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: selected
                          ? const Color(0xFFF28B82)
                          : const Color(0xFFE0E0E0),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(opt.$1, style: const TextStyle(fontSize: 18)),
                      const SizedBox(width: 8),
                      Text(
                        opt.$2,
                        style: TextStyle(
                          fontFamily: 'Urbanist',
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: selected
                              ? const Color(0xFFF28B82)
                              : const Color(0xFF1A1A1A),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}
