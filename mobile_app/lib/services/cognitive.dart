import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:mobile_app/session/session.dart';
import 'package:mobile_app/pages/models/cognitive.dart';
import 'package:mobile_app/services/auth_api.dart';

String get baseUrl => AuthApi.baseUrl;

class ApiException implements Exception {
  final int? statusCode;
  final String message;

  ApiException({this.statusCode, required this.message});

  @override
  String toString() {
    if (statusCode != null) {
      return 'ApiException($statusCode): $message';
    }
    return 'ApiException: $message';
  }
}

Future<void> saveLdResultToBackend({
  required String studentId,
  required Map<String, dynamic> features,
  required List<double> probs,
  required String predLabel,
  required double predScore,
  required int shapeGameScore,
  required int colorGameScore,
  required int bubbleGameScore,
  required int
  totalScore, // Note: This is still the parameter name; we'll map it correctly in the body
}) async {
  final uri = Uri.parse('$baseUrl/api/cognitive/ld-predictions');

  final body = <String, dynamic>{
    'studentId': studentId,
    'probs': probs,
    'predLabel': predLabel,
    'predScore': predScore,
    ...features,
    'shapeGameScore': shapeGameScore,
    'colorGameScore': colorGameScore,
    'bubbleGameScore': bubbleGameScore,
    'totalGameScore':
        totalScore, // Fixed: Renamed from 'totalScore' to match backend
    // Removed 'colorPostHintCorrect' since it's not in the backend schema
  };

  final res = await http.post(
    uri,
    headers: {'Content-Type': 'application/json'},
    body: jsonEncode(body),
  );

  if (res.statusCode < 200 || res.statusCode >= 300) {
    throw ApiException(statusCode: res.statusCode, message: 'Save failed');
  }
}

class LdHistoryApi {
  static Future<List<LdAttempt>> fetchHistoryByStudentId(
    String studentId,
  ) async {
    final token = Session.token;
    final url = Uri.parse('$baseUrl/api/cognitive/ld-history/$studentId');

    final res = await http.get(
      url,
      headers: {if (token != null) "Authorization": "Bearer $token"},
    );

    if (res.statusCode != 200) {
      throw ApiException(
        statusCode: res.statusCode,
        message: 'Failed to fetch history',
      );
    }

    final data = jsonDecode(res.body) as Map<String, dynamic>;
    final list = (data['attempts'] as List<dynamic>? ?? []);
    return list
        .map((e) => LdAttempt.fromJson(e as Map<String, dynamic>))
        .toList();
  }
}
