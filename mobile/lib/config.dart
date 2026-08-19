class AppConfig {
  static const envUrl = String.fromEnvironment('API_URL');
  static const liveUrl = 'https://mobile-app-3w9q.onrender.com/api';

  static String defaultBaseUrl() {
    if (envUrl.isNotEmpty) return envUrl;
    return liveUrl;
  }
}
