import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/leaderboard_entry.dart';

class ApiService {
  // Change this to your backend URL
  // For web/Chrome: use localhost
  // For Android emulator: use 10.0.2.2
  // For iOS simulator: use localhost
  static const String baseUrl = 'http://localhost:8000';
  
  /// Fetch leaderboard from API
  static Future<List<LeaderboardEntry>> fetchLeaderboard({int limit = 10}) async {
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
