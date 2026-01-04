import 'dart:convert';
import 'package:http/http.dart' as http;

class SignNumberApi {
  // ✅ For Android Emulator use 10.0.2.2
  // ✅ For real phone use your PC IP address
  static const String baseUrl = "http://10.0.2.2:8000";

  /// Call POST /predict
  /// features must be exactly 42 numbers
  static Future<Map<String, dynamic>> predict({
    required List<double> features,
    int? expected,
  }) async {
    final uri = Uri.parse("$baseUrl/predict");

    final body = {
      "features": features,
      "expected": expected,
    };

    final res = await http.post(
      uri,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(body),
    );

    if (res.statusCode != 200) {
      throw Exception("API error ${res.statusCode}: ${res.body}");
    }

    return jsonDecode(res.body) as Map<String, dynamic>;
  }
}
