import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class EditProfileDialog extends StatefulWidget {
  final String currentBio;
  final String currentMajor;
  final String currentClass;
  
  const EditProfileDialog({
    super.key,
    required this.currentBio,
    required this.currentMajor,
    required this.currentClass,
  });

  @override
  State<EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends State<EditProfileDialog> {
  late TextEditingController _bioController;
  String? _selectedMajor;
  String? _selectedClass;
  
  final List<String> _majors = [
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
    _selectedMajor = widget.currentMajor;
    _selectedClass = widget.currentClass;
  }

  @override
  void dispose() {
    _bioController.dispose();
    super.dispose();
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
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Profile picture upload coming soon!'),
                      backgroundColor: Colors.blue,
                    ),
                  );
                },
                icon: const Icon(Icons.camera_alt, color: Colors.white),
                label: Text(
                  'Change Profile Picture',
                  style: GoogleFonts.urbanist(
                    color: Colors.white,
                    fontSize: 14,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.white54),
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
                    onPressed: () {
                      Navigator.pop(context, {
                        'bio': _bioController.text,
                        'major': _selectedMajor,
                        'class': _selectedClass,
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
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
