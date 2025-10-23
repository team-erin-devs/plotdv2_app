import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../models/challenge.dart';
import '../models/leaderboard_entry.dart';
import 'authenticated_api_service.dart';

class ApiService {
  /// Fetch today's active challenges (authenticated)
  static Future<List<Challenge>> fetchChallenge() async {
    try {
      print('🔵 Attempting to fetch challenges with auth...');

      final response = await AuthenticatedApiService.authenticatedGet(
        '/api/challenges/',
      );

      print('🔵 Response status: ${response.statusCode}');
      print('🔵 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        print('🔵 Parsed JSON: $jsonData');

        List challengeData = jsonData is Map && jsonData.containsKey('results')
            ? jsonData['results']
            : jsonData;

        print('🔵 Challenge data count: ${challengeData.length}');

        return challengeData.map((data) {
          print('🔵 Parsing challenge: ${data['title']}');
          return Challenge(
            id: data['id'].toString(),
            title: data['title'] ?? '',
            description: data['description'] ?? '',
            difficulty: ChallengeDifficulty.easy,
            points: data['points'] ?? 0,
          );
        }).toList();
      } else {
        throw Exception('Failed to fetch challenges: ${response.statusCode}');
      }
    } catch (e, stackTrace) {
      print('🔴 ERROR in fetchChallenge: $e');
      print('🔴 Stack trace: $stackTrace');
      rethrow;
    }
  }

  /// Fetch leaderboard (authenticated)
  static Future<List<LeaderboardEntry>> fetchLeaderboard({
    int limit = 10,
  }) async {
    try {
      final response = await AuthenticatedApiService.authenticatedGet(
        '/api/leaderboard/?limit=$limit',
      );

      print('🔵 Leaderboard response status: ${response.statusCode}');
      print('🔵 Leaderboard response body: ${response.body}');

      if (response.statusCode != 200) {
        throw Exception('Failed to load leaderboard: ${response.statusCode}');
      }

      final List<dynamic> data = json.decode(response.body);

      for (var entry in data) {
        print('🔵 Leaderboard entry: $entry');
      }

      return data.map((json) => LeaderboardEntry.fromJson(json)).toList();
    } catch (e, stack) {
      print('🔴 ERROR in fetchLeaderboard: $e');
      print('🔴 Stack trace: $stack');
      rethrow;
    }
  }

  /// Upload a media file to the server
  static Future<String> uploadMedia(XFile mediaFile) async {
    try {
      print('🔵 Uploading media: ${mediaFile.path}');
      
      // Get the access token
      final token = await AuthenticatedApiService.getAccessToken();
      if (token == null) {
        throw Exception('No access token available');
      }

      // Create multipart request
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('${AuthenticatedApiService.baseUrl}/api/upload/'),
      );

      // Add authorization header
      request.headers['Authorization'] = 'Bearer $token';

      // Add the media file
      final file = await http.MultipartFile.fromPath(
        'media',
        mediaFile.path,
        filename: mediaFile.name,
      );
      request.files.add(file);

      // Send the request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('🔵 Upload response status: ${response.statusCode}');
      print('🔵 Upload response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        final mediaUrl = data['media_url'] ?? data['url'] ?? data['image_url'];
        if (mediaUrl != null) {
          print('🔵 Media uploaded successfully: $mediaUrl');
          return mediaUrl;
        } else {
          throw Exception('No media URL returned from server');
        }
      } else {
        throw Exception('Failed to upload media: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('🔴 ERROR in uploadMedia: $e');
      rethrow;
    }
  }

  /// Upload multiple media files and return their URLs
  static Future<List<String>> uploadMediaFiles(List<XFile> mediaFiles) async {
    try {
      print('🔵 Uploading ${mediaFiles.length} media files');
      
      final List<String> mediaUrls = [];
      
      for (int i = 0; i < mediaFiles.length; i++) {
        print('🔵 Uploading media ${i + 1}/${mediaFiles.length}');
        final mediaUrl = await uploadMedia(mediaFiles[i]);
        mediaUrls.add(mediaUrl);
      }
      
      print('🔵 All media files uploaded successfully: $mediaUrls');
      return mediaUrls;
    } catch (e) {
      print('🔴 ERROR in uploadMediaFiles: $e');
      rethrow;
    }
  }

  /// Submit a challenge completion (authenticated)
  static Future<Map<String, dynamic>> submitChallenge({
    required String challengeId,
    required String proofImageUrl,
  }) async {
    try {
      final response = await AuthenticatedApiService.authenticatedPost(
        '/api/challenges/$challengeId/submit/',
        {'proof_image_url': proofImageUrl},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        return json.decode(response.body);
      } else {
        throw Exception('Failed to submit challenge: ${response.statusCode}');
      }
    } catch (e) {
      print('🔴 ERROR in submitChallenge: $e');
      rethrow;
    }
  }

  /// Submit a challenge completion with multiple media files
  static Future<Map<String, dynamic>> submitChallengeWithMedia({
    required String challengeId,
    required List<XFile> mediaFiles,
  }) async {
    try {
      print('🔵 Submitting challenge $challengeId with ${mediaFiles.length} media files');
      
      // Upload all media files first
      final mediaUrls = await uploadMediaFiles(mediaFiles);
      
      // Submit challenge with the first media URL (or you can modify this to handle multiple URLs)
      final result = await submitChallenge(
        challengeId: challengeId,
        proofImageUrl: mediaUrls.first,
      );
      
      print('🔵 Challenge submitted successfully');
      return result;
    } catch (e) {
      print('🔴 ERROR in submitChallengeWithMedia: $e');
      rethrow;
    }
  }

  /// Health check endpoint (no auth needed)
  static Future<bool> checkHealth() async {
    try {
      final response = await http.get(
        Uri.parse('${AuthenticatedApiService.baseUrl}/api/health/'),
      );
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  /// Check if user is authenticated
  static Future<bool> isAuthenticated() async {
    final token = await AuthenticatedApiService.getAccessToken();
    return token != null && token.isNotEmpty;
  }

  /// Logout user
  static Future<void> logout() async {
    await AuthenticatedApiService.clearTokens();
  }
}
