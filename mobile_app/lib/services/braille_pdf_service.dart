import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;
import 'package:open_file/open_file.dart';
import 'package:path_provider/path_provider.dart';

class BraillePdfService {
  // ✅ change this IP if your PC IP changes
  static const String baseUrl = "http://192.168.1.126:3000";

  // Keep same function name you already call from QuizPage
  static Future<void> generateAndOpenPdf({
    required String type, // "math" or "sinhala"
    required String title,
    required List<Map<String, String>> items,
  }) async {
    final uri = Uri.parse("$baseUrl/api/braille/pdf");

    final res = await http.post(
      uri,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({"type": type, "title": title, "items": items}),
    );

    if (res.statusCode != 200) {
      throw Exception("Server error: ${res.statusCode} ${res.body}");
    }

    // ✅ Android-safe folder (never null)
    final dir = await getApplicationDocumentsDirectory();
    final filePath =
        "${dir.path}/braille_${type}_${DateTime.now().millisecondsSinceEpoch}.pdf";

    final file = File(filePath);
    await file.writeAsBytes(res.bodyBytes, flush: true);

    final result = await OpenFile.open(file.path);
    if (result.type != ResultType.done) {
      throw Exception("Open failed: ${result.message}");
    }
  }
}
