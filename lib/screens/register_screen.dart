import 'package:flutter/material.dart';
import 'package:flutter/gestures.dart';
import 'dart:convert';
import '../services/auth_service.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    final formState = _formKey.currentState;
    if (formState == null || !formState.validate()) return;

    setState(() => _isLoading = true);
    try {
      await _authService.register(
        username: _usernameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        name: _nameController.text.trim(),
      );
      if (mounted) {
        Navigator.pushReplacementNamed(context, '/onboarding');
      }
    } catch (e) {
      debugPrint('❌ Registration error: $e');
      if (mounted) {
        String msg = e.toString();
        if (msg.startsWith('Exception: ')) {
          msg = msg.substring(11);
        }
        if (msg.startsWith('Registration failed: ')) {
          final body = msg.substring(20);
          try {
            final parsed = Map<String, dynamic>.from(
                (const JsonDecoder()).convert(body) as Map);
            msg = parsed['error'] ?? body;
          } catch (_) {
            msg = body;
          }
        }
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(msg),
            backgroundColor: Colors.red[400],
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 60),

                // Header
                const Text(
                  'Create an Account',
                  style: TextStyle(
                    fontFamily: 'Urbanist',
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1A1A1A),
                    letterSpacing: -0.5,
                  ),
                ),

                const SizedBox(height: 40),

                // Name
                _buildField(
                  label: 'Name',
                  hint: 'ex. John Smith',
                  controller: _nameController,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Name is required';
                    return null;
                  },
                ),

                const SizedBox(height: 32),

                // Username
                _buildField(
                  label: 'Username',
                  hint: 'ex. username123',
                  controller: _usernameController,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Username is required';
                    if (v.trim().length < 3) return 'At least 3 characters';
                    return null;
                  },
                ),

                const SizedBox(height: 32),

                // Email
                _buildField(
                  label: 'Email',
                  hint: 'ex. johnsmith@email.com',
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Email is required';
                    if (!v.contains('@') || !v.contains('.')) return 'Enter a valid email';
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
                    if (v.length < 8) return 'At least 8 characters';
                    return null;
                  },
                ),

                const SizedBox(height: 32),

                // Confirm Password
                _buildField(
                  label: 'Confirm password',
                  controller: _confirmPasswordController,
                  isPassword: true,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Please confirm your password';
                    if (v != _passwordController.text) return 'Passwords do not match';
                    return null;
                  },
                ),

                const SizedBox(height: 12),

                // Password requirements
                Padding(
                  padding: const EdgeInsets.only(left: 2),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Password must:',
                        style: TextStyle(
                          fontFamily: 'Urbanist',
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: Colors.grey[500],
                        ),
                      ),
                      const SizedBox(height: 4),
                      ...[
                        'be at least 8 characters long',
                        'include upper and lower case characters',
                        'contain 1 number',
                        'contain 1 special character',
                        'match in both fields',
                      ].map((req) => Padding(
                            padding: const EdgeInsets.only(top: 2),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '  ·  ',
                                  style: TextStyle(
                                    fontFamily: 'Urbanist',
                                    fontSize: 12,
                                    color: Colors.grey[500],
                                  ),
                                ),
                                Text(
                                  req,
                                  style: TextStyle(
                                    fontFamily: 'Urbanist',
                                    fontSize: 12,
                                    fontWeight: FontWeight.w400,
                                    color: Colors.grey[500],
                                  ),
                                ),
                              ],
                            ),
                          )),
                    ],
                  ),
                ),

                const SizedBox(height: 40),

                // Register button
                GestureDetector(
                  onTap: _isLoading ? null : _handleRegister,
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
                              'Register',
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

                // Already have an account? Log In
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
                              Navigator.pushReplacementNamed(context, '/login');
                            },
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 40),
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
    TextInputType? keyboardType,
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
          keyboardType: keyboardType,
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
