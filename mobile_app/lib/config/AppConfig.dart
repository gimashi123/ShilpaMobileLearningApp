import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConfig {
  static String get apiBaseUrl =>
      dotenv.env['API_BASE_URL'] ?? 'http://10.0.2.2:3000';
}

// Use 10.0.2.2 for Android Emulator to access host machine otherwise use localhost ip
