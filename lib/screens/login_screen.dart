import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import 'package:flutter/gestures.dart';


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

  Future<void> _handleLogin() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isLoading = true);
      try {
        final response = await _authService.login(
          username: _usernameController.text,
          password: _passwordController.text,
        );

        //navigate after successful login
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
    const accentPink = Color.fromRGBO(237, 33, 144, 0.25);

    return Scaffold(
      backgroundColor: Colors.black, // phone background
      body: Center(
        child: ClipRRect(
          borderRadius: BorderRadius.circular(38), // matches Figma
          child: Container(
            width: 393,
            height: 852,
            color: background,
            child: SafeArea(
              child: Form(
                key: _formKey,
                child: Padding(
                  // Figma left = 67px, button left = 102px; this is a good middle ground
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 100),

                      // Logo (Plotd*)
                      Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            // If you want to use the image logo:
                            Image.asset(
                              'assets/images/login logo.png',
                              height: 62.07, // ~Group 76 height
                              fit: BoxFit.contain,
                            ),

                            // If you ever want text instead, comment the Image and
                            // uncomment the Row below and make sure fonts exist.
                            /*
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: const [
                                Text(
                                  'Ploit',
                                  style: TextStyle(
                                    fontFamily: 'Epoch',
                                    fontSize: 56.67,
                                    height: 51 / 56.67,
                                    letterSpacing: -0.023,
                                    color: Colors.white,
                                  ),
                                ),
                                SizedBox(width: 4),
                                Text(
                                  '*',
                                  style: TextStyle(
                                    fontFamily: 'Epoch',
                                    fontSize: 56.67,
                                    height: 51 / 56.67,
                                    letterSpacing: -0.023,
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                            */
                          ],
                        ),
                      ),

                      const SizedBox(height: 52.07), // 100 → 202.07 gap

                      // Username field group
                      _buildUnderlineField(
                        label: 'Username',
                        controller: _usernameController,
                        isPassword: false,
                        grey: grey,
                        underline: underline,
                      ),

                      const SizedBox(height: 19), // 202.07 → 250.07 gap approx

                      // Password field group
                      _buildUnderlineField(
                        label: 'Password',
                        controller: _passwordController,
                        isPassword: true,
                        grey: grey,
                        underline: underline,
                      ),

                      const SizedBox(height: 60), // 279.07 → 339.07 gap approx

                      // Centered glowy Register button
                      Center(
                        child: GestureDetector(
                          onTap: _isLoading ? null : _handleLogin,
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
                                      "Login",
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

                      // "Don't have an account? Register" 
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
                                text: "Don't have an account? ",
                              ),
                              TextSpan(
                                text: "Register",
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () {
                                    Navigator.pushReplacementNamed(context, '/register');
                                    // or Navigator.pushNamed(context, '/register');
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

                      // Spacer to keep content near top like the design
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
          cursorColor: Colors.white,
          style: const TextStyle(
            fontFamily: 'Urbanist',
            fontWeight: FontWeight.w400,
            fontSize: 24,
            height: 29 / 24,
            letterSpacing: -0.023,
            color: Colors.white,
          ),
          decoration: InputDecoration(
            labelText: label,
            labelStyle: TextStyle(
              fontFamily: 'Urbanist',
              fontWeight: FontWeight.w400,
              fontSize: 24,
              height: 29 / 24,
              letterSpacing: -0.023,
              color: grey,
            ),
            floatingLabelBehavior: FloatingLabelBehavior.never,
            isDense: true,
            contentPadding: const EdgeInsets.only(bottom: 4),
            enabledBorder: UnderlineInputBorder(
              borderSide: BorderSide(
                color: underline,
                width: 2,
              ),
            ),
            focusedBorder: const UnderlineInputBorder(
              borderSide: BorderSide(
                color: Colors.white,
                width: 2,
              ),
            ),
          ),
          validator: (value) {
            if (value == null || value.trim().isEmpty) {
              return '$label cannot be empty';
            }
            return null;
          },
        ),
      ],
    );
  }
}