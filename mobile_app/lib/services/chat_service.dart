import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_ai_toolkit/flutter_ai_toolkit.dart';
import 'package:http/http.dart' as http;
import 'package:mobile_app/config/AppConfig.dart';

class ChatServiceException implements Exception {
  const ChatServiceException(
    this.userMessage, {
    this.statusCode,
    this.retryable = false,
    this.details,
  });

  final String userMessage;
  final int? statusCode;
  final bool retryable;
  final String? details;

  @override
  String toString() => userMessage;
}

class ChatService {
  static const String _chatBackendUrlFromEnv = String.fromEnvironment(
    'CHAT_BACKEND_URL',
    defaultValue: '',
  );

  static String get backendUrl {
    if (_chatBackendUrlFromEnv.trim().isNotEmpty) {
      return _normalizeChatUrl(_chatBackendUrlFromEnv.trim());
    }
    if (kIsWeb) return 'http://localhost:8000/chat';
    if (Platform.isAndroid) {
      return _normalizeChatUrl(AppConfig.apiChatBaseUrl);
    }
    // if (Platform.isAndroid) return 'http://127.0.0.1:8000/chat';

    return AppConfig.apiChatBaseUrl;
  }

  static String _normalizeChatUrl(String rawUrl) {
    final uri = Uri.parse(rawUrl.trim());
    final path = uri.path;
    if (path == '/chat' || path.endsWith('/chat')) {
      return uri.toString();
    }
    final normalizedPath = path.endsWith('/')
        ? '${path}chat'
        : '$path/chat';
    return uri.replace(path: normalizedPath).toString();
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

  static String userFriendlyError(Object error) {
    if (error is ChatServiceException) {
      return error.userMessage;
    }

    // Toolkit wrappers may prepend type names like:
    // "LlmFailureException: ChatServiceException: <message>"
    var message = error.toString().trim();
    final prefixPattern = RegExp(r'^[A-Za-z0-9_<>]+Exception:\s*');
    for (var i = 0; i < 3; i++) {
      final stripped = message.replaceFirst(prefixPattern, '');
      if (stripped == message) break;
      message = stripped.trim();
    }

    if (message.isEmpty) {
      return 'Could not send message. Please try again.';
    }
    return message;
  }

  // Backend replies may include markdown (**, _, `, etc.).
  // Strip formatting markers so plain-text UIs and TTS read naturally.
  static String sanitizeAssistantText(String text) {
    var cleaned = text;
    cleaned = cleaned.replaceAll('*', '');
    cleaned = cleaned.replaceAll('_', '');
    cleaned = cleaned.replaceAll('`', '');
    cleaned = cleaned.replaceAllMapped(
      RegExp(r'^\s{0,3}#{1,6}\s+', multiLine: true),
      (_) => '',
    );
    cleaned = cleaned.replaceAllMapped(
      RegExp(r'^\s{0,3}>\s?', multiLine: true),
      (_) => '',
    );
    cleaned = cleaned.replaceAllMapped(
      RegExp(r'[ \t]+\n'),
      (_) => '\n',
    );
    return cleaned.trim();
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

  String _messageForStatusCode(int statusCode) {
    switch (statusCode) {
      case 400:
        return 'Invalid request. Please try again.';
      case 401:
      case 403:
        return 'You are not authorized. Please sign in again.';
      case 404:
        return 'Chat service was not found. Please contact support.';
      case 408:
        return 'The request timed out. Please try again.';
      case 429:
        return 'Too many requests. Please wait a moment and try again.';
      case 500:
        return 'Server error. Please try again in a moment.';
      case 502:
        return 'Server is temporarily unavailable. Please wait and try again.';
      case 503:
        return 'Service is temporarily down. Please wait and try again.';
      case 504:
        return 'Gateway timeout. Please try again.';
      default:
        return 'Unable to send message right now. Please try again.';
    }
  }

  String _extractServerErrorDetails(String rawBody) {
    final body = rawBody.trim();
    if (body.isEmpty) return '';
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        final candidate =
            decoded['message'] ?? decoded['error'] ?? decoded['detail'];
        if (candidate is String && candidate.trim().isNotEmpty) {
          return candidate.trim();
        }
      }
    } catch (_) {
      // Ignore parse errors and fall back to raw text.
    }
    return body;
  }

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

    http.Response response;
    try {
      response = await _client
          .post(
            uri,
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 60));
    } on SocketException catch (e) {
      throw ChatServiceException(
        'Cannot connect to chat server. Check your internet connection and try again.',
        retryable: true,
        details: e.message,
      );
    } on TimeoutException {
      throw const ChatServiceException(
        'Chat request timed out. Please try again.',
        retryable: true,
      );
    } on http.ClientException catch (e) {
      throw ChatServiceException(
        'Network error while contacting chat server. Please try again.',
        retryable: true,
        details: e.message,
      );
    }

    if (kDebugMode) {
      debugPrint('CHAT RES STATUS => ${response.statusCode}');
      debugPrint('CHAT RES BODY => ${response.body}');
    }

    if (response.statusCode < 200 || response.statusCode >= 300) {
      final details = _extractServerErrorDetails(response.body);
      throw ChatServiceException(
        _messageForStatusCode(response.statusCode),
        statusCode: response.statusCode,
        retryable: response.statusCode >= 500 || response.statusCode == 429,
        details: details.isEmpty ? null : details,
      );
    }

    dynamic decoded;
    try {
      decoded = jsonDecode(response.body);
    } on FormatException {
      throw const ChatServiceException(
        'Received an invalid response from chat server. Please try again.',
        retryable: true,
      );
    }

    if (decoded is! Map<String, dynamic>) {
      throw const ChatServiceException(
        'Received an unexpected response from chat server.',
        retryable: true,
      );
    }
    final reply = decoded['reply'] ?? decoded['response'];
    if (reply is! String || reply.trim().isEmpty) {
      throw const ChatServiceException(
        'Chat server returned an empty response. Please try again.',
        retryable: true,
      );
    }
    return ChatService.sanitizeAssistantText(reply.trim());
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
