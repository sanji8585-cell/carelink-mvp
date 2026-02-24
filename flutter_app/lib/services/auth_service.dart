import 'package:flutter/foundation.dart';
import 'api_service.dart';

class AuthService extends ChangeNotifier {
  final ApiService _api;
  Map<String, dynamic>? _user;
  bool _isLoading = false;

  AuthService(this._api);

  Map<String, dynamic>? get user => _user;
  bool get isLoggedIn => _user != null;
  bool get isLoading => _isLoading;

  Future<bool> tryAutoLogin() async {
    if (!await _api.isLoggedIn()) return false;
    try {
      _user = await _api.getMe();
      notifyListeners();
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> signup(String email, String password, String name) async {
    _isLoading = true;
    notifyListeners();
    try {
      final result = await _api.signup(email, password, name);
      _user = result['user'];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();
    try {
      final result = await _api.login(email, password);
      _user = result['user'];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await _api.logout();
    _user = null;
    notifyListeners();
  }
}
