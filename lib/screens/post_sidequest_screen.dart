import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:convert';
import 'dart:math' as math;
import 'package:intl/intl.dart';
import '../services/authenticated_api_service.dart';

class PostSidequestScreen extends StatefulWidget {
  const PostSidequestScreen({super.key});

  @override
  State<PostSidequestScreen> createState() => _PostSidequestScreenState();
}

class _PostSidequestScreenState extends State<PostSidequestScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _locationController = TextEditingController();
  
  String selectedVibe = 'productive';
  int numPeople = 3;
  bool postToBoard = false;
  bool _isPosting = false;

  DateTime? _selectedDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;

  @override
  void dispose() {
    _titleController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(primary: Color(0xFFFFB300)),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  Future<void> _selectTime(bool isStart) async {
    final initial = isStart 
        ? (_startTime ?? const TimeOfDay(hour: 14, minute: 0))
        : (_endTime ?? const TimeOfDay(hour: 17, minute: 0));
        
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(primary: Color(0xFFFFB300)),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isStart) _startTime = picked;
        else _endTime = picked;
      });
    }
  }

  Future<void> _postSidequest() async {
    final title = _titleController.text.trim();
    if (title.isEmpty) {
      _showError('give your quest a name!');
      return;
    }
    if (_selectedDate == null || _startTime == null) {
      _showError('please pick a date and start time!');
      return;
    }

    setState(() => _isPosting = true);

    try {
      final startDateTime = DateTime(
        _selectedDate!.year, _selectedDate!.month, _selectedDate!.day,
        _startTime!.hour, _startTime!.minute,
      );
      
      DateTime? endDateTime;
      if (_endTime != null) {
        endDateTime = DateTime(
          _selectedDate!.year, _selectedDate!.month, _selectedDate!.day,
          _endTime!.hour, _endTime!.minute,
        );
        // Handle end time next day
        if (endDateTime.isBefore(startDateTime)) {
          endDateTime = endDateTime.add(const Duration(days: 1));
        }
      }

      final payload = {
        'title': title,
        'event_datetime': startDateTime.toUtc().toIso8601String(),
        'vibe': selectedVibe,
        'max_people': numPeople,
        'post_to_campus_board': postToBoard,
        'location': _locationController.text.trim(),
      };
      
      if (endDateTime != null) {
        payload['end_datetime'] = endDateTime.toUtc().toIso8601String();
      }

      final response = await AuthenticatedApiService.authenticatedPost(
        '/api/sidequests/',
        payload,
      );

      if (response.statusCode == 201) {
        if (mounted) {
          Navigator.pushNamed(context, '/sidequest-confirmation');
          // Reset form
          _titleController.clear();
          _locationController.clear();
          setState(() {
            selectedVibe = 'productive';
            _selectedDate = null;
            _startTime = null;
            _endTime = null;
            numPeople = 3;
            postToBoard = false;
          });
        }
      } else {
        final errorBody = jsonDecode(response.body);
        throw Exception(errorBody.toString());
      }
    } catch (e) {
      _showError('something went wrong: $e');
    } finally {
      if (mounted) setState(() => _isPosting = false);
    }
  }
  
  void _showError(String message) {
     if (!mounted) return;
     ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w600)),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData.light().copyWith(
        scaffoldBackgroundColor: const Color(0xFFF8F4F0), // slight off white
        textTheme: GoogleFonts.plusJakartaSansTextTheme(),
      ),
      child: Scaffold(
        body: SafeArea(
           child: Column(
             children: [
                // ── Header ──
                Padding(
                   padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                   child: Row(
                     mainAxisAlignment: MainAxisAlignment.spaceBetween,
                     children: [
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.black87, size: 28),
                          onPressed: () => Navigator.pop(context),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                        Text.rich(
                           TextSpan(children: [
                              TextSpan(
                                 text: 'Plot',
                                 style: GoogleFonts.plusJakartaSans(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF1E1E1E),
                                 ),
                              ),
                              TextSpan(
                                 text: 'd',
                                 style: GoogleFonts.plusJakartaSans(
                                    fontSize: 24,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF1E1E1E),
                                 ),
                              ),
                              WidgetSpan(
                                alignment: PlaceholderAlignment.top,
                                child: Image.asset(
                                  'assets/images/asterik.png',
                                  width: 18,
                                  color: const Color(0xFF1E1E1E),
                                ),
                              ),
                           ]),
                        ),
                        const SizedBox(width: 28), // Balance for centering
                     ],
                   ),
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // ── Yellow sticky note for title ──
                        Container(
                          width: double.infinity,
                          height: 180, // Taller sticky note
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF3D4), // Very light yellow note
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'What\'s the quest?',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF2D2D2D),
                                ),
                              ),
                              const SizedBox(height: 12),
                              Container(height: 1, color: const Color(0xFFE4D5B7)),
                              const SizedBox(height: 12),
                              Expanded(
                                child: TextField(
                                  controller: _titleController,
                                  maxLines: null, // Allow expanding
                                  expands: true,
                                  textAlignVertical: TextAlignVertical.top,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                    fontStyle: FontStyle.italic,
                                    color: const Color(0xFF1E1E1E),
                                    height: 1.2,
                                  ),
                                  decoration: InputDecoration(
                                    hintText: 'Coffee run and study\nsession',
                                    hintStyle: GoogleFonts.plusJakartaSans(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800,
                                      fontStyle: FontStyle.italic,
                                      color: const Color(0xFFA69980),
                                      height: 1.2,
                                    ),
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.zero,
                                    isDense: true,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),
          
                        // ── Location ──
                        _buildLabel('Location'),
                        const SizedBox(height: 8),
                        _buildInputField(
                           child: TextField(
                              controller: _locationController,
                              style: GoogleFonts.plusJakartaSans(fontSize: 15, color: Colors.black87, fontWeight: FontWeight.w500),
                              decoration: InputDecoration(
                                 hintText: 'Enter location',
                                 hintStyle: GoogleFonts.plusJakartaSans(color: Colors.grey[500], fontSize: 15),
                                 border: InputBorder.none,
                                 isDense: true,
                              ),
                           ),
                           suffixIcon: Icons.location_on,
                        ),
                        const SizedBox(height: 20),
          
                        // ── Date ──
                        _buildLabel('Date'),
                        const SizedBox(height: 8),
                        GestureDetector(
                           onTap: _selectDate,
                           child: _buildInputField(
                              child: Text(
                                 _selectedDate == null ? 'Choose date' : DateFormat('MMM d, yyyy').format(_selectedDate!),
                                 style: GoogleFonts.plusJakartaSans(
                                    fontSize: 15,
                                    color: _selectedDate == null ? Colors.grey[500] : Colors.black87,
                                    fontWeight: _selectedDate == null ? FontWeight.w400 : FontWeight.w500,
                                 ),
                              ),
                              suffixIcon: Icons.calendar_today_outlined,
                           ),
                        ),
                        const SizedBox(height: 20),
          
                        // ── Start & End Time ──
                        Row(
                           children: [
                              Expanded(
                                 child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                       _buildLabel('Start time'),
                                       const SizedBox(height: 8),
                                       GestureDetector(
                                          onTap: () => _selectTime(true),
                                          child: _buildInputField(
                                             child: Text(
                                                _startTime == null ? 'Choose time' : _startTime!.format(context).toLowerCase(),
                                                style: GoogleFonts.plusJakartaSans(
                                                   fontSize: 15,
                                                   color: _startTime == null ? Colors.grey[500] : Colors.black87,
                                                   fontWeight: _startTime == null ? FontWeight.w400 : FontWeight.w500,
                                                ),
                                             ),
                                             suffixIcon: Icons.access_time,
                                          ),
                                       ),
                                    ],
                                 )
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                 child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                       _buildLabel('End time'),
                                       const SizedBox(height: 8),
                                       GestureDetector(
                                          onTap: () => _selectTime(false),
                                          child: _buildInputField(
                                             child: Text(
                                                _endTime == null ? 'Choose time' : _endTime!.format(context).toLowerCase(),
                                                style: GoogleFonts.plusJakartaSans(
                                                   fontSize: 15,
                                                   color: _endTime == null ? Colors.grey[500] : Colors.black87,
                                                   fontWeight: _endTime == null ? FontWeight.w400 : FontWeight.w500,
                                                ),
                                             ),
                                             suffixIcon: Icons.access_time,
                                          ),
                                       ),
                                    ],
                                 )
                              ),
                           ],
                        ),
                        const SizedBox(height: 28),
          
                        // ── Vibes ──
                        _buildLabel("What's the vibe?"),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 12,
                          runSpacing: 12,
                          children: [
                            _buildVibePill('Chill'),
                            _buildVibePill('Active'),
                            _buildVibePill('Social'),
                            _buildVibePill('Fun'),
                            _buildVibePill('Productive'),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(color: const Color(0xFFFFB300)),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Icon(Icons.add, color: Colors.black, size: 20),
                            ),
                          ],
                        ),
                        const SizedBox(height: 28),
          
                        // ── How many people ──
                        _buildLabel("How many people?"),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF3D4), // exact light yellow bg
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              GestureDetector(
                                onTap: () {
                                  if (numPeople > 1) setState(() => numPeople--);
                                },
                                child: Container(
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFFFB300),
                                    shape: BoxShape.circle,
                                  ),
                                  padding: const EdgeInsets.all(6),
                                  child: const Icon(Icons.remove, color: Colors.black, size: 22),
                                ),
                              ),
                              Column(
                                children: [
                                  Text(
                                    numPeople.toString(),
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.black,
                                      height: 1.1,
                                    ),
                                  ),
                                  Text(
                                    'people',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFFFFB300),
                                    ),
                                  ),
                                ],
                              ),
                              GestureDetector(
                                onTap: () => setState(() => numPeople++),
                                child: Container(
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFFFB300),
                                    shape: BoxShape.circle,
                                  ),
                                  padding: const EdgeInsets.all(6),
                                  child: const Icon(Icons.add, color: Colors.black, size: 22),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 28),
          
                        // ── Public Toggle ──
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildLabel('Public?'),
                            Switch(
                              value: postToBoard,
                              onChanged: (val) => setState(() => postToBoard = val),
                              activeColor: const Color(0xFFFFB300),
                              activeTrackColor: const Color(0xFFFFB300).withValues(alpha: 0.3),
                              inactiveThumbColor: Colors.white,
                              inactiveTrackColor: Colors.grey[300],
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
          
                        // ── Post Section ──
                        SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: _isPosting ? null : _postSidequest,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFFFFB300),
                              disabledBackgroundColor: const Color(0xFFFFB300).withValues(alpha: 0.5),
                              padding: const EdgeInsets.symmetric(vertical: 22),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(6),
                              ),
                              elevation: 0,
                            ),
                            child: _isPosting
                                ? const SizedBox(
                                    width: 24,
                                    height: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.black,
                                      strokeWidth: 2.5,
                                    ),
                                  )
                                : Text(
                                    'Post Sidequest!',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w800,
                                      color: const Color(0xFF1E1E1E),
                                    ),
                                  ),
                          ),
                        ),
                        const SizedBox(height: 16),
          
                        // Cancel
                        Center(
                          child: TextButton(
                            onPressed: () => Navigator.pop(context),
                            style: TextButton.styleFrom(
                               foregroundColor: Colors.grey[600],
                            ),
                            child: Text(
                              'Cancel',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF5F5F5F),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ),
             ]
           )
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
     return Text(
         text,
         style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF1E1E1E),
         ),
     );
  }

  Widget _buildInputField({required Widget child, required IconData suffixIcon}) {
     return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
           color: Colors.white,
           border: Border.all(color: Colors.grey[300]!),
           borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
           children: [
              Expanded(child: child),
              Icon(suffixIcon, color: Colors.grey[600], size: 20),
           ],
        ),
     );
  }

  Widget _buildVibePill(String title) {
    bool isSelected = selectedVibe.toLowerCase() == title.toLowerCase();
    return GestureDetector(
      onTap: () => setState(() => selectedVibe = title.toLowerCase()),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? const Color(0xFFFFB300) : Colors.white,
          border: Border.all(color: const Color(0xFFFFB300)),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Text(
          title,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
            color: const Color(0xFF1E1E1E),
          ),
        ),
      ),
    );
  }
}

