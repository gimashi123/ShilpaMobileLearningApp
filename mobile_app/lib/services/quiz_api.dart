import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mobile_app/config/AppConfig.dart';
import 'package:mobile_app/models/quiz.dart';



class QuizApi {
  static const String baseUrl = "http://192.168.1.101:3000/api/quizzes";

  static Future<List<Quiz>> fetchRandomQuizzes({
    required String grade,
    required String type,
  }) async {
    final uri = Uri.parse("$baseUrl/api/quizzes/random?grade=$grade&type=$type");

    final response = await http.get(uri);

    if (response.statusCode != 200) {
      throw Exception("Failed to load quizzes");
    }

    final data = jsonDecode(response.body);
    final List list = (data["quizzes"] ?? []) as List;

    return list.map((q) => Quiz.fromJson(q as Map<String, dynamic>)).toList();
  }

  static Future<Map<String, dynamic>> checkAnswer({
    required String quizId,
    required String userAnswer,
  }) async {
    final uri = Uri.parse("$baseUrl/check/$quizId");

    final response = await http.post(
      uri,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"userAnswer": userAnswer}),
    );

    if (response.statusCode != 200) {
      throw Exception("Failed to check answer");
    }

    return jsonDecode(response.body) as Map<String, dynamic>;
  }

  /// Save the completed quiz history independently
  static Future<Map<String, dynamic>> saveHistory({
    required String token,
    required String disabilityType,
    required int difficultyLevel,
    required int totalQuestions,
    required int correctCount,
    required List<Map<String, dynamic>> questions,
  }) async {
    // using AppConfig if possible, else falling back to baseUrl
    final apiBase = AppConfig.apiBaseUrl.isNotEmpty ? AppConfig.apiBaseUrl : "http://192.168.1.101:3000";
    final url = Uri.parse('$apiBase/api/quizzes/history');

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
        print("Failed to save quiz history: ${response.body}");
        return {'success': false, 'xpGained': 0, 'totalXp': 0};
      }
    } catch (e) {
      print("Error saving quiz history: $e");
      return {'success': false, 'xpGained': 0, 'totalXp': 0};
    }
  }
}
