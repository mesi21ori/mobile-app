import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'api.dart';
import 'config.dart';

class AuthState extends ChangeNotifier {
  AuthState() {
    _load();
  }

  final _storage = const FlutterSecureStorage();
  late ApiClient api = ApiClient(baseUrl: AppConfig.defaultBaseUrl());

  bool loading = true;
  Map<String, dynamic>? user;

  bool get isLoggedIn => user != null;
  String get role => user?['role'] ?? 'USER';
  bool get isAdmin => role == 'ADMIN' || role == 'SUPER_ADMIN';
  bool get isSuper => role == 'SUPER_ADMIN';

  Future<void> _load() async {
    final url = await _storage.read(key: 'apiUrl');
    if (url != null && url.isNotEmpty) api.baseUrl = url;
    final token = await _storage.read(key: 'token');
    if (token != null) {
      api.token = token;
      try {
        user = Map<String, dynamic>.from(await api.get('/auth/me'));
      } catch (_) {
        await logout();
      }
    }
    loading = false;
    notifyListeners();
  }

  Future<void> login(String username, String password, {String? apiUrl}) async {
    if (apiUrl != null && apiUrl.trim().isNotEmpty) {
      api.baseUrl = apiUrl.trim();
      await _storage.write(key: 'apiUrl', value: api.baseUrl);
    }
    final data = await api.post('/auth/login', {
      'username': username.trim(),
      'password': password,
    });
    api.token = data['token'];
    user = Map<String, dynamic>.from(data['user']);
    await _storage.write(key: 'token', value: api.token);
    notifyListeners();
  }

  Future<void> logout() async {
    api.token = null;
    user = null;
    await _storage.delete(key: 'token');
    notifyListeners();
  }
}
