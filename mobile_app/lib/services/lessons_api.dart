// lib/services/lessons_api.dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class LessonApi {
  static const String baseUrl = 'http://192.168.1.101:3000';

  static Future<List<dynamic>> fetchMyLessons(String token) async {
    final url = Uri.parse('$baseUrl/api/lessons/my');

    print('---- fetchMyLessons ----');
    print('URL    : $url');
    print('TOKEN  : $token');

    final res = await http.get(
      url,
      headers: {'Authorization': 'Bearer $token'},
    );

    print('STATUS : ${res.statusCode}');
    print('BODY   : ${res.body}');

    final json = jsonDecode(res.body);

    if (res.statusCode != 200) {
      // show backend error
      final msg = json['message'] ?? 'Failed to load lessons';
      throw Exception(msg);
    }

    final data = json['data'];
    if (data is List) {
      return data;
    } else {
      // defensive: if backend changed shape
      return [];
    }
  }
}
