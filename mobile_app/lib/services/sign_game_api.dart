import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mobile_app/config/AppConfig.dart';

class SignGameApi {
  static final String baseUrl = AppConfig.apiBaseUrl;

  /// Fetch the student's current difficulty level based on recent history
  static Future<int> getLevel(String token, String disabilityType) async {
    final url = Uri.parse(
        '$baseUrl/api/sign-game/level?disabilityType=$disabilityType');

    try {
      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        if (json['success'] == true) {
          return json['data']['currentLevel'] ?? 1;
        }
      }
      return 1; // Fallback to level 1
    } catch (e) {
      print("Error fetching sign game level: $e");
      return 1; // Fallback
    }
  }

  /// Save the completed quiz history
  static Future<Map<String, dynamic>> saveHistory({
    required String token,
    required String disabilityType,
    required int difficultyLevel,
    required int totalQuestions,
    required int correctCount,
    required List<Map<String, dynamic>> questions,
  }) async {
    final url = Uri.parse('$baseUrl/api/sign-game/history');

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'disabilityType': disabilityType,
          'difficultyLevel': difficultyLevel,
          'totalQuestions': totalQuestions,
          'correctCount': correctCount,
          'questions': questions,
        }),
      );

      if (response.statusCode == 201) {
        final json = jsonDecode(response.body);
        return {
          'success': true,
          'xpGained': json['data']['xpGained'] ?? 0,
          'totalXp': json['data']['totalXp'] ?? 0,
        };
      } else {
        print("Failed to save sign game history: ${response.body}");
        return {'success': false, 'xpGained': 0, 'totalXp': 0};
      }
    } catch (e) {
      print("Error saving sign game history: $e");
      return {'success': false, 'xpGained': 0, 'totalXp': 0};
    }
  }
}
