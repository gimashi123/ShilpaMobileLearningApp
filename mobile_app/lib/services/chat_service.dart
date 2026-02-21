import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_ai_toolkit/flutter_ai_toolkit.dart';
import 'package:http/http.dart' as http;

class ChatService {
  static const String _chatBackendUrlFromEnv = String.fromEnvironment(
    'CHAT_BACKEND_URL',
    defaultValue: '',
  );

  static String get backendUrl {
    if (_chatBackendUrlFromEnv.trim().isNotEmpty) {
      return _chatBackendUrlFromEnv.trim();
    }
    if (kIsWeb) return 'http://localhost:8000/chat';
    if (Platform.isAndroid) return 'http://127.0.0.1:8000/chat';
    return 'http://127.0.0.1:8000/chat';
  }

  LlmProvider createProvider({
    bool preferSinhala = true,
    Iterable<ChatMessage>? history,
  }) {
    return _BackendChatProvider(
      backendUrl: backendUrl,
      languageCode: preferSinhala ? 'si' : 'en',
      history: history,
    );
  }
}

class _BackendChatProvider extends LlmProvider with ChangeNotifier {
  _BackendChatProvider({
    required this.backendUrl,
    required this.languageCode,
    Iterable<ChatMessage>? history,
    http.Client? client,
  }) : _history = List<ChatMessage>.from(history ?? []),
       _client = client ?? http.Client();

  final String backendUrl;
  final String languageCode;
  final http.Client _client;
  List<ChatMessage> _history;

  @override
  Iterable<ChatMessage> get history => _history;

  @override
  set history(Iterable<ChatMessage> value) {
    _history = List<ChatMessage>.from(value);
    notifyListeners();
  }

  String _buildPromptWithContext(String prompt) => prompt.trim();

  Future<String> _fetchReply(String prompt) async {
    final uri = Uri.parse(backendUrl);
    final payload = <String, dynamic>{
      'message': _buildPromptWithContext(prompt),
      'language': languageCode,
    };

    if (kDebugMode) {
      debugPrint('CHAT REQ => POST $backendUrl');
      debugPrint('CHAT REQ BODY => ${jsonEncode(payload)}');
    }

    final response = await _client
        .post(
          uri,
          headers: const {'Content-Type': 'application/json'},
          body: jsonEncode(payload),
        )
        .timeout(const Duration(seconds: 60));

    if (kDebugMode) {
      debugPrint('CHAT RES STATUS => ${response.statusCode}');
      debugPrint('CHAT RES BODY => ${response.body}');
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
        'Backend failed: ${response.statusCode} ${response.body}',
      );
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw Exception('Invalid backend response format.');
    }
    final reply = decoded['reply'] ?? decoded['response'];
    if (reply is! String || reply.trim().isEmpty) {
      throw Exception('Invalid response format.');
    }
    return reply.trim();
  }

  // This creates the typing effect in the UI
  Stream<String> _simulateStreaming(String fullText) async* {
    final words = fullText.split(' ');
    for (var i = 0; i < words.length; i++) {
      yield words[i] + (i == words.length - 1 ? "" : " ");
      await Future<void>.delayed(const Duration(milliseconds: 30));
    }
  }

  @override
  Stream<String> generateStream(String prompt, {Iterable<Attachment> attachments = const []}) async* {
    final reply = await _fetchReply(prompt);
    yield* _simulateStreaming(reply);
  }

  @override
  Stream<String> sendMessageStream(String prompt, {Iterable<Attachment> attachments = const []}) async* {
    final userMessage = ChatMessage.user(prompt, attachments);
    final llmMessage = ChatMessage.llm();

    _history = [..._history, userMessage, llmMessage];
    notifyListeners();

    try {
      final reply = await _fetchReply(prompt);
      await for (final text in _simulateStreaming(reply)) {
        llmMessage.append(text);
        notifyListeners();
        yield text;
      }
    } catch (_) {
      _history.remove(llmMessage);
      notifyListeners();
      rethrow;
    }
  }
}
