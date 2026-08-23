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
  bool get isClassLeader => role == 'CLASS_LEADER';
  bool get canManageClass => isAdmin || isClassLeader;
  bool get canCreateEvent => isAdmin || isClassLeader;
  bool get canManageVestments => isAdmin;
  bool get canRegisterParticipants => isClassLeader;
  int? get groupId => jsonInt(user?['groupId']);

  Future<void> refreshUser() async {
    try {
      user = Map<String, dynamic>.from(await api.get('/auth/me'));
      notifyListeners();
    } catch (_) {}
  }

  Future<void> _load() async {
    api.baseUrl = AppConfig.defaultBaseUrl();
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

  Future<void> login(String username, String password) async {
    api.baseUrl = AppConfig.defaultBaseUrl();
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
