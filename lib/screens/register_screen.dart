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
  bool _hasScrolledToBottom = false;
  final _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _usernameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 10) {
      if (!_hasScrolledToBottom) {
        setState(() {
          _hasScrolledToBottom = true;
        });
      }
    }
  }

  Future<void> _handleRegister() async {
    if (!_hasScrolledToBottom) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Please read the Terms of Service to the bottom before registering',
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

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
                child: SingleChildScrollView(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 80),

                        // Logo (Plotd)
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

                        const SizedBox(height: 32),

                        // Terms of Service Section
                        Text(
                          'Terms of Service',
                          style: TextStyle(
                            fontFamily: 'Urbanist',
                            fontWeight: FontWeight.w600,
                            fontSize: 16,
                            color: grey,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          height: 120,
                          decoration: BoxDecoration(
                            border: Border.all(color: underline, width: 1.5),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: SingleChildScrollView(
                            controller: _scrollController,
                            padding: const EdgeInsets.all(12),
                            child: Text(
                              _getTermsOfService(),
                              style: const TextStyle(
                                fontFamily: 'Urbanist',
                                fontWeight: FontWeight.w400,
                                fontSize: 12,
                                height: 1.5,
                                color: Color(0xFF8A8A8A),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              _hasScrolledToBottom
                                  ? Icons.check_circle
                                  : Icons.radio_button_unchecked,
                              color: _hasScrolledToBottom ? Colors.green : grey,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Text(
                              _hasScrolledToBottom
                                  ? 'You have read the Terms of Service'
                                  : 'Please scroll to the bottom to continue',
                              style: TextStyle(
                                fontFamily: 'Urbanist',
                                fontWeight: FontWeight.w400,
                                fontSize: 12,
                                color: _hasScrolledToBottom
                                    ? Colors.green
                                    : grey,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 32),

                        // Centered glowy Register button
                        Center(
                          child: GestureDetector(
                            onTap: (_isLoading || !_hasScrolledToBottom)
                                ? null
                                : _handleRegister,
                            child: Container(
                              width: 393,
                              height: 64,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  colors: [
                                    _hasScrolledToBottom
                                        ? const Color(0xFFE91E8C)
                                        : const Color(
                                            0xFFE91E8C,
                                          ).withOpacity(0.5),
                                    _hasScrolledToBottom
                                        ? const Color(0xFFC9178B)
                                        : const Color(
                                            0xFFC9178B,
                                          ).withOpacity(0.5),
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

                        const SizedBox(height: 40),
                      ],
                    ),
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
              borderSide: BorderSide(color: underline, width: 1.5),
            ),
            focusedBorder: UnderlineInputBorder(
              borderSide: BorderSide(color: grey, width: 1.5),
            ),
            errorBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.red, width: 1.5),
            ),
            focusedErrorBorder: const UnderlineInputBorder(
              borderSide: BorderSide(color: Colors.red, width: 1.5),
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

  String _getTermsOfService() {
    return '''PLOTD – TERMS & CONDITIONS

Last updated: November 27 2025

Welcome to Plotd (“Plotd”, “we”, “our”, “us”). These Terms & Conditions (“Terms”) govern your access to and use of the Plotd mobile application and related services (the “Service”).
By creating an account, accessing, or using Plotd, you agree to be bound by these Terms.
If you do not agree, do not use the Service.

1. Eligibility

To use Plotd, you must:

Be at least 18 years old

Reside in a region where the Service is available

Have the legal capacity to enter a binding agreement

Agree to comply with these Terms and all applicable laws

If you are under the legal age of majority in your jurisdiction, you must have permission from a parent or guardian.

2. Use of the Service

Plotd is a challenge-based social app for entertainment purposes. You agree that:

You will use Plotd responsibly and safely.

You will not complete or attempt challenges that could cause harm, injury, property damage, or violate any law or campus rule.

You will use the Service only for lawful purposes and will not engage in harassment, bullying, hate speech, or abusive behaviour.

We reserve the right to suspend or terminate your account if you engage in harmful or inappropriate conduct.

3. User Content

“User Content” includes photos, videos, captions, proof submissions, usernames, and any other content you upload.

By uploading content, you:

Grant Plotd a non-exclusive, worldwide, royalty-free, transferable license to use, display, reproduce, distribute, and create derivative works for the purpose of operating and improving the Service.

Confirm that you own the rights to your content or have permission to share it.

Agree not to upload content that is:

Illegal

Violent, harmful, or dangerous

Sexual or pornographic

Harassing, discriminatory, or hateful

Someone else’s private information (e.g., addresses, IDs)

You are responsible for the content you post.

4. Prohibited Behavior

You agree not to:

Perform dangerous stunts, illegal acts, or risky behaviours as part of a challenge

Impersonate others

Attempt to hack, reverse-engineer, or disrupt Plotd systems

Upload malware, spam, or harmful code

Attempt to artificially manipulate scores, points, or leaderboards

Use Plotd while driving or in unsafe environments

Plotd encourages fun, safe, and responsible activity. Any misuse can result in account suspension or removal.

5. Safety Disclaimer

Plotd challenges are optional.
You participate at your own risk.

Plotd does not require or encourage users to:

Risk injury

Break the law

Violate university rules

Damage property

Endanger themselves or others

You are solely responsible for your actions while using the Service.

Plotd is not liable for any injuries, damages, losses, or consequences resulting from your participation in challenges.

6. Data & Privacy

Your privacy matters. By using Plotd, you consent to our Privacy Policy, which outlines:

What data we collect

How we use it

How we store it

How you can request deletion

We do not sell your personal data.

7. Account Security

You are responsible for maintaining the confidentiality of your account credentials.
You agree to notify us immediately if you suspect unauthorized access or misuse.

Plotd is not responsible for losses caused by unauthorized account use.

8. Modifications to the Service

We may update, change, or discontinue parts of the Service at any time.
We may also update these Terms periodically. Continued use means you accept the updated Terms.

9. Termination

We may suspend or terminate your access if you violate these Terms or if your behaviour threatens the safety or experience of other users.

You may delete your account at any time.

10. Disclaimer of Warranties

The Service is provided “as is” and without warranties of any kind, whether express or implied.

Plotd does not guarantee:

Continuous or error-free operation

Availability of challenges or features

Accuracy of user-generated content

11. Limitation of Liability

To the fullest extent permitted by law:

Plotd is not liable for:

Personal injury

Property damage

Losses arising from challenge participation

Unauthorized access to your account or data

Damages related to downtime, errors, or bugs

Your sole remedy is to stop using the Service.

12. Governing Law

These Terms are governed by the laws of Ontario, Canada, unless otherwise required by your jurisdiction.

13. Contact Information

If you have questions or concerns about these Terms, you can contact us at:

Email: plotdbusiness@gmail.com
Team: Plotd Team
''';
  }
}
