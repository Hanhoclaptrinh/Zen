import 'package:flutter_dotenv/flutter_dotenv.dart';

class AppConstants {
  static String get baseUrl {
    final String host = dotenv.env['HOST'] ?? 'localhost';
    final String port = dotenv.env['PORT'] ?? '3000';
    return 'http://$host:$port';
  }
}
