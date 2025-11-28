import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';
import 'package:shared_preferences/shared_preferences.dart';

class IntroVideoWrapper extends StatefulWidget {
  const IntroVideoWrapper({super.key});

  @override
  State<IntroVideoWrapper> createState() => _IntroVideoWrapperState();
}

class _IntroVideoWrapperState extends State<IntroVideoWrapper> {
  VideoPlayerController? _controller;
  bool _navigated = false;
  bool _isInitializing = true;
  String _debugMessage = 'Initializing...';

  @override
  void initState() {
    super.initState();
    _checkAndInitVideo();
  }

  Future<void> _checkAndInitVideo() async {
    try {
      setState(() {
        _debugMessage = 'Checking preferences...';
      });
      
      final prefs = await SharedPreferences.getInstance();
      
      // For debugging: always play video (remove this line later if you want first-launch-only)
      await prefs.setBool('has_seen_intro', false);
      
      final hasSeenIntro = prefs.getBool('has_seen_intro') ?? false;
      
      print('Has seen intro: $hasSeenIntro');
      
      // Uncomment these lines if you want video to play only on first launch
      // if (hasSeenIntro) {
      //   print('Skipping video - already seen');
      //   _goToAuth();
      //   return;
      // }

      setState(() {
        _debugMessage = 'Loading video...';
      });

      await _initVideo();
      
    } catch (e) {
      print('❌ Error in checkAndInitVideo: $e');
      setState(() {
        _debugMessage = 'Error: $e';
      });
      await Future.delayed(const Duration(seconds: 2));
      _goToAuth();
    }
  }

  Future<void> _initVideo() async {
    try {
      print('🎬 Attempting to load video from assets/videos/intro.mp4');
      
      _controller = VideoPlayerController.asset('assets/videos/intro.mp4');
      
      print('📹 Controller created, initializing...');
      
      await _controller!.initialize().timeout(
        const Duration(seconds: 5),
        onTimeout: () {
          print('⏱️ Video initialization timeout');
          throw Exception('Video initialization timeout');
        },
      );
      
      print('✅ Video initialized successfully');
      print('📏 Video duration: ${_controller!.value.duration}');
      
      if (!mounted) return;

      setState(() {
        _isInitializing = false;
        _debugMessage = 'Playing video...';
      });

      // Start playing
      await _controller!.play();
      print('▶️ Video playing');

      // Add listener for video position changes
      _controller!.addListener(_checkVideoProgress);

      // Mark as seen
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool('has_seen_intro', true);

      // IMPORTANT: Set a timeout based on video duration
      final videoDuration = _controller!.value.duration;
      if (videoDuration > Duration.zero) {
        // Add 1 second buffer to ensure video completes
        final timeoutDuration = videoDuration + const Duration(seconds: 1);
        print('⏰ Setting timeout for ${timeoutDuration.inSeconds} seconds');
        
        Future.delayed(timeoutDuration, () {
          if (!_navigated && mounted) {
            print('⏱️ Video duration timeout - navigating');
            _goToAuth();
          }
        });
      } else {
        // Fallback if duration is unknown (shouldn't happen but just in case)
        Future.delayed(const Duration(seconds: 10), () {
          if (!_navigated && mounted) {
            print('⚠️ Fallback timeout triggered');
            _goToAuth();
          }
        });
      }

    } catch (e) {
      print('❌ Error loading video: $e');
      print('📁 Make sure intro.mp4 exists in assets/videos/ folder');
      print('📝 Make sure pubspec.yaml includes assets/videos/');
      
      setState(() {
        _debugMessage = 'Video failed to load. Redirecting...';
      });
      
      await Future.delayed(const Duration(seconds: 2));
      if (mounted) {
        _goToAuth();
      }
    }
  }

  void _checkVideoProgress() {
    if (_navigated) return;
    if (_controller == null || !_controller!.value.isInitialized) return;

    final position = _controller!.value.position;
    final duration = _controller!.value.duration;

    // Print progress for debugging
    if (position.inSeconds % 1 == 0) {
      print('📍 Video position: ${position.inSeconds}s / ${duration.inSeconds}s');
    }

    // Check if we're near the end (within 500ms)
    if (duration > Duration.zero && 
        position >= duration - const Duration(milliseconds: 500)) {
      print('🏁 Video near end detected, navigating...');
      _goToAuth();
    }
  }

  void _goToAuth() {
    if (_navigated || !mounted) return;
    
    print('🚀 Navigating to auth...');
    _navigated = true;
    
    // Remove listener before navigating
    _controller?.removeListener(_checkVideoProgress);
    
    Navigator.of(context).pushReplacementNamed('/auth');
  }

  @override
  void dispose() {
    _controller?.removeListener(_checkVideoProgress);
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        print('👆 Screen tapped - skipping video');
        _goToAuth();
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: Stack(
          children: [
            // Video player or loading indicator
            Center(
              child: _controller != null && _controller!.value.isInitialized
                  ? AspectRatio(
                      aspectRatio: _controller!.value.aspectRatio,
                      child: VideoPlayer(_controller!),
                    )
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const CircularProgressIndicator(color: Colors.white),
                        const SizedBox(height: 20),
                        Text(
                          _debugMessage,
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Text(
                          'Tap anywhere to skip',
                          style: TextStyle(
                            color: Colors.white38,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
            ),
            
            // Skip button
            if (_controller != null && _controller!.value.isInitialized)
              Positioned(
                top: 50,
                right: 20,
                child: SafeArea(
                  child: TextButton(
                    onPressed: _goToAuth,
                    style: TextButton.styleFrom(
                      backgroundColor: Colors.black.withOpacity(0.5),
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
                      ),
                    ),
                  ),
                ),
              ),
            
            // Debug info (remove in production)
            if (_controller != null && _controller!.value.isInitialized)
              Positioned(
                bottom: 20,
                left: 20,
                child: Container(
                  padding: const EdgeInsets.all(8),
                  color: Colors.black.withOpacity(0.5),
                  child: Text(
                    'Position: ${_controller!.value.position.inSeconds}s / ${_controller!.value.duration.inSeconds}s',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}