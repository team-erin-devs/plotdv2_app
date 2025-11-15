import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'package:flutter/gestures.dart';


class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;

  Future<void> _handleRegister()  async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        final response = await _authService.register(
          username: _usernameController.text,
          email: _emailController.text,
          password: _passwordController.text,
        );

        // TODO: Store tokens and navigate to home screen
        if (mounted) {
          Navigator.pushReplacementNamed(context, '/home');
        }
        print(response);
      } catch (e) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(e.toString())));
      } finally {
        setState(() => _isLoading = false);
      }
    }
  }

@override
  Widget build(BuildContext context) {
    const background = Color(0xFF030303);
    const grey = Color(0xFFACACAC);
    const underline = Color(0xFF2D2D2D);

    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(38),
          child: Container(
            width: 393,
            height: 852,
            color: background,
            child: SafeArea(
              child: Form(
                key: _formKey,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 80),

                      // Logo (Ploit*)
                      Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Image.asset(
                              'assets/images/login logo.png',
                              height: 62.07,
                              fit: BoxFit.contain,
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 80),

                      // Username field
                      _buildUnderlineField(
                        label: 'Username',
                        controller: _usernameController,
                        isPassword: false,
                        grey: grey,
                        underline: underline,
                      ),

                      const SizedBox(height: 32),

                      // Email field
                      _buildUnderlineField(
                        label: 'Email',
                        controller: _emailController,
                        isPassword: false,
                        grey: grey,
                        underline: underline,
                      ),

                      const SizedBox(height: 32),

                      // Password field
                      _buildUnderlineField(
                        label: 'Password',
                        controller: _passwordController,
                        isPassword: true,
                        grey: grey,
                        underline: underline,
                      ),

                      const SizedBox(height: 48),

                      // Centered glowy Register button
                      Center(
                        child: GestureDetector(
                          onTap: _isLoading ? null : _handleRegister,
                          child: Container(
                            width: 393,
                            height: 64,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [
                                  Color(0xFFE91E8C),
                                  Color(0xFFC9178B),
                                ],
                                begin: Alignment.centerLeft,
                                end: Alignment.centerRight,
                              ),
                              borderRadius: BorderRadius.circular(32),
                              boxShadow: const [
                                BoxShadow(
                                  color: Color.fromRGBO(233, 30, 140, 0.4),
                                  blurRadius: 30,
                                  spreadRadius: 0,
                                  offset: Offset(0, 4),
                                ),
                              ],
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
                                      "Register",
                                      style: TextStyle(
                                        fontFamily: 'Urbanist',
                                        fontWeight: FontWeight.w600,
                                        fontSize: 20,
                                        letterSpacing: -0.023,
                                        color: Colors.white,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // "Already have an account? Login"
                      Center(
                        child: RichText(
                          text: TextSpan(
                            style: const TextStyle(
                              fontFamily: 'Urbanist',
                              fontWeight: FontWeight.w400,
                              fontSize: 14,
                              height: 17 / 14,
                              letterSpacing: -0.023,
                              color: grey,
                            ),
                            children: [
                              const TextSpan(
                                text: "Already have an account? ",
                              ),
                              TextSpan(
                                text: "Login",
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () {
                                    Navigator.pop(context);
                                  },
                                style: const TextStyle(
                                  decoration: TextDecoration.underline,
                                  fontWeight: FontWeight.w500,
                                  color: grey,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const Spacer(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildUnderlineField({
    required String label,
    required TextEditingController controller,
    required bool isPassword,
    required Color grey,
    required Color underline,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: controller,
          obscureText: isPassword,
          cursorColor: grey,
          style: const TextStyle(
            fontFamily: 'Urbanist',
            fontWeight: FontWeight.w400,
            fontSize: 20,
            letterSpacing: -0.023,
            color: Colors.white,
          ),
          decoration: InputDecoration(
            labelText: label,
            labelStyle: TextStyle(
              fontFamily: 'Urbanist',
              fontWeight: FontWeight.w400,
              fontSize: 20,
              letterSpacing: -0.023,
              color: grey,
            ),
            floatingLabelBehavior: FloatingLabelBehavior.never,
            isDense: true,
            contentPadding: const EdgeInsets.only(bottom: 8, top: 4),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(
                color: underline,
                width: 1.5,
              ),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(
                color: grey,
                width: 1.5,
              ),
            ),
            errorBorder: const UnderlineInputBorder(
              borderSide: BorderSide(
                color: Colors.red,
                width: 1.5,
              ),
            ),
            focusedErrorBorder: const UnderlineInputBorder(
              borderSide: BorderSide(
                color: Colors.red,
                width: 1.5,
              ),
            ),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return '$label cannot be empty';
            }
            if (label == 'Email' && !value.contains('@')) {
              return 'Please enter a valid email';
            }
            return null;
          },
        ),
      ],
    );
  }
}