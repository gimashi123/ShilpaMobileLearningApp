import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  static String get apiBaseUrl =>
      dotenv.env['APP_BASE_URL'] ??
      dotenv.env['API_BASE_URL'] ??
      'http://127.0.0.1:3000';

  static String get pythonBackendUrl =>
      dotenv.env['APP_PYTHON_BACKEND_URL'] ??
      dotenv.env['PYTHON_BACKEND_URL'] ??
      'http://127.0.0.1:8000';
}
