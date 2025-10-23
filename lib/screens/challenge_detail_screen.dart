import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/challenge.dart';
import '../services/api_service.dart';

class ChallengeDetailScreen extends StatefulWidget {
  final Challenge challenge;

  const ChallengeDetailScreen({super.key, required this.challenge});

  @override
  State<ChallengeDetailScreen> createState() => _ChallengeDetailScreenState();
}

class _ChallengeDetailScreenState extends State<ChallengeDetailScreen> {
  final List<XFile> _mediaFiles = [];
  final ImagePicker _picker = ImagePicker();
  bool _isUploading = false;
  bool _isSubmitting = false;

  Future<void> _pickMedia() async {
    try {
      final XFile? media = await _picker.pickMedia();
      if (media != null) {
        setState(() => _mediaFiles.add(media));
        _showMediaAddedMessage();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error picking media: $e')));
      }
    }
  }

  Future<void> _takePhoto() async {
    try {
      final XFile? photo = await _picker.pickImage(source: ImageSource.camera);
      if (photo != null) {
        setState(() => _mediaFiles.add(photo));
        _showMediaAddedMessage();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error taking photo: $e')));
      }
    }
  }

  void _removeMedia(int index) => setState(() => _mediaFiles.removeAt(index));

  void _showMediaAddedMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Media added! (${_mediaFiles.length} total)'),
        backgroundColor: _getDifficultyColor(),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  Widget _buildMediaPreview(int index) {
    final mediaFile = _mediaFiles[index];
    final fileExtension = mediaFile.path.split('.').last.toLowerCase();
    
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            border: Border.all(
              color: _getDifficultyColor(),
              width: 2,
            ),
          ),
          child: _getMediaWidget(mediaFile, fileExtension),
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
              onPressed: () => _removeMedia(index),
            ),
          ),
        ),
      ],
    );
  }

  Widget _getMediaWidget(XFile mediaFile, String fileExtension) {
    if (['jpg', 'jpeg', 'png', 'gif'].contains(fileExtension)) {
      // Image files
      return Image.file(
        File(mediaFile.path),
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      );
    } else if (['mp4', 'mov', 'avi'].contains(fileExtension)) {
      // Video files
      return Container(
        color: Colors.black,
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.play_circle_outline,
                color: Colors.white,
                size: 32,
              ),
              SizedBox(height: 4),
              Text(
                'VIDEO',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      );
    } else if (fileExtension == 'pdf') {
      // PDF files
      return Container(
        color: Colors.red[50],
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.picture_as_pdf,
                color: Colors.red,
                size: 32,
              ),
              SizedBox(height: 4),
              Text(
                'PDF',
                style: TextStyle(
                  color: Colors.red,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      // Other file types
      return Container(
        color: Colors.grey[200],
        child: const Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.attach_file,
                color: Colors.grey,
                size: 32,
              ),
              SizedBox(height: 4),
              Text(
                'FILE',
                style: TextStyle(
                  color: Colors.grey,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  Future<void> _submitChallenge() async {
    if (_mediaFiles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one media file')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      await ApiService.submitChallengeWithMedia(
        challengeId: widget.challenge.id,
        mediaFiles: _mediaFiles,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Challenge submitted successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Navigate back or show success screen
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to submit challenge: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
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
                    onPressed: _pickMedia,
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

            // Media Files
            if (_mediaFiles.isNotEmpty) ...[
              Text(
                "UPLOADED MEDIA",
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
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                ),
                itemCount: _mediaFiles.length,
                itemBuilder: (context, index) {
                  return _buildMediaPreview(index);
                },
              ),
            ] else
              Center(
                child: Column(
                  children: [
                    Icon(
                      Icons.attach_file_outlined,
                      size: 48,
                      color: Colors.grey[700],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "NO MEDIA YET",
                      style: TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
              ),

            // Submit button
            if (_mediaFiles.isNotEmpty) ...[
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submitChallenge,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _getDifficultyColor(),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isSubmitting
                      ? const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.black),
                              ),
                            ),
                            SizedBox(width: 12),
                            Text(
                              "SUBMITTING...",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        )
                      : const Text(
                          "SUBMIT CHALLENGE",
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
