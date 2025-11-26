import 'package:flutter/material.dart';
import 'dart:ui';
import 'intro_video_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      // background comes from your app theme (black); not touched
      body: Stack(
        children: [
          /// ENVELOPE / LETTER PNG (contains all inner elements)
          Positioned(
            top: 245, // matches your CSS `top: 245px`
            left: (size.width - 387) / 2, // calc(50% - 387px/2)
            child: Image.asset(
              'assets/images/welcome-page-image.png',
              width: 387,  // letter width
              height: 361, // letter height
              fit: BoxFit.fill,
            ),
          ),

          /// JOIN THE PLOT BUTTON
          Positioned(
            left: (size.width - 309) / 2,   // same width as your design
            top: 684,                       // same top offset
            child: GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const IntroVideoScreen(),
                  ),
                );
              },
              child: Image.asset(
                'assets/images/Join-the-plot-button.png',
                width: 309,
                height: 60,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
