// import 'dart:convert';
// import 'package:http/http.dart' as http;
// import 'package:mobile_app/config/AppConfig.dart';

// class SignNumberApi {

//   static String baseUrl = AppConfig.apiBaseUrl;

//   /// Call POST /predict
//   /// features must be exactly 42 numbers
//   static Future<Map<String, dynamic>> predict({
//     required List<double> features,
//     int? expected,
//   }) async {
//     final uri = Uri.parse("$baseUrl/predict");

//     final body = {
//       "features": features,
//       "expected": expected,
//     };

//     final res = await http.post(
//       uri,
//       headers: {"Content-Type": "application/json"},
//       body: jsonEncode(body),
//     );

//     if (res.statusCode != 200) {
//       throw Exception("API error ${res.statusCode}: ${res.body}");
//     }

//     return jsonDecode(res.body) as Map<String, dynamic>;
//   }
// }
