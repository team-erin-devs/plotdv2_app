import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthService {
  static const String baseUrl = 'http://localhost:8000/api/auth';

  Future<Map<String, dynamic>> register({
    required String username,
    required String email,
    required String password,
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
        'university': university,
        'student_id': studentId,
      }),
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body);
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

      //save the tokens locally on device - so that the user doesn't need to login everytime they reopen the app
      final tokens = data['tokens'];
      if (tokens != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('access_token', tokens['access'] ?? '');
        await prefs.setString('refresh_token', tokens['refresh'] ?? '');
      }

      return data;
    } else {
      throw Exception('Login failed: ${response.body}');
    }
  }
}
