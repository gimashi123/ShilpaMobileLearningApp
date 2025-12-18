import 'dart:io'; // For Platform check
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart'; // For kIsWeb check

class AuthApi {
  // Use 10.0.2.2 for Android Emulator to access host machine
  // Use localhost for iOS Simulator, Web, and Desktop
  static String get baseUrl {
    if (kIsWeb) return 'http://localhost:3000';
    if (Platform.isAndroid) return 'http://10.0.2.2:3000';
    return 'http://localhost:3000';
  }

  // ---------- REGISTER ----------
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

    print("AUTH: Sending register request to $url with body $body");

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      if (response.statusCode != 201) {
        print(
          "AUTH: Register failed [${response.statusCode}] ${response.body}",
        );
        throw Exception("Registration failed: ${response.body}");
      }
    } catch (e) {
      // Allow connection errors to bubble up, but log them
      print("AUTH: Network/Server error: $e");
      rethrow;
    }
  }

  // ---------- LOGIN ----------
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
