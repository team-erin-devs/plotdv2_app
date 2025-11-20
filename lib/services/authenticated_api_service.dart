import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// Base class for making authenticated API calls
class AuthenticatedApiService {
  static const String baseUrl = 'http://localhost:8000';

  /// Get the stored access token
  static Future<String?> getAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('access_token');
  }

  /// Get the stored refresh token
  static Future<String?> getRefreshToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('refresh_token');
  }

  /// Save new tokens to storage
  static Future<void> saveTokens({
    required String accessToken,
    required String refreshToken,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('access_token', accessToken);
    await prefs.setString('refresh_token', refreshToken);
  }

  /// Clear stored tokens (for logout)
  static Future<void> clearTokens() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('refresh_token');
  }

  /// Get headers with authentication
  static Future<Map<String, String>> getAuthHeaders() async {
    final token = await getAccessToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  /// Refresh the access token using the refresh token
  static Future<bool> refreshAccessToken() async {
    try {
      final refreshToken = await getRefreshToken();
      if (refreshToken == null) return false;

      final response = await http.post(
        Uri.parse('$baseUrl/api/auth/token/refresh/'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'refresh': refreshToken}),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final newAccessToken = data['access'];
        if (newAccessToken != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('access_token', newAccessToken);
          return true;
        }
      }
      return false;
    } catch (e) {
      return false;
    }
  }

  /// Make an authenticated GET request
  static Future<http.Response> authenticatedGet(String endpoint) async {
    final headers = await getAuthHeaders();
    final response = await http.get(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
    );

    // If unauthorized, try to refresh token and retry
    if (response.statusCode == 401) {
      final refreshed = await refreshAccessToken();
      if (refreshed) {
        final newHeaders = await getAuthHeaders();
        return await http.get(
          Uri.parse('$baseUrl$endpoint'),
          headers: newHeaders,
        );
      }
    }

    return response;
  }

  /// Make an authenticated POST request
  static Future<http.Response> authenticatedPost(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    final headers = await getAuthHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
      body: jsonEncode(body),
    );

    // If unauthorized, try to refresh token and retry
    if (response.statusCode == 401) {
      final refreshed = await refreshAccessToken();
      if (refreshed) {
        final newHeaders = await getAuthHeaders();
        return await http.post(
          Uri.parse('$baseUrl$endpoint'),
          headers: newHeaders,
          body: jsonEncode(body),
        );
      }
    }

    return response;
  }

  /// Make an authenticated PUT request
  static Future<http.Response> authenticatedPut(
    String endpoint,
    Map<String, dynamic> body,
  ) async {
    final headers = await getAuthHeaders();
    final response = await http.put(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
      body: jsonEncode(body),
    );

    if (response.statusCode == 401) {
      final refreshed = await refreshAccessToken();
      if (refreshed) {
        final newHeaders = await getAuthHeaders();
        return await http.put(
          Uri.parse('$baseUrl$endpoint'),
          headers: newHeaders,
          body: jsonEncode(body),
        );
      }
    }

    return response;
  }

  /// Make an authenticated DELETE request
  static Future<http.Response> authenticatedDelete(String endpoint) async {
    final headers = await getAuthHeaders();
    final response = await http.delete(
      Uri.parse('$baseUrl$endpoint'),
      headers: headers,
    );

    if (response.statusCode == 401) {
      final refreshed = await refreshAccessToken();
      if (refreshed) {
        final newHeaders = await getAuthHeaders();
        return await http.delete(
          Uri.parse('$baseUrl$endpoint'),
          headers: newHeaders,
        );
      }
    }

    return response;
  }

  /// Get current user's stats
  static Future<Map<String, dynamic>> getUserStats() async {
    final response = await authenticatedGet('/api/user/stats/');
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load user stats: ${response.statusCode}');
    }
  }

  /// Get current user's information
  static Future<Map<String, dynamic>> getCurrentUser() async {
    // First get the user ID from the token or make a request
    // For now, we'll decode it from the user info in local storage
    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('user_info');
    
    if (userJson != null) {
      return jsonDecode(userJson);
    }
    
    throw Exception('User information not found. Please log in again.');
  }

  /// Get current user's proof submissions
  static Future<List<dynamic>> getUserProofs() async {
    final response = await authenticatedGet('/api/proofs/');
    
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      // Handle both array response and paginated response
      if (data is List) {
        return data;
      } else if (data is Map && data.containsKey('results')) {
        return data['results'];
      }
      return [];
    } else {
      throw Exception('Failed to load user proofs: ${response.statusCode}');
    }
  }

  /// Get current user's profile including bio, major, class_year, etc.
  static Future<Map<String, dynamic>> getUserProfile() async {
    final response = await authenticatedGet('/api/user/profile/');
    
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load user profile: ${response.statusCode}');
    }
  }

  /// Update current user's profile
  static Future<Map<String, dynamic>> updateUserProfile({
    String? bio,
    String? major,
    String? classYear,
    String? profilePicture,
    String? university,
  }) async {
    final Map<String, dynamic> updateData = {};
    
    if (bio != null) updateData['bio'] = bio;
    if (major != null) updateData['major'] = major;
    if (classYear != null) updateData['class_year'] = classYear;
    if (profilePicture != null) updateData['profile_picture'] = profilePicture;
    if (university != null) updateData['university'] = university;

    final headers = await getAuthHeaders();
    final response = await http.patch(
      Uri.parse('$baseUrl/api/user/profile/'),
      headers: headers,
      body: jsonEncode(updateData),
    );

    // If unauthorized, try to refresh token and retry
    if (response.statusCode == 401) {
      final refreshed = await refreshAccessToken();
      if (refreshed) {
        final newHeaders = await getAuthHeaders();
        final retryResponse = await http.patch(
          Uri.parse('$baseUrl/api/user/profile/'),
          headers: newHeaders,
          body: jsonEncode(updateData),
        );
        
        if (retryResponse.statusCode == 200) {
          return jsonDecode(retryResponse.body);
        } else {
          throw Exception('Failed to update profile: ${retryResponse.statusCode}');
        }
      }
    }

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to update profile: ${response.statusCode} - ${response.body}');
    }
  }

  /// Get presigned URL for profile picture upload
  static Future<Map<String, dynamic>> getProfilePicturePresignedUrl({
    required String filename,
  }) async {
    final headers = await getAuthHeaders();
    final response = await http.post(
      Uri.parse('$baseUrl/api/profile-picture/presign/'),
      headers: headers,
      body: jsonEncode({'filename': filename}),
    );

    if (response.statusCode == 401) {
      final refreshed = await refreshAccessToken();
      if (refreshed) {
        final newHeaders = await getAuthHeaders();
        final retryResponse = await http.post(
          Uri.parse('$baseUrl/api/profile-picture/presign/'),
          headers: newHeaders,
          body: jsonEncode({'filename': filename}),
        );
        
        if (retryResponse.statusCode == 200) {
          return jsonDecode(retryResponse.body);
        } else {
          throw Exception('Failed to get presigned URL: ${retryResponse.statusCode}');
        }
      }
    }

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to get presigned URL: ${response.statusCode} - ${response.body}');
    }
  }
}
