import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/api_service.dart';
import '../models/user_model.dart';

class AuthProvider extends ChangeNotifier {
  User? _user;
  bool _isAuthenticated = false;
  bool _isLoading = false;

  User? get user => _user;
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;

  AuthProvider() {
    ApiService.onUnauthenticated = () {
      logout();
    };
    _loadAuthData();
  }

  Future<void> _loadAuthData() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('access_token');
    final userData = prefs.getString('user_data');

    if (token != null && userData != null) {
      try {
        _user = User.fromJson(jsonDecode(userData));
        _isAuthenticated = true;
        notifyListeners();
      } catch (e) {
        print("Error loading auth data: $e");
        await logout();
      }
    }
  }

  Future<void> login(String email, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      print("AuthProvider: Attempting login for $email");
      final response = await ApiService.login(email, password);
      _user = User.fromJson(response['user']);
      _isAuthenticated = true;
      print(
        "AuthProvider: Login successful, user: ${_user?.name}, isAuthenticated: $_isAuthenticated",
      );
    } catch (e) {
      print("AuthProvider: Login failed: $e");
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
      print("AuthProvider: notifyListeners() called, isLoading: $_isLoading");
    }
  }

  Future<void> refreshProfile() async {
    try {
      final userData = await ApiService.getProfile();
      _user = User.fromJson(userData);
      // Persist fresh permissions to local storage so they survive restarts
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('user_data', jsonEncode(_user!.toJson()));
      notifyListeners();
    } catch (e) {
      print("Error refreshing profile: $e");
    }
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      await ApiService.changePassword(
        currentPassword: currentPassword,
        newPassword: newPassword,
        confirmPassword: confirmPassword,
      );
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await ApiService.clearAuth();
    _user = null;
    _isAuthenticated = false;
    notifyListeners();
  }

  void updateUserData(User newData) async {
    _user = newData;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('user_data', jsonEncode(newData.toJson()));
    notifyListeners();
  }
}
