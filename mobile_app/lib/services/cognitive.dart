import 'dart:convert';
import 'package:http/http.dart' as http;

Future<void> saveLdResultToBackend({
  String baseUrl = 'http://127.0.0.1:3000',
  required String studentId,
  required Map<String, dynamic> features, // all your 28 input fields incl derived
  required List<double> probs, // length 3
  required String predLabel,   // below/average/above
  required double predScore,
}) async {
  final body = <String, dynamic>{
    "studentId": studentId,
    "probs": probs,
    "predLabel": predLabel,
    "predScore": predScore,

    // merge the 28 fields (raw + derived)
    ...features,
  };

  final uri = Uri.parse("$baseUrl/api/ld-predictions");

  final res = await http.post(
    uri,
    headers: {"Content-Type": "application/json"},
    body: jsonEncode(body),
  );

  if (res.statusCode < 200 || res.statusCode >= 300) {
    throw Exception("Save failed ${res.statusCode}: ${res.body}");
  }
}
