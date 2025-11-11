import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/challenge.dart';
import '../services/upload_service.dart';
import '../widgets/upload_mission_card.dart';

class ChallengeDetailScreen extends StatefulWidget {
  final Challenge challenge;

  const ChallengeDetailScreen({super.key, required this.challenge});

  @override
  State<ChallengeDetailScreen> createState() => _ChallengeDetailScreenState();
}

class _ChallengeDetailScreenState extends State<ChallengeDetailScreen> {
  final List<_SelectedImage> _images = [];
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;

  Future<void> _pickImage() async {
    try {
      final XFile? picked = await _picker.pickImage(
        source: ImageSource.gallery,
      );
      if (picked != null) {
        final bytes = await picked.readAsBytes();
        setState(
          () => _images.add(_SelectedImage(bytes: bytes, name: picked.name)),
        );
      }
    } catch (e) {
      _showSnack('Error picking image: $e');
    }
  }

  void _removeImage(int index) => setState(() => _images.removeAt(index));

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.black87),
    );
  }

  Future<void> _uploadImages() async {
    if (_images.isEmpty) {
      _showSnack("Please select at least one image before uploading.");
      return;
    }

    setState(() => _isUploading = true);

    try {
      for (final img in _images) {
        await UploadService.uploadProof(
          bytes: img.bytes,
          filename: img.name,
          challengeId: widget.challenge.id,
        );
      }
      _showSnack("Upload successful!");
      setState(() => _images.clear());
    } catch (e) {
      _showSnack("Upload failed: $e");
    } finally {
      setState(() => _isUploading = false);
    }
  }

  List<Color> _getGradient() {
    switch (widget.challenge.difficulty) {
      case ChallengeDifficulty.easy:
        return [const Color(0xFF23B2CA), const Color(0xFF126C87)];
      case ChallengeDifficulty.medium:
        return [const Color(0xFFA621ED), const Color(0xFF5E1387)];
      case ChallengeDifficulty.hard:
        return [const Color(0xFFED2190), const Color(0xFF871352)];
    }
  }

  @override
  Widget build(BuildContext context) {
    final gradient = _getGradient();
    final accent = gradient.first;

    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: UploadMissionCard(
            title: widget.challenge.title,
            description: widget.challenge.description,
            difficulty: widget.challenge.difficulty,
            points: widget.challenge.points,
            gradient: gradient,
            uploadSection: Column(
              children: [
                // Upload area with border
                Container(
                  width: double.infinity,
                  constraints: const BoxConstraints(minHeight: 300),
                  padding: const EdgeInsets.all(32),
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: Colors.white.withOpacity(0.3),
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Column(
                    children: [
                      GridView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              crossAxisSpacing: 12,
                              mainAxisSpacing: 12,
                            ),
                        itemCount: _images.length,
                        itemBuilder: (context, index) {
                          final img = _images[index];
                          return Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: Image.memory(
                                  img.bytes,
                                  fit: BoxFit.cover,
                                  width: double.infinity,
                                  height: double.infinity,
                                ),
                              ),
                              Positioned(
                                top: 4,
                                right: 4,
                                child: GestureDetector(
                                  onTap: () => _removeImage(index),
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.close,
                                      size: 16,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 84),

                      // Upload file button (lighter color, inside the border)
                      SizedBox(
                        width: 250,
                        height: 50,
                        child: ElevatedButton(
                          onPressed: _pickImage,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white.withOpacity(0.8),
                            foregroundColor: accent,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'upload file',
                                style: TextStyle(
                                  fontFamily: 'Urbanist',
                                  fontWeight: FontWeight.w500,
                                  fontSize: 18,
                                  color: accent,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Icon(Icons.arrow_upward, size: 24, color: accent),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),

                // Submit proof button (white background, outside the border)
                SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: ElevatedButton(
                    onPressed: _isUploading ? null : _uploadImages,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.white,
                      foregroundColor: accent,
                      disabledBackgroundColor: Colors.grey[800],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: _isUploading
                        ? SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: accent,
                              strokeWidth: 2.5,
                            ),
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Submit proof',
                                style: TextStyle(
                                  fontFamily: 'Urbanist',
                                  fontWeight: FontWeight.w500,
                                  fontSize: 20,
                                  color: accent,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Icon(
                                Icons.arrow_forward,
                                size: 24,
                                color: accent,
                              ),
                            ],
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SelectedImage {
  final Uint8List bytes;
  final String name;
  _SelectedImage({required this.bytes, required this.name});
}
