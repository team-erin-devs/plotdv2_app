import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../services/upload_service.dart';
import 'circle_image_cropper.dart';

class EditProfileDialog extends StatefulWidget {
  final String currentBio;
  final String currentMajor;
  final String currentClass;
  final String? currentProfilePictureUrl;
  
  const EditProfileDialog({
    super.key,
    required this.currentBio,
    required this.currentMajor,
    required this.currentClass,
    this.currentProfilePictureUrl,
  });

  @override
  State<EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends State<EditProfileDialog> {
  late TextEditingController _bioController;
  String? _selectedMajor;
  String? _selectedClass;
  String? _newProfilePictureUrl;
  Uint8List? _selectedImageBytes;
  bool _isUploading = false;
  final ImagePicker _picker = ImagePicker();
  
  final List<String> _majors = [
    'Not specified',
    'Undecided Major',
    'Commerce',
    'Engineering',
    'Computer Science',
    'Arts & Science',
    'Life Sciences',
    'Health Sciences',
    'Kinesiology',
    'Nursing',
    'Education',
    'Law',
    'Business',
    'Economics',
    'Psychology',
    'Mathematics',
    'Physics',
    'Chemistry',
    'Biology',
    'English',
    'History',
    'Philosophy',
  ];
  
  final List<String> _classes = [
    'Not specified',
    'Class of \'25',
    'Class of \'26',
    'Class of \'27',
    'Class of \'28',
    'Class of \'29',
    'Class of \'30',
    'Class of \'31',
  ];

  @override
  void initState() {
    super.initState();
    _bioController = TextEditingController(text: widget.currentBio);
    // Only set values if they exist in the dropdown lists
    _selectedMajor = _majors.contains(widget.currentMajor) ? widget.currentMajor : null;
    _selectedClass = _classes.contains(widget.currentClass) ? widget.currentClass : null;
  }

  @override
  void dispose() {
    _bioController.dispose();
    super.dispose();
  }

  Future<void> _pickProfilePicture() async {
    try {
      final XFile? picked = await _picker.pickImage(
        source: ImageSource.gallery,
      );
      
      if (picked != null) {
        // Get the image bytes
        final imageBytes = await picked.readAsBytes();
        
        // Show our custom circular cropper
        if (mounted) {
          final Uint8List? croppedBytes = await showDialog<Uint8List>(
            context: context,
            barrierDismissible: false,
            builder: (context) => CircleImageCropper(imageBytes: imageBytes),
          );
          
          if (croppedBytes != null) {
            setState(() {
              _selectedImageBytes = croppedBytes;
            });
            
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Image selected! Click Save to upload.'),
                  backgroundColor: Colors.green,
                ),
              );
            }
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error picking image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: const Color(0xFF0a0a0a),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Edit Profile',
                style: GoogleFonts.epilogue(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Change Profile Picture Button
              OutlinedButton.icon(
                onPressed: _isUploading ? null : _pickProfilePicture,
                icon: Icon(
                  _selectedImageBytes != null ? Icons.check_circle : Icons.camera_alt,
                  color: _selectedImageBytes != null ? Colors.green : Colors.white,
                ),
                label: Text(
                  _selectedImageBytes != null ? 'Image Selected' : 'Change Profile Picture',
                  style: GoogleFonts.urbanist(
                    color: _selectedImageBytes != null ? Colors.green : Colors.white,
                    fontSize: 14,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(
                    color: _selectedImageBytes != null ? Colors.green : Colors.white54,
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              
              const SizedBox(height: 24),
              
              // Bio
              Text(
                'Bio',
                style: GoogleFonts.urbanist(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _bioController,
                maxLines: 3,
                maxLength: 150,
                style: GoogleFonts.urbanist(color: Colors.white),
                decoration: InputDecoration(
                  hintText: 'Tell us about yourself...',
                  hintStyle: GoogleFonts.urbanist(color: Colors.grey[600]),
                  filled: true,
                  fillColor: Colors.grey[900],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  counterStyle: GoogleFonts.urbanist(color: Colors.grey[600]),
                ),
              ),
              
              const SizedBox(height: 20),
              
              // Major
              Text(
                'Major',
                style: GoogleFonts.urbanist(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedMajor,
                dropdownColor: Colors.grey[900],
                style: GoogleFonts.urbanist(color: Colors.white),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.grey[900],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                items: _majors.map((major) {
                  return DropdownMenuItem(
                    value: major,
                    child: Text(major, style: GoogleFonts.urbanist()),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedMajor = value;
                  });
                },
              ),
              
              const SizedBox(height: 20),
              
              // Class
              Text(
                'Class',
                style: GoogleFonts.urbanist(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _selectedClass,
                dropdownColor: Colors.grey[900],
                style: GoogleFonts.urbanist(color: Colors.white),
                decoration: InputDecoration(
                  filled: true,
                  fillColor: Colors.grey[900],
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                ),
                items: _classes.map((classYear) {
                  return DropdownMenuItem(
                    value: classYear,
                    child: Text(classYear, style: GoogleFonts.urbanist()),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedClass = value;
                  });
                },
              ),
              
              const SizedBox(height: 32),
              
              // Action buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      'Cancel',
                      style: GoogleFonts.urbanist(
                        color: Colors.grey[400],
                        fontSize: 16,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _isUploading ? null : () async {
                      String? uploadedUrl;
                      
                      // Upload image if selected
                      if (_selectedImageBytes != null) {
                        setState(() => _isUploading = true);
                        
                        try {
                          uploadedUrl = await UploadService.uploadProfilePicture(
                            bytes: _selectedImageBytes!,
                            filename: 'profile_${DateTime.now().millisecondsSinceEpoch}.jpg',
                          );
                          
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Profile picture uploaded!'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        } catch (e) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text('Upload failed: $e'),
                                backgroundColor: Colors.red,
                              ),
                            );
                            setState(() => _isUploading = false);
                            return;
                          }
                        } finally {
                          if (mounted) {
                            setState(() => _isUploading = false);
                          }
                        }
                      }
                      
                      if (mounted) {
                        Navigator.pop(context, {
                          'bio': _bioController.text,
                          'major': _selectedMajor,
                          'class': _selectedClass,
                          'profile_picture': uploadedUrl,
                        });
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _isUploading ? Colors.grey : Colors.blue,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _isUploading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            'Save',
                            style: GoogleFonts.urbanist(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
