import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  static String get apiBaseUrl {
    return dotenv.env['API_BASE_URL'] ?? 'http://192.168.8.179:3000';
  }

  static String get apiChatBaseUrl {
    return dotenv.env['API_CHAT_BASE_URL'] ?? 'http://192.168.8.179:8000';
  }
}
