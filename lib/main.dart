import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:team_erin_app/screens/home_screen.dart';
import 'package:team_erin_app/screens/challenges_screen.dart';
import 'package:team_erin_app/screens/leaderboard_screen.dart';
import 'package:team_erin_app/screens/ranking_screen.dart';
import 'package:team_erin_app/screens/login_screen.dart';
import 'package:team_erin_app/screens/register_screen.dart';
import 'package:team_erin_app/screens/profile_screen.dart';
import 'package:team_erin_app/screens/welcome_screen.dart';
import 'package:team_erin_app/screens/intro_video_screen.dart';
import 'package:team_erin_app/widgets/auth_guard.dart';
import 'package:team_erin_app/screens/edit_sidequest_screen.dart';
import 'package:team_erin_app/screens/sidequest_confirmation_screen.dart';
import 'services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final bool loggedIn = await AuthService.isAuthenticated();

  runApp(MyApp(loggedIn: loggedIn));
}

class MyApp extends StatelessWidget {
  final bool loggedIn;

  const MyApp({super.key, required this.loggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Challenge App',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: Colors.black,
        canvasColor: Colors.black,
        cardColor: Colors.black,
        colorScheme: const ColorScheme.dark(
          surface: Colors.black,
          primary: Colors.white,
          secondary: Colors.grey,
        ),
        textTheme: TextTheme(
          headlineLarge: TextStyle(fontSize: 16, color: Colors.white),
          bodyMedium: TextStyle(fontSize: 14, color: Colors.white70),
        ),
        useMaterial3: false, // retro vibe
      ),
      home: const IntroVideoWrapper(),
      routes: {
        '/auth': (context) => const AuthSplashScreen(),
        '/welcome': (context) => const WelcomeScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/home': (context) => AuthGuard(child: const MainNavigation()),
        '/challenges': (context) => AuthGuard(child: const ChallengesScreen()),
        '/challenges/detail': (context) => AuthGuard(child: const ChallengesScreen()),
        '/sidequest-confirmation': (context) => const SidequestConfirmationScreen(),
      },
    );
  }
}

class AuthSplashScreen extends StatefulWidget {
  const AuthSplashScreen({super.key});

  @override
  State<AuthSplashScreen> createState() => _AuthSplashScreenState();
}

class _AuthSplashScreenState extends State<AuthSplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkAuthAndNavigate();
  }

  Future<void> _checkAuthAndNavigate() async {
    final isAuth = await AuthService.isAuthenticated();
    
    if (!mounted) return;
    
    if (isAuth) {
      Navigator.of(context).pushReplacementNamed('/home');
    } else {
      Navigator.of(context).pushReplacementNamed('/welcome');
    }
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: CircularProgressIndicator(color: Colors.white),
      ),
    );
  }
}

// Main Navigation with Bottom Nav Bar
class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const HomeScreen(), // 0 = Home
    const ChallengesScreen(), // 1 = Missions
    const EditSidequestScreen(), // 2 = Sidequests
    const LeaderboardScreen(), // 3 = Ranking
    const ProfileScreen(), // 4 = Profile
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(
              'assets/images/retro game - profile_ what others see.png',
            ),
            fit: BoxFit.fitWidth,
          ),
        ),
        child: _pages[_selectedIndex],
      ),
      bottomNavigationBar: _NeoBottomNavBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        items: const [
          _NeoNavItem(icon: Icons.home_rounded, label: 'Home'),
          _NeoNavItem(icon: Icons.flag_circle_rounded, label: 'Missions'),
          _NeoNavItem(icon: Icons.explore_rounded, label: 'Sidequests'),
          _NeoNavItem(icon: Icons.bar_chart_rounded, label: 'Ranking'),
          _NeoNavItem(icon: Icons.person_rounded, label: 'Profile'),
        ],
      ),
    );
  }
}

class _NeoBottomNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<_NeoNavItem> items;

  const _NeoBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTap,
    required this.items,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF0B0B0B),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.4),
              blurRadius: 12,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Row(
          children: List.generate(items.length, (i) {
            final selected = i == currentIndex;
            final color = selected ? Colors.white : const Color(0xFF8E8E93);

            return Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => onTap(i),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(items[i].icon, size: 26, color: color),
                      const SizedBox(height: 6),
                      Text(
                        items[i].label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: color,
                          letterSpacing: 0.1,
                        ),
                      ),
                      const SizedBox(height: 6),
                      AnimatedOpacity(
                        opacity: selected ? 1 : 0,
                        duration: const Duration(milliseconds: 180),
                        child: Container(
                          width: 18,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }
}

class _NeoNavItem {
  final IconData icon;
  final String label;
  const _NeoNavItem({required this.icon, required this.label});
}
