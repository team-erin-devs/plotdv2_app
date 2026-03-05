import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';
import '../services/authenticated_api_service.dart';
import '../services/upload_service.dart';
import '../widgets/bouncing_button.dart';

class PastSidequestScreen extends StatefulWidget {
  final int sidequestId;

  const PastSidequestScreen({super.key, required this.sidequestId});

  @override
  State<PastSidequestScreen> createState() => _PastSidequestScreenState();
}

class _PastSidequestScreenState extends State<PastSidequestScreen> {
  bool _isLoading = true;
  Map<String, dynamic>? _sidequestData;
  int _currentRating = 0; // Current rated stars
  bool _isRatingSending = false;
  int _currentImageIndex = 0;
  bool _isUploadingImage = false;

  @override
  void initState() {
    super.initState();
    _loadSidequest();
  }

  Future<void> _loadSidequest() async {
    setState(() => _isLoading = true);
    try {
      final res = await AuthenticatedApiService.authenticatedGet('/api/sidequests/${widget.sidequestId}/');
      if (res.statusCode == 200) {
        final decoded = jsonDecode(res.body);
        _sidequestData = decoded;
        
        // Find if this user already rated the sidequest
        final participants = decoded['participants'] as List? ?? [];
        for (var p in participants) {
          if (p['user'] != null && p['status'] == 'going') {
            // Find current user's rating (naive lookup: first user we find that matches the current session context - ideally we'd compare our ID)
            // But since the API participant list has `rating` and `user` dict, we can look up the user ID if we had it.
            // A simpler way: since we're fetching from authenticatedGet, we parse our own ID from UserStats or assume it matches.
            // For now, let's see if the API can return `user_status` with rating, or we just look up the `user_status` dictionary.
            // We just grab the rating if it's there for us. We'll refine this later.
          }
        }

        // Just fetching my own profile or matching username to grab rating
        final myProfileRes = await AuthenticatedApiService.authenticatedGet('/api/user/profile/');
        if (myProfileRes.statusCode == 200) {
           final myUsername = jsonDecode(myProfileRes.body)['user']?['username'];
           for (var p in participants) {
             if (p['user']?['username'] == myUsername) {
               _currentRating = p['rating'] ?? 0;
               break;
             }
           }
        }
      } else {
        debugPrint('🔴 Error loading sidequest: ${res.statusCode}');
      }
    } catch (e) {
      debugPrint('🔴 Exception loading sidequest: $e');
    }
    if (mounted) setState(() => _isLoading = false);
  }

  Future<void> _handleRating(int rating) async {
    if (_isRatingSending) return;
    setState(() => _isRatingSending = true);

    try {
      final res = await AuthenticatedApiService.authenticatedPost(
        '/api/sidequests/${widget.sidequestId}/rate/',
        {'rating': rating},
      );
      if (res.statusCode == 200) {
        setState(() => _currentRating = rating);
      } else {
        final err = jsonDecode(res.body)['detail'] ?? 'Error saving rating';
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
      }
    } catch (e) {
       if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error saving rating: $e')));
    }

    if (mounted) setState(() => _isRatingSending = false);
  }

  Future<void> _uploadImage() async {
    if (_isUploadingImage) return;
    
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);
    if (pickedFile == null) return;

    setState(() => _isUploadingImage = true);

    try {
      final String filename = pickedFile.name;
      final mimeType = lookupMimeType(pickedFile.path) ?? 'image/jpeg';
      
      // 1. Get Presigned URL
      final presignRes = await AuthenticatedApiService.authenticatedPost(
        '/api/sidequests/${widget.sidequestId}/image-presign/',
        {'filename': filename},
      );
      
      if (presignRes.statusCode != 200) {
         throw Exception('Failed to get presigned URL: ${presignRes.body}');
      }
      
      final presignData = jsonDecode(presignRes.body);
      final presignedUrl = presignData['presigned_url'];
      final fileUrl = presignData['file_url'];

      // 2. Upload file bytes directly to B2
      final bytes = await pickedFile.readAsBytes();
      
      // Use the existing UploadService which properly handles Dio headers for AWS Signature
      await UploadService.uploadToBackblaze(
        presignedUrl: presignedUrl, 
        bytes: bytes, 
        contentType: mimeType
      );

      // 3. Register image with Sidequest backend
      final addRes = await AuthenticatedApiService.authenticatedPost(
        '/api/sidequests/${widget.sidequestId}/add-image/',
        {'file_url': fileUrl},
      );
      
      if (addRes.statusCode == 200) {
        // Success, refresh the sidequest data
        await _loadSidequest();
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Image uploaded! 🎉')));
      } else {
        throw Exception('Failed to link image: ${addRes.body}');
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error uploading image: $e')));
    } finally {
      if (mounted) setState(() => _isUploadingImage = false);
    }
  }

  Widget _buildRatingAsterisks() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        final isFilled = index < _currentRating;
        return BouncingButton(
          onPressed: () => _handleRating(index + 1),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4.0),
            child: SvgPicture.asset(
              'assets/images/asterik.svg',
              width: 48,
              height: 48,
              theme: SvgTheme(currentColor: isFilled ? const Color(0xFFFFB300) : Colors.grey[300]!),
            ),
          ),
        );
      }),
    );
  }

  Widget _buildImageCarousel(List images) {
    if (images.isEmpty) {
      return Container(
        height: 300,
        decoration: BoxDecoration(
          color: Colors.grey[200],
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.center,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.image_not_supported, size: 48, color: Colors.grey[400]),
            const SizedBox(height: 8),
            Text(
              'no images available.\ntap "upload images" below to add.',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        SizedBox(
          height: 350,
          child: PageView.builder(
            itemCount: images.length,
            onPageChanged: (idx) => setState(() => _currentImageIndex = idx),
            itemBuilder: (context, index) {
              final imgUrl = images[index].toString();
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  image: DecorationImage(
                    image: (imgUrl.startsWith('images/') || imgUrl.startsWith('assets/images/'))
                        ? AssetImage(imgUrl.startsWith('images/') ? 'assets/$imgUrl' : imgUrl)
                        : NetworkImage(imgUrl) as ImageProvider,
                    fit: BoxFit.cover,
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        // Dots
        if (images.length > 1)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(images.length, (index) {
              final active = index == _currentImageIndex;
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 4),
                width: 8,
                height: 8,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: active ? const Color(0xFF64A8DB) : Colors.grey[300],
                ),
              );
            }),
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        backgroundColor: Color(0xFFF8F4F0),
        body: Center(child: CircularProgressIndicator(color: Color(0xFFE8837C))),
      );
    }

    if (_sidequestData == null) {
       return Scaffold(
        backgroundColor: const Color(0xFFF8F4F0),
        body: Center(
          child: Text('could not load sidequest', style: GoogleFonts.plusJakartaSans(fontSize: 16)),
        ),
      );
    }

    final sq = _sidequestData!;
    final title = sq['title'] ?? 'untitled';
    final creator = sq['creator']?['username'] ?? 'unknown';
    final images = sq['images'] as List? ?? [];
    
    // Parse participants string "with Lukas, Sindu, Moon, ..."
    final participantsList = sq['participants'] as List? ?? [];
    final goingNames = participantsList
        .where((p) => p['status'] == 'going')
        .map((p) => (p['user']?['first_name']?.toString().isNotEmpty == true) 
             ? p['user']['first_name'].toString() 
             : p['user']?['username']?.toString() ?? 'unknown')
        .toList();
    
    String attendeesString = '';
    if (goingNames.isNotEmpty) {
      if (goingNames.length == 1) {
        attendeesString = goingNames.first;
      } else if (goingNames.length == 2) {
        attendeesString = '${goingNames.first} and ${goingNames.last}';
      } else {
        final everyoneElse = goingNames.sublist(0, goingNames.length - 1).join(', ');
        attendeesString = '$everyoneElse, and ${goingNames.last}';
      }
    }

    // Parse time
    final dtStr = sq['event_datetime'];
    final endDtStr = sq['end_datetime'];
    String dateFormatted = '';
    String timeFormatted = '';
    
    if (dtStr != null) {
      final dt = DateTime.parse(dtStr).toLocal();
      dateFormatted = DateFormat("MMMM d'th', yyyy").format(dt);
      
      // Fix 'th/st/nd/rd' formatting manually
      final day = dt.day;
      String suffix = 'th';
      if (day % 10 == 1 && day != 11) suffix = 'st';
      else if (day % 10 == 2 && day != 12) suffix = 'nd';
      else if (day % 10 == 3 && day != 13) suffix = 'rd';
      dateFormatted = DateFormat("MMMM d").format(dt) + "$suffix, ${dt.year}";

      timeFormatted = DateFormat('h:mm').format(dt);
      
      if (endDtStr != null) {
        final et = DateTime.parse(endDtStr).toLocal();
        timeFormatted += ' - ${DateFormat('h:mm a').format(et)}';
      } else {
        timeFormatted += ' ${DateFormat('a').format(dt)}';
      }
    }

    final vibe = sq['vibe'] ?? '';
    final location = sq['location']?.toString() ?? '';

    return Scaffold(
      backgroundColor: const Color(0xFFF8F4F0),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black87, size: 24),
          onPressed: () => Navigator.pop(context),
        ),
        title: Image.asset(
          'assets/images/plotd-title.png',
          height: 32,
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: Colors.black,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'hosted by $creator',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: Colors.black87,
              ),
            ),
            
            const SizedBox(height: 24),
            _buildImageCarousel(images),
            
            const SizedBox(height: 24),
            if (attendeesString.isNotEmpty)
              RichText(
                text: TextSpan(
                  text: 'with ',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w400,
                    color: Colors.black87,
                  ),
                  children: [
                    TextSpan(
                      text: attendeesString,
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),

            const SizedBox(height: 16),
            // Tags Row
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (vibe.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFFB300), // generic yellow
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      vibe.toString().toLowerCase(),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),

            const SizedBox(height: 20),
            // Date / Time
            Row(
              children: [
                const Icon(Icons.calendar_today_outlined, size: 20, color: Colors.black54),
                const SizedBox(width: 8),
                Text(
                  dateFormatted,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black54,
                  ),
                ),
                const SizedBox(width: 16),
                const Icon(Icons.access_time, size: 20, color: Colors.black54),
                const SizedBox(width: 8),
                Text(
                  timeFormatted.toLowerCase(),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black54,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (location.isNotEmpty)
              Row(
                children: [
                   const Icon(Icons.location_on_outlined, size: 20, color: Colors.black54),
                   const SizedBox(width: 8),
                   Expanded(
                     child: Text(
                       location,
                       style: GoogleFonts.plusJakartaSans(
                         fontSize: 14,
                         fontWeight: FontWeight.w500,
                         color: Colors.black54,
                       ),
                     ),
                   ),
                ],
              ),
              
            const SizedBox(height: 60),
            _buildRatingAsterisks(),
            
            const SizedBox(height: 60),
            
            // Upload Button
            SizedBox(
              width: double.infinity,
              child: BouncingButton(
                child: ElevatedButton(
                  onPressed: _isUploadingImage ? null : _uploadImage,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF64A8DB),
                    disabledBackgroundColor: const Color(0xFF64A8DB).withOpacity(0.5),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: _isUploadingImage
                      ? const SizedBox(
                          height: 20, width: 20, 
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                        )
                      : Text(
                          'Upload Images',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
