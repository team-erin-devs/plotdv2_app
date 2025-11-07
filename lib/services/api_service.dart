import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:team_erin_app/models/user_profile.dart';
import '../models/challenge.dart';
import '../models/leaderboard_entry.dart';
import '../models/user.dart';
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

        ChallengeDifficulty _parseDifficulty(dynamic raw, int? points) {
          // If backend provides a field, try direct parse first
          if (raw != null) {
            if (raw is Enum) {
              final n = raw.name.toLowerCase();
              if (n == 'easy') return ChallengeDifficulty.easy;
              if (n == 'medium') return ChallengeDifficulty.medium;
              if (n == 'hard') return ChallengeDifficulty.hard;
            }
            if (raw is String) {
              final tail = raw.contains('.') ? raw.split('.').last : raw;
              final n = tail.trim().toLowerCase();
              if (n == 'easy') return ChallengeDifficulty.easy;
              if (n == 'medium') return ChallengeDifficulty.medium;
              if (n == 'hard') return ChallengeDifficulty.hard;
              final asInt = int.tryParse(n);
              if (asInt != null) {
                if (asInt == 1) return ChallengeDifficulty.easy;
                if (asInt == 2) return ChallengeDifficulty.medium;
                if (asInt == 3) return ChallengeDifficulty.hard;
              }
            }
            if (raw is int) {
              if (raw == 1) return ChallengeDifficulty.easy;
              if (raw == 2) return ChallengeDifficulty.medium;
              if (raw == 3) return ChallengeDifficulty.hard;
            }
          }

          // Fallback: derive from points if difficulty absent
          if (points != null) {
            if (points >= 20) return ChallengeDifficulty.hard;
            if (points >= 10) return ChallengeDifficulty.medium;
            return ChallengeDifficulty.easy;
          }

          // Final fallback
          return ChallengeDifficulty.easy;
        }

        return challengeData.map((data) {
          // Be lenient with types
          final int? points = () {
            final v = data['points'];
            if (v is int) return v;
            return int.tryParse(v?.toString() ?? '');
          }();

          final dynamic rawDiff =
          data['difficulty'] ?? data['difficulty_label'] ?? data['difficultyLabel'] ?? data['level'];

          final diff = _parseDifficulty(rawDiff, points);

          print('🔵 Parsing challenge: ${data['title']}');
          return Challenge(
            id: data['id'].toString(),
            title: (data['title'] ?? '').toString(),
            description: (data['description'] ?? '').toString(),
            difficulty: diff,
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

  // Fetch user profile
  static Future<UserProfile> fetchUserProfile() async {
  try {
    print('🔵 Attempting to fetch user profile with auth...');
    
    // Add these debug lines:
    final token = await AuthenticatedApiService.getAccessToken();
    final headers = await AuthenticatedApiService.getAuthHeaders();
    print('🔑 Token exists: ${token != null}');
    print('🔑 Headers: $headers');
    
    final response = await AuthenticatedApiService.authenticatedGet(
      '/api/user/profile/',
    );

    print('🔵 Profile response status: ${response.statusCode}');
    print('🔵 Profile response headers: ${response.headers}');
    print('🔵 Profile response body: ${response.body}');

    if (response.statusCode == 200) {
      final Map<String, dynamic> data = json.decode(response.body);
      print('🔵 Parsed JSON data: $data');
      return UserProfile.fromJson(data);
    } else {
      throw Exception('Failed to load user profile: ${response.statusCode}');
    }
  } catch (e) {
    print('🔴 ERROR in fetchUserProfile: $e');
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
