import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mobile_app/session/session.dart';
import 'package:mobile_app/config/AppConfig.dart';

class ProgressApi {
  static String get baseUrl => AppConfig.apiBaseUrl.isNotEmpty 
      ? AppConfig.apiBaseUrl 
      : "http://192.168.1.101:3000";

  /// Fetch summary of progress (XP, counts)
  static Future<Map<String, dynamic>> fetchSummary() async {
    final token = Session.token ?? "";
    final url = Uri.parse("$baseUrl/api/progress/summary");

    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception("Failed to load progress summary: ${response.statusCode}");
      }
    } catch (e) {
      print("PROGRESS_SUMMARY_ERROR: $e");
      rethrow;
    }
  }

  /// Fetch detailed history (lessons, quizzes, games)
  static Future<Map<String, dynamic>> fetchHistory() async {
    final token = Session.token ?? "";
    final url = Uri.parse("$baseUrl/api/progress/history");

    try {
      final response = await http.get(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        throw Exception("Failed to load progress history: ${response.statusCode}");
      }
    } catch (e) {
      print("PROGRESS_HISTORY_ERROR: $e");
      rethrow;
    }
  }

  /// Mark a lesson as complete
  static Future<bool> completeLesson(String lessonId) async {
    final token = Session.token ?? "";
    final url = Uri.parse("$baseUrl/api/lessons/$lessonId/complete");

    try {
      final response = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      return response.statusCode == 200;
    } catch (e) {
      print("COMPLETE_LESSON_ERROR: $e");
      return false;
    }
  }
}
