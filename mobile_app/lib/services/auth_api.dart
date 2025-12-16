// lib/services/auth_api.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthApi {
  // Android emulator → 10.0.2.2, change port if needed
  static const String baseUrl = 'http://10.0.2.2:3000';

  // ---------- REGISTER ----------
  static Future<void> register({
    required String name,
    required String email,
    required String password,
    required String role,
    required String disabilityType,
  }) async {
    final url = Uri.parse('$baseUrl/api/auth/register');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'name': name,
        'email': email,
        'password': password,
        'role': role,
        'disabilityType': disabilityType,
      }),
    );

    if (response.statusCode != 201) {
      throw Exception("Registration failed: ${response.body}");
    }
  }

  static Map<String, dynamic>? currentUser;

  // ---------- LOGIN ----------
  /// Returns {"token": String, "user": Map}
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final url = Uri.parse('$baseUrl/api/auth/login');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'email': email, 'password': password}),
    );

    final json = jsonDecode(response.body);

    if (response.statusCode != 200 && response.statusCode != 201) {
      throw Exception(json['message'] ?? 'Login failed');
    }

    return {'token': json['data']['token'], 'user': json['data']['user']};
  }

  static void logout() {
    currentUser = null;
  }
}
