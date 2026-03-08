import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  // static String get apiBaseUrl => dotenv.env['API_BASE_URL'] ?? 'http://127.0.0.1:3000';
  static String get apiBaseUrl => dotenv.env['API_BASE_URL'] ?? 'http://192.168.43.79:3000';
}