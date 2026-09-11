import 'package:flutter/material.dart';
import '../config/app_config.dart';
import '../models/user.dart';
import 'api_service.dart';
import 'storage_service.dart';

class AuthService extends ChangeNotifier {
  User? _currentUser;
  bool _isLoading = true;
  String? _errorMessage;

  User? get currentUser => _currentUser;
  bool get isAuthenticated => _currentUser != null;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  UserRole get role => _currentUser?.role ?? UserRole.user;

  Future<void> init() async {
    _isLoading = true;
    notifyListeners();

    // Check custom host setting
    final savedHost = await StorageService.getCustomHost();
    if (savedHost != null && savedHost.isNotEmpty) {
      AppConfig.customHost = savedHost;
    }

    // Check token
    final token = await StorageService.getAccessToken();
    if (token != null) {
      try {
        _currentUser = await ApiService().getMyProfile();
      } catch (e) {
        await StorageService.clearAll();
        _currentUser = null;
      }
    }

    _isLoading = false;
    notifyListeners();
  }

  Future<bool> login(String emailOrPhone, String password) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await ApiService().login(emailOrPhone, password);
      await StorageService.saveTokens(res.accessToken, res.refreshToken);
      _currentUser = res.user ?? await ApiService().getMyProfile();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<bool> register({
    String? email,
    String? phone,
    required String username,
    required String firstName,
    required String lastName,
    required String password,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final res = await ApiService().register(
        email: email,
        phone: phone,
        username: username,
        firstName: firstName,
        lastName: lastName,
        password: password,
      );
      await StorageService.saveTokens(res.accessToken, res.refreshToken);
      _currentUser = res.user ?? await ApiService().getMyProfile();
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  Future<void> refreshProfile() async {
    if (!isAuthenticated) return;
    try {
      _currentUser = await ApiService().getMyProfile();
      notifyListeners();
    } catch (_) {}
  }

  Future<void> logout() async {
    await ApiService().logout();
    await StorageService.clearAll();
    _currentUser = null;
    notifyListeners();
  }

  Future<void> setHost(String host) async {
    AppConfig.customHost = host.trim();
    await StorageService.saveCustomHost(host.trim());
    notifyListeners();
  }
}
