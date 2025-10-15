import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/challenge.dart';
import '../models/leaderboard_entry.dart';

class ApiService {
  // Change this to your backend URL
  // For web/Chrome: use localhost
  // For Android emulator: use 10.0.2.2
  // For iOS simulator: use localhost
  static const String baseUrl = 'http://localhost:8000';

  /// Fetch today's active challenges (filtered by Django backend)
  static Future<List<Challenge>> fetchChallenge() async {
    try {
      print('🔵 Attempting to fetch from: $baseUrl/api/challenges/');

      final response = await http.get(Uri.parse('$baseUrl/api/challenges/'));

      print('🔵 Response status: ${response.statusCode}');
      print('🔵 Response body: ${response.body}');

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);

        print('🔵 Parsed JSON: $jsonData');

        // Handle paginated response from Django REST Framework
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
            difficulty: ChallengeDifficulty.easy, // Default difficulty
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

  /// Fetch leaderboard from API
  static Future<List<LeaderboardEntry>> fetchLeaderboard({
    int limit = 10,
  }) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/leaderboard/?limit=$limit'),
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        return data.map((json) => LeaderboardEntry.fromJson(json)).toList();
      } else {
        throw Exception('Failed to load leaderboard: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching leaderboard: $e');
    }
  }

  /// Health check endpoint
  static Future<bool> checkHealth() async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/api/health/'));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }
}
