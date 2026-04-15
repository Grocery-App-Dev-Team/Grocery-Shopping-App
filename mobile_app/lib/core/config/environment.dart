import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

class Environment {
  static Future<void> load() async {
    await dotenv.load(fileName: '.env');
  }

  static String get baseUrl {
    final envUrl = dotenv.env['BASE_URL'];
    if (envUrl != null && envUrl.isNotEmpty) {
      return envUrl;
    }
    return kIsWeb ? 'http://localhost:8080/api' : 'http://10.0.2.2:8080/api';
  }

  static bool get isDevelopment =>
      dotenv.env['ENVIRONMENT']?.toLowerCase() == 'development';

  static bool get enableLogging =>
      (dotenv.env['ENABLE_LOGGING'] ?? 'true').toLowerCase() == 'true';
}
