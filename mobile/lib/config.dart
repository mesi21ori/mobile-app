import 'dart:io';
import 'package:flutter/foundation.dart';

class AppConfig {
  static const envUrl = String.fromEnvironment('API_URL');

  static String defaultBaseUrl() {
    if (envUrl.isNotEmpty) return envUrl;
    if (kIsWeb) return 'http://127.0.0.1:3000/api';
    if (Platform.isAndroid) return 'http://10.0.2.2:3000/api';
    return 'http://127.0.0.1:3000/api';
  }
}
