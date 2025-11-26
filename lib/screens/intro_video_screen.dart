import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'login_screen.dart';

class IntroVideoScreen extends StatefulWidget {
  const IntroVideoScreen({super.key});

  @override
  State<IntroVideoScreen> createState() => _IntroVideoScreenState();
}

class _IntroVideoScreenState extends State<IntroVideoScreen> {
  late VideoPlayerController _videoPlayerController;
  ChewieController? _chewieController;
  bool _isLoading = true;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();
    _initializePlayer();
  }

  Future<void> _initializePlayer() async {
    try {
      _videoPlayerController = VideoPlayerController.asset(
        'assets/videos/intro_video.mp4',
      );

      await _videoPlayerController.initialize();

      _chewieController = ChewieController(
        videoPlayerController: _videoPlayerController,
        autoPlay: true,
        looping: false,
        aspectRatio: _videoPlayerController.value.aspectRatio,
        showControls: false,
        allowFullScreen: false,
        allowMuting: false,
        showOptions: false,
      );

      // Listen for video completion
      _videoPlayerController.addListener(() {
        if (_videoPlayerController.value.position ==
            _videoPlayerController.value.duration) {
          _skipToLogin();
        }
      });

      setState(() {
        _isLoading = false;
      });
    } catch (e) {
      print('Error loading video: $e');
      setState(() {
        _hasError = true;
        _isLoading = false;
      });
      // Auto-skip to login if video fails to load
      Future.delayed(const Duration(seconds: 2), () {
        if (mounted) _skipToLogin();
      });
    }
  }

  void _skipToLogin() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (context) => const LoginScreen()),
    );
  }

  @override
  void dispose() {
    _videoPlayerController.dispose();
    _chewieController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Video player
          if (!_isLoading && !_hasError && _chewieController != null)
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: AspectRatio(
                  aspectRatio: _videoPlayerController.value.aspectRatio,
                  child: Chewie(controller: _chewieController!),
                ),
              ),
            ),

          // Loading indicator
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(
                color: Colors.white,
              ),
            ),

          // Error message
          if (_hasError)
            const Center(
              child: Text(
                'Loading...',
                style: TextStyle(color: Colors.white),
              ),
            ),

          // Skip button
          Positioned(
            top: 50,
            right: 20,
            child: TextButton(
              onPressed: _skipToLogin,
              style: TextButton.styleFrom(
                backgroundColor: Colors.white.withOpacity(0.2),
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
              ),
              child: const Text(
                'Skip',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
