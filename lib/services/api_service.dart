import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import '../models/challenge.dart';
import '../models/leaderboard_entry.dart';
import 'authenticated_api_service.dart';

class ApiService {
  static final String baseUrl = AuthenticatedApiService.baseUrl;
  
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

  /// Upload a file as proof for a challenge
  static Future<Map<String, dynamic>> uploadProof({
    required String challengeId,
    required XFile file,
    String? description,
  }) async {
    try {
      print('🔵 Uploading proof for challenge: $challengeId');
      print('🔵 File path: ${file.path}');
      
      // Check if user is authenticated
      final token = await AuthenticatedApiService.getAccessToken();
      if (token == null || token.isEmpty) {
        throw Exception('User not authenticated. Please log in first.');
      }
      
      // Create multipart request
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/api/challenges/$challengeId/upload/'),
      );

      // Add Bearer token authentication
      request.headers['Authorization'] = 'Bearer $token';

      // Add the file
      final http.MultipartFile multipartFile;
      if (kIsWeb) {
        final bytes = await file.readAsBytes();
        multipartFile = http.MultipartFile.fromBytes(
          'file',
          bytes,
          filename: file.name,
        );
      } else {
        multipartFile = await http.MultipartFile.fromPath(
          'file',
          file.path,
          filename: file.name,
        );
      }
      request.files.add(multipartFile);

      // Add description if provided
      if (description != null && description.isNotEmpty) {
        request.fields['description'] = description;
      }

      // Send the request
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('🔵 Upload response status: ${response.statusCode}');
      print('🔵 Upload response body: ${response.body}');

      if (response.statusCode == 200 || response.statusCode == 201) {
        final data = json.decode(response.body);
        print('🔵 Proof uploaded successfully');
        return data;
      } else {
        throw Exception('Failed to upload proof: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('🔴 ERROR in uploadProof: $e');
      rethrow;
    }
  }

  /// Get user's submitted proofs
  static Future<List<Map<String, dynamic>>> getUserProofs() async {
    try {
      // Check if user is authenticated
      final token = await AuthenticatedApiService.getAccessToken();
      if (token == null || token.isEmpty) {
        throw Exception('User not authenticated. Please log in first.');
      }
      
      final response = await http.get(
        Uri.parse('$baseUrl/api/proofs/'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.cast<Map<String, dynamic>>();
      } else {
        throw Exception('Failed to fetch proofs: ${response.statusCode}');
      }
    } catch (e) {
      print('🔴 ERROR in getUserProofs: $e');
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
