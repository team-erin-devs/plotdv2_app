import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import '../services/auth_service.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen> {
  bool _checking = true;

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final isAuth = await AuthService.isAuthenticated();
    if (!mounted) return;
    if (isAuth) {
      Navigator.of(context).pushReplacementNamed('/home');
    } else {
      setState(() => _checking = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_checking) {
      return const Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 40),
          child: Column(
            children: [
              const Spacer(flex: 3),

              // ── Plotd* Logo ──
              Row(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // Yellow asterisk icon
                  Image.asset(
                    'assets/images/asterik.png',
                    width: 50,
                    color: const Color(0xFFF5C542),
                  ),
                  const SizedBox(width: 8),
                  // "Plotd" text
                  Text(
                    'Plotd',
                    style: TextStyle(
                      fontFamily: 'Urbanist',
                      fontSize: 52,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFFF5C5A3),
                      letterSpacing: -1,
                    ),
                  ),
                  // Smaller purple asterisk
                  Transform.translate(
                    offset: const Offset(2, -18),
                    child: Image.asset(
                      'assets/images/asterik.png',
                      width: 24,
                      color: const Color(0xFFA8A0C8),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              // Tagline
              Text(
                '*do it for the plot',
                style: TextStyle(
                  fontFamily: 'Urbanist',
                  fontSize: 16,
                  fontWeight: FontWeight.w500,
                  fontStyle: FontStyle.italic,
                  color: const Color(0xFFF5C5A3).withOpacity(0.7),
                  letterSpacing: 0.5,
                ),
              ),

              const Spacer(flex: 4),

              // ── Join Now! Button ──
              GestureDetector(
                onTap: () => Navigator.pushNamed(context, '/register'),
                child: Container(
                  width: double.infinity,
                  height: 56,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(width: 0),
                    gradient: const LinearGradient(
                      colors: [
                        Color(0xFFF5C542), // yellow
                        Color(0xFFF2A6A2), // pink
                        Color(0xFFA8A0C8), // blue/purple
                      ],
                    ),
                  ),
                  child: Container(
                    margin: const EdgeInsets.all(2.5),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      color: Colors.white,
                    ),
                    child: Center(
                      child: ShaderMask(
                        shaderCallback: (bounds) => const LinearGradient(
                          colors: [
                            Color(0xFFF5C542),
                            Color(0xFFF2A6A2),
                            Color(0xFFA8A0C8),
                          ],
                        ).createShader(bounds),
                        child: const Text(
                          'Join Now!',
                          style: TextStyle(
                            fontFamily: 'Urbanist',
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: Colors.white, // required for ShaderMask
                            letterSpacing: -0.3,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // ── Already have an account? Log In ──
              RichText(
                text: TextSpan(
                  style: const TextStyle(
                    fontFamily: 'Urbanist',
                    fontSize: 14,
                    fontWeight: FontWeight.w400,
                    color: Color(0xFF888888),
                  ),
                  children: [
                    const TextSpan(text: 'Already have an account?  '),
                    TextSpan(
                      text: 'Log In',
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF333333),
                        decoration: TextDecoration.underline,
                      ),
                      recognizer: TapGestureRecognizer()
                        ..onTap = () {
                          Navigator.pushNamed(context, '/login');
                        },
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 48),
            ],
          ),
        ),
      ),
    );
  }
}
