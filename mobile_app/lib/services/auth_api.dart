// lib/services/auth_api.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthApi {
  // static const String baseUrl = 'http://10.0.2.2:3000'; 
   static const String baseUrl = 'http://192.168.1.176:3000';

  // ---------- REGISTER ---------- (unchanged)
  static Future<void> register({
    required String name,
    required String email,
    required String password,
    required String role,
    required String disabilityType,
    String? grade,
  }) async {
    final url = Uri.parse('$baseUrl/api/auth/register');

    final Map<String, dynamic> body = {
      'name': name,
      'email': email,
      'password': password,
      'role': role,
      'disabilityType': disabilityType,
    };

    if (grade != null && grade.isNotEmpty) {
      body['grade'] = grade;
    }

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    if (response.statusCode != 201) {
      throw Exception("Registration failed: ${response.body}");
    }
  }

  // ---------- LOGIN ----------  ✅ fixed
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

    // backend: { success, data: { token, user }, message? }
    if (response.statusCode != 200 || json['success'] == false) {
      final msg = json['message'] ?? 'Login failed';
      throw Exception(msg);
    }

    final data = json['data'] as Map<String, dynamic>;
    return {'token': data['token'], 'user': data['user']};
  }
}
