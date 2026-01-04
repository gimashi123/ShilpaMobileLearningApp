import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

class BraillePdfService {
  // 🔁 change if your PC IP changes
  static const String baseUrl = "http://192.168.1.126:3000";

  static Future<void> generateAndOpenPdf({
    required String type, // "math" or "sinhala"
    required String title,
    required List<Map<String, String>> items,
    int perPage = 5, // ✅ EXACTLY 5 PER PAGE
  }) async {
    final uri = Uri.parse("$baseUrl/api/braille/pdf");

    final res = await http.post(
      uri,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "type": type,
        "title": title,
        "items": items,
        "perPage": perPage,
      }),
    );

    if (res.statusCode != 200) {
      throw Exception("Server error: ${res.statusCode} ${res.body}");
    }

    final dir = await getApplicationDocumentsDirectory();
    final path =
        "${dir.path}/braille_${type}_${DateTime.now().millisecondsSinceEpoch}.pdf";

    final file = File(path);
    await file.writeAsBytes(res.bodyBytes, flush: true);

    final result = await OpenFilex.open(file.path);
    if (result.type != ResultType.done) {
      throw Exception("Open failed: ${result.message}");
    }
  }
}
