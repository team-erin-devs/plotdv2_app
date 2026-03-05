import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'authenticated_api_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class AuthService {
  // Use http://10.0.2.2:8000/api/auth for Android emulator, and http://127.0.0.1:8000/api/auth for iOS Simulator/Web
  static final String baseUrl = dotenv.env['API_BASE_URL'] ?? 'http://127.0.0.1:8000/api/auth';

  Future<Map<String, dynamic>> register({
    required String username,
    required String email,
    required String password,
    String? name,
    String? university,
    String? studentId,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/register/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'email': email,
        'password': password,
        if (name != null && name.isNotEmpty) 'name': name,
      }),
    );

    if (response.statusCode == 201) {
      final data = jsonDecode(response.body);

      final accessToken = data['access_token'];
      final refreshToken = data['refresh_token'];
      final user = data['user'];

      if (accessToken != null && refreshToken != null) {
        await AuthenticatedApiService.saveTokens(
          accessToken: accessToken,
          refreshToken: refreshToken,
        );

        if (user != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('user_info', jsonEncode(user));
        }

        print('✅ Registration tokens saved successfully!');
      }

      return data;
    } else {
      throw Exception('Registration failed: ${response.body}');
    }
  }

  Future<Map<String, dynamic>> login({
    required String username,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/login/'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'username': username, 'password': password}),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);

      // ✅ Django returns tokens inside a 'tokens' object
      final accessToken = data['access_token'];
      final refreshToken = data['refresh_token'];
      final user = data['user'];

      if (accessToken != null && refreshToken != null) {
        await AuthenticatedApiService.saveTokens(
          accessToken: accessToken,
          refreshToken: refreshToken,
        );

        if (user != null) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setString('user_info', jsonEncode(user));
        }

        print('✅ Login tokens saved successfully!');
      }

      return data;
    } else {
      throw Exception('Login failed: ${response.body}');
    }
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('access_token');
    await prefs.remove('refresh_token');
    await prefs.remove('user_info');
  }

  static Future<bool> isAuthenticated() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    return token != null && token.isNotEmpty;
  }
}
