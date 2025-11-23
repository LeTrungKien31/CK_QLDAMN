// lib/providers/auth_provider.dart
import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/api_service.dart';

class AuthProvider with ChangeNotifier {
  User? _currentUser;
  bool _isAuthenticated = false;

  User? get currentUser => _currentUser;
  bool get isAuthenticated => _isAuthenticated;

  final ApiService _apiService = ApiService();

  Future<void> checkAuth() async {
    await _apiService.loadToken();
    _currentUser = await _apiService.getCurrentUser();
    _isAuthenticated = _currentUser != null;
    notifyListeners();
  }

  Future<bool> login(String username, String password) async {
    try {
      final data = await _apiService.login(username, password);
      _currentUser = User.fromJson(data['user']);
      _isAuthenticated = true;
      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<void> logout() async {
    await _apiService.logout();
    _currentUser = null;
    _isAuthenticated = false;
    notifyListeners();
  }

  Future<bool> changePassword(String oldPassword, String newPassword) async {
    try {
      return await _apiService.changePassword(oldPassword, newPassword);
    } catch (e) {
      return false;
    }
  }
}
