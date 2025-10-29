import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/challenge.dart';
import '../services/upload_service.dart'; // make sure path matches your project

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

  Future<void> _takePhoto() async {
    try {
      final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
      if (photo != null) {
        final bytes = await photo.readAsBytes();
        setState(
          () => _images.add(_SelectedImage(bytes: bytes, name: photo.name)),
        );
      }
    } catch (e) {
      _showSnack('Error taking photo: $e');
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

  Color _getDifficultyColor() {
    switch (widget.challenge.difficulty) {
      case ChallengeDifficulty.easy:
        return Colors.greenAccent;
      case ChallengeDifficulty.medium:
        return Colors.amberAccent;
      case ChallengeDifficulty.hard:
        return Colors.redAccent;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
        centerTitle: true,
        elevation: 0,
        title: Text(
          widget.challenge.title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(2),
          child: Container(color: _getDifficultyColor(), height: 2),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.challenge.description,
              style: const TextStyle(fontSize: 14, color: Colors.white70),
            ),
            const SizedBox(height: 24),

            // Buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    onPressed: _pickImage,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _getDifficultyColor(),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      "GALLERY",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _takePhoto,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _getDifficultyColor(),
                      foregroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      "CAMERA",
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Image previews
            if (_images.isNotEmpty)
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "SELECTED IMAGES",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: _getDifficultyColor(),
                    ),
                  ),
                  const SizedBox(height: 12),
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
                          Container(
                            decoration: BoxDecoration(
                              border: Border.all(
                                color: _getDifficultyColor(),
                                width: 2,
                              ),
                            ),
                            child: Image.memory(img.bytes, fit: BoxFit.cover),
                          ),
                          Positioned(
                            top: 2,
                            right: 2,
                            child: Container(
                              color: Colors.redAccent,
                              child: IconButton(
                                icon: const Icon(Icons.close, size: 16),
                                color: Colors.black,
                                padding: EdgeInsets.zero,
                                constraints: const BoxConstraints(),
                                onPressed: () => _removeImage(index),
                              ),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              )
            else
              Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.image_outlined,
                      size: 48,
                      color: Colors.grey[700],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "NO IMAGES YET",
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 24),

            // Upload button
            Center(
              child: ElevatedButton(
                onPressed: _isUploading ? null : _uploadImages,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _getDifficultyColor(),
                  foregroundColor: Colors.black,
                  padding: const EdgeInsets.symmetric(
                    vertical: 14,
                    horizontal: 40,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: _isUploading
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          color: Colors.black,
                          strokeWidth: 2.5,
                        ),
                      )
                    : const Text(
                        "UPLOAD",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
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

/// Helper class to store image bytes + original filename
class _SelectedImage {
  final Uint8List bytes;
  final String name;
  _SelectedImage({required this.bytes, required this.name});
}
