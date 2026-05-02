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

class MatchImageItem {
  final String id;
  final String asset;

  const MatchImageItem({required this.id, required this.asset});

  factory MatchImageItem.fromJson(Map<String, dynamic> json) {
    return MatchImageItem(
      id: (json['id'] ?? '').toString(),
      asset: (json['asset'] ?? json['assetUrl'] ?? '').toString(),
    );
  }

  bool get isValid => id.trim().isNotEmpty && asset.trim().isNotEmpty;
}

class MatchNumberItem {
  final int value;
  final String word;

  const MatchNumberItem({required this.value, required this.word});

  factory MatchNumberItem.fromJson(Map<String, dynamic> json) {
    final parsedValue = int.tryParse((json['value'] ?? '').toString()) ?? -1;
    return MatchNumberItem(
      value: parsedValue,
      word: (json['word'] ?? '').toString(),
    );
  }

  bool get isValid => value > 0 && word.trim().isNotEmpty;
}

class MatchSoundItem {
  final String id;
  final String soundAsset;
  final String imageAsset;

  const MatchSoundItem({
    required this.id,
    required this.soundAsset,
    required this.imageAsset,
  });

  factory MatchSoundItem.fromJson(Map<String, dynamic> json) {
    return MatchSoundItem(
      id: (json['id'] ?? '').toString(),
      soundAsset: (json['soundAsset'] ?? json['sound'] ?? '').toString(),
      imageAsset:
          (json['imageAsset'] ?? json['asset'] ?? json['image'] ?? '').toString(),
    );
  }

  bool get isValid =>
      id.trim().isNotEmpty &&
      soundAsset.trim().isNotEmpty &&
      imageAsset.trim().isNotEmpty;
}

class MatchPatternTypeItem {
  final String type;
  final List<String> bank;

  const MatchPatternTypeItem({required this.type, required this.bank});

  factory MatchPatternTypeItem.fromJson(Map<String, dynamic> json) {
    final rawBank = json['bank'];
    final bank = rawBank is List
        ? rawBank.map((e) => e.toString()).where((e) => e.trim().isNotEmpty).toList()
        : <String>[];
    return MatchPatternTypeItem(
      type: (json['type'] ?? '').toString(),
      bank: bank,
    );
  }

  bool get isValid => type.trim().isNotEmpty && bank.length >= 3;
}

class IqGameConfig {
  final List<String> shapes;
  final Map<String, String> colorOptions;
  final List<String> bubbleColors;

  const IqGameConfig({
    required this.shapes,
    required this.colorOptions,
    required this.bubbleColors,
  });

  factory IqGameConfig.fromJson(Map<String, dynamic> json) {
    final rawShapes = (json['shapes'] as List<dynamic>? ?? const []);
    final shapes = rawShapes
        .map((e) => e.toString().trim())
        .where((e) => e.isNotEmpty)
        .toList();

    final rawColors = json['colorOptions'];
    final colorOptions = <String, String>{};
    if (rawColors is Map<String, dynamic>) {
      rawColors.forEach((k, v) {
        final key = k.toString().trim();
        final value = v.toString().trim();
        if (key.isNotEmpty && value.isNotEmpty) {
          colorOptions[key] = value;
        }
      });
    }

    final rawBubbleColors = (json['bubbleColors'] as List<dynamic>? ?? const []);
    final bubbleColors = rawBubbleColors
        .map((e) => e.toString().trim())
        .where((e) => e.isNotEmpty)
        .toList();

    return IqGameConfig(
      shapes: shapes,
      colorOptions: colorOptions,
      bubbleColors: bubbleColors,
    );
  }

  bool get isValid =>
      shapes.isNotEmpty && colorOptions.isNotEmpty && bubbleColors.isNotEmpty;
}

Future<List<MatchImageItem>> fetchMatchImageItems() async {
  final uri = Uri.parse('$baseUrl/api/cognitive/match-image-items');
  final res = await http.get(uri);

  if (res.statusCode < 200 || res.statusCode >= 300) {
    throw ApiException(
      statusCode: res.statusCode,
      message: 'Failed to fetch match image items',
    );
  }

  final decoded = jsonDecode(res.body);
  final rawItems = decoded is Map<String, dynamic>
      ? (decoded['items'] as List<dynamic>? ?? const [])
      : (decoded is List<dynamic> ? decoded : const []);

  return rawItems
      .whereType<Map<String, dynamic>>()
      .map(MatchImageItem.fromJson)
      .where((e) => e.isValid)
      .toList();
}

Future<List<MatchNumberItem>> fetchMatchNumberItems() async {
  final uri = Uri.parse('$baseUrl/api/cognitive/match-number-items');
  final res = await http.get(uri);

  if (res.statusCode < 200 || res.statusCode >= 300) {
    throw ApiException(
      statusCode: res.statusCode,
      message: 'Failed to fetch match number items',
    );
  }

  final decoded = jsonDecode(res.body);
  final rawItems = decoded is Map<String, dynamic>
      ? (decoded['items'] as List<dynamic>? ?? const [])
      : (decoded is List<dynamic> ? decoded : const []);

  return rawItems
      .whereType<Map<String, dynamic>>()
      .map(MatchNumberItem.fromJson)
      .where((e) => e.isValid)
      .toList();
}

Future<List<MatchSoundItem>> fetchMatchSoundItems() async {
  final uri = Uri.parse('$baseUrl/api/cognitive/match-sound-items');
  final res = await http.get(uri);

  if (res.statusCode < 200 || res.statusCode >= 300) {
    throw ApiException(
      statusCode: res.statusCode,
      message: 'Failed to fetch match sound items',
    );
  }

  final decoded = jsonDecode(res.body);
  final rawItems = decoded is Map<String, dynamic>
      ? (decoded['items'] as List<dynamic>? ?? const [])
      : (decoded is List<dynamic> ? decoded : const []);

  return rawItems
      .whereType<Map<String, dynamic>>()
      .map(MatchSoundItem.fromJson)
      .where((e) => e.isValid)
      .toList();
}

Future<List<MatchPatternTypeItem>> fetchMatchPatternTypeItems() async {
  final uri = Uri.parse('$baseUrl/api/cognitive/match-pattern-types');
  final res = await http.get(uri);

  if (res.statusCode < 200 || res.statusCode >= 300) {
    throw ApiException(
      statusCode: res.statusCode,
      message: 'Failed to fetch match pattern types',
    );
  }

  final decoded = jsonDecode(res.body);
  final rawItems = decoded is Map<String, dynamic>
      ? (decoded['items'] as List<dynamic>? ?? const [])
      : (decoded is List<dynamic> ? decoded : const []);

  return rawItems
      .whereType<Map<String, dynamic>>()
      .map(MatchPatternTypeItem.fromJson)
      .where((e) => e.isValid)
      .toList();
}

Future<IqGameConfig> fetchIqGameConfig() async {
  final uri = Uri.parse('$baseUrl/api/cognitive/iq-game-config');
  final res = await http.get(uri);

  if (res.statusCode < 200 || res.statusCode >= 300) {
    throw ApiException(
      statusCode: res.statusCode,
      message: 'Failed to fetch IQ game config',
    );
  }

  final decoded = jsonDecode(res.body);
  final raw = decoded is Map<String, dynamic>
      ? (decoded['config'] as Map<String, dynamic>? ?? decoded)
      : <String, dynamic>{};

  final config = IqGameConfig.fromJson(raw);
  if (!config.isValid) {
    throw ApiException(message: 'Invalid IQ game config payload');
  }
  return config;
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
