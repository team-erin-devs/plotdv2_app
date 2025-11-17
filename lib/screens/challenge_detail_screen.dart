import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
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
  final List<_SelectedFile> _files = [];
  bool _isUploading = false;

  Future<void> _pickFile() async {
    try {
      FilePickerResult? result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: [
          'jpg',
          'jpeg',
          'png',
          'gif',
          'mp4',
          'mov',
          'avi',
          'pdf',
        ],
        allowMultiple: false,
        withData: true,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = result.files.first;
        if (file.bytes != null) {
          setState(
            () => _files.add(
              _SelectedFile(
                bytes: file.bytes!,
                name: file.name,
                extension: file.extension ?? '',
              ),
            ),
          );
        }
      }
    } catch (e) {
      _showSnack('Error picking file: $e');
    }
  }

  void _removeFile(int index) => setState(() => _files.removeAt(index));

  void _showSnack(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(msg), backgroundColor: Colors.black87),
    );
  }

  Future<void> _uploadFiles() async {
    if (_files.isEmpty) {
      _showSnack("Please select at least one file before uploading.");
      return;
    }

    setState(() => _isUploading = true);

    try {
      for (final file in _files) {
        await UploadService.uploadProof(
          bytes: file.bytes,
          filename: file.name,
          challengeId: widget.challenge.id,
        );
      }
      _showSnack("Upload successful!");
      setState(() => _files.clear());
    } catch (e) {
      _showSnack("Upload failed: $e");
    } finally {
      setState(() => _isUploading = false);
    }
  }

  Widget _buildFileThumbnail(_SelectedFile file) {
    if (['jpg', 'jpeg', 'png', 'gif'].contains(file.extension.toLowerCase())) {
      return Image.memory(
        file.bytes,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
      );
    }

    IconData icon;
    Color color;

    if (['mp4', 'mov', 'avi'].contains(file.extension.toLowerCase())) {
      icon = Icons.videocam;
      color = Colors.purple;
    } else if (file.extension.toLowerCase() == 'pdf') {
      icon = Icons.picture_as_pdf;
      color = Colors.red;
    } else {
      icon = Icons.insert_drive_file;
      color = Colors.blue;
    }

    return Container(
      color: Colors.grey[900],
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 48, color: color),
          const SizedBox(height: 8),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(
              file.name,
              style: const TextStyle(color: Colors.white, fontSize: 12),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
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
                        itemCount: _files.length,
                        itemBuilder: (context, index) {
                          final file = _files[index];
                          return Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: _buildFileThumbnail(file),
                              ),
                              Positioned(
                                top: 4,
                                right: 4,
                                child: GestureDetector(
                                  onTap: () => _removeFile(index),
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
                          onPressed: _pickFile,
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
                    onPressed: _isUploading ? null : _uploadFiles,
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

class _SelectedFile {
  final Uint8List bytes;
  final String name;
  final String extension;
  _SelectedFile({
    required this.bytes,
    required this.name,
    required this.extension,
  });
}
