import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mobile_app/models/quiz.dart';

class QuizApi {
  static const String baseUrl = "http://192.168.1.101:3000/api/quizzes";

  static Future<List<Quiz>> fetchRandomQuizzes({
    required String grade,
    required String type,
  }) async {
    final uri = Uri.parse("$baseUrl/random?grade=$grade&type=$type");

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
}
