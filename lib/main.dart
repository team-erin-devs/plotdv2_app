import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:team_erin_app/screens/home_screen.dart';
import 'package:team_erin_app/screens/sidequest_feed_screen.dart';
import 'package:team_erin_app/screens/leaderboard_screen.dart';
import 'package:team_erin_app/screens/ranking_screen.dart';
import 'package:team_erin_app/screens/login_screen.dart';
import 'package:team_erin_app/screens/register_screen.dart';
import 'package:team_erin_app/screens/profile_screen.dart';
import 'package:team_erin_app/screens/welcome_screen.dart';
import 'package:team_erin_app/screens/onboarding_screen.dart';
import 'package:team_erin_app/screens/search_screen.dart';
import 'package:team_erin_app/widgets/auth_guard.dart';
import 'package:team_erin_app/screens/post_sidequest_screen.dart';
import 'services/auth_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

// GLOBAL KEY HERE
final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");

  final bool loggedIn = await AuthService.isAuthenticated();

  runApp(MyApp(loggedIn: loggedIn));
}

class MyApp extends StatelessWidget {
  final bool loggedIn;

  const MyApp({super.key, required this.loggedIn});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
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
      home: const WelcomeScreen(),
      routes: {
        '/welcome': (context) => const WelcomeScreen(),
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/onboarding': (context) => const OnboardingScreen(),
        '/home': (context) => AuthGuard(child: const MainNavigation()),
      },
    );
  }
}

// Auth check is now handled inside WelcomeScreen

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
    const SidequestFeedScreen(), // 1 = Feed
    const PostSidequestScreen(), // 2 = Sidequests
    const SearchScreen(), // 3 = Search
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
          _NeoNavItem(icon: Icons.home_outlined, label: 'Home'),
          _NeoNavItem(icon: Icons.local_activity_outlined, label: 'Quests'),
          _NeoNavItem(icon: Icons.add, label: 'Create'),
          _NeoNavItem(icon: Icons.search_rounded, label: 'Search'),
          _NeoNavItem(icon: Icons.person_outline_rounded, label: 'Profile'),
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
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: const BoxDecoration(
          color: Colors.white,
          border: Border(top: BorderSide(color: Color(0xFFE8E0D8))),
        ),
        child: Row(
          children: List.generate(items.length, (i) {
            final selected = i == currentIndex;
            final color = selected ? const Color(0xFF2D2D2D) : const Color(0xFF9E9E9E);

            return Expanded(
              child: InkWell(
                borderRadius: BorderRadius.circular(16),
                onTap: () => onTap(i),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(items[i].icon, size: selected ? 28 : 26, color: color),
                      const SizedBox(height: 4),
                      Text(
                        items[i].label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                          color: color,
                          letterSpacing: 0.1,
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
