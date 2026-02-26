import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        await _authService.login(
          username: _usernameController.text.trim(),
          password: _passwordController.text,
        );
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/home');
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(e.toString()),
              backgroundColor: Colors.red[400],
            ),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 60),

                // Header
                const Text(
                  'Welcome Back',
                  style: TextStyle(
                    fontFamily: 'Urbanist',
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1A1A1A),
                    letterSpacing: -0.5,
                  ),
                ),

                const SizedBox(height: 48),

                // Username
                _buildField(
                  label: 'Username',
                  hint: 'ex. username123',
                  controller: _usernameController,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Username is required';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 32),

                // Password
                _buildField(
                  label: 'Password',
                  controller: _passwordController,
                  isPassword: true,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Password is required';
                    return null;
                  },
                ),

                const Spacer(),

                // Login button
                GestureDetector(
                  onTap: _isLoading ? null : _handleLogin,
                  child: Container(
                    width: double.infinity,
                    height: 56,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(30),
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
                          ? const SizedBox(
                              width: 24,
                              height: 24,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: Colors.white,
                              ),
                            )
                          : const Text(
                              'Log In',
                              style: TextStyle(
                                fontFamily: 'Urbanist',
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                                letterSpacing: -0.3,
                              ),
                            ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                // Don't have an account? Register
                Center(
                  child: RichText(
                    text: TextSpan(
                      style: const TextStyle(
                        fontFamily: 'Urbanist',
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: Color(0xFF888888),
                      ),
                      children: [
                        const TextSpan(text: "Don't have an account?  "),
                        TextSpan(
                          text: 'Register',
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF333333),
                            decoration: TextDecoration.underline,
                          ),
                          recognizer: TapGestureRecognizer()
                            ..onTap = () {
                              Navigator.pushReplacementNamed(context, '/register');
                            },
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 48),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required String label,
    String? hint,
    required TextEditingController controller,
    bool isPassword = false,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Urbanist',
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: Color(0xFF1A1A1A),
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          obscureText: isPassword,
          style: const TextStyle(
            fontFamily: 'Urbanist',
            fontSize: 16,
            fontWeight: FontWeight.w400,
            color: Color(0xFF1A1A1A),
          ),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              fontFamily: 'Urbanist',
              fontSize: 16,
              fontWeight: FontWeight.w400,
              color: Colors.grey[400],
            ),
            isDense: true,
            contentPadding: const EdgeInsets.only(bottom: 10, top: 4),
            enabledBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xFFE0E0E0), width: 1.5),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Color(0xFFF2A6A2), width: 2),
            ),
            errorBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.red, width: 1.5),
            ),
            focusedErrorBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.red, width: 2),
            ),
          ),
          validator: validator,
        ),
        if (hint != null) ...[
          const SizedBox(height: 4),
          Text(
            hint,
            style: TextStyle(
              fontFamily: 'Urbanist',
              fontSize: 12,
              fontWeight: FontWeight.w400,
              color: Colors.grey[400],
            ),
          ),
        ],
      ],
    );
  }
}