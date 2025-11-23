// lib/providers/auth_provider.dart
import 'package:flutter/material.dart';
import '../models/user.dart';
import '../services/database_service.dart';

class AuthProvider with ChangeNotifier {
  User? _currentUser;
  bool _isAuthenticated = false;

  User? get currentUser => _currentUser;
  bool get isAuthenticated => _isAuthenticated;

  final DatabaseService _dbService = DatabaseService();

  Future<void> checkAuth() async {
    final userData = await _dbService.getCurrentUser();
    if (userData != null) {
      _currentUser = User.fromJson(userData);
      _isAuthenticated = true;
    } else {
      _currentUser = null;
      _isAuthenticated = false;
    }
    notifyListeners();
  }

  Future<bool> login(String username, String password) async {
    try {
      final userData = await _dbService.login(username, password);
      if (userData != null) {
        _currentUser = User.fromJson(userData);
        _isAuthenticated = true;
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      // ignore: avoid_print
      print('Login error in provider: $e');
      return false;
    }
  }

  Future<void> logout() async {
    await _dbService.clearCurrentUser();
    _currentUser = null;
    _isAuthenticated = false;
    notifyListeners();
  }

  Future<bool> changePassword(String oldPassword, String newPassword) async {
    try {
      return await _dbService.changePassword(oldPassword, newPassword);
    } catch (e) {
      // ignore: avoid_print
      print('Change password error: $e');
      return false;
    }
  }
}