import 'package:flutter/material.dart';

import 'api_service.dart';
import 'local_db.dart';
import '../screens/admin/admin_dashboard.dart';
import '../screens/parent_dashboard.dart';
import '../screens/teacher_dashboard.dart';

class AuthService extends ChangeNotifier {
  bool _isLoading = false;
  String? _role;
  String? _email;
  int? _tempUserId;
  String? _lastOtpDemo;

  bool get isLoading => _isLoading;
  String? get role => _role;
  String? get email => _email;
  String? get lastOtpDemo => _lastOtpDemo;
  int? get tempUserId => _tempUserId;
  bool get isAuthenticated => LocalDb.hasSession;

  final ApiService _api = ApiService();

  AuthService() {
    _role = LocalDb.role;
    _email = LocalDb.email;
  }

  String? dashboardRouteForRole([String? role]) {
    switch (role ?? _role) {
      case 'admin':
        return AdminDashboard.routeName;
      case 'teacher':
        return TeacherDashboard.routeName;
      case 'parent':
        return ParentDashboard.routeName;
      default:
        return null;
    }
  }

  Future<bool> restoreSession() async {
    if (!LocalDb.hasSession) {
      return false;
    }

    _isLoading = true;
    notifyListeners();

    try {
      final res = await _api.get('/auth/me');
      final user = res.data['user'] as Map<String, dynamic>?;
      if (user == null) {
        await logout();
        return false;
      }

      _role = user['role']?.toString();
      _email = user['email']?.toString();
      await LocalDb.saveRole(_role ?? '');
      if (_email != null) {
        await LocalDb.saveEmail(_email!);
      }
      return _role != null;
    } catch (_) {
      await logout();
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> login(String email, String password, String role) async {
    _isLoading = true;
    _lastOtpDemo = null;
    _tempUserId = null;
    notifyListeners();
    try {
      final res = await _api.post('/auth/login/otp', data: {
        'email': email,
        'password': password,
        'role': role,
      });
      _role = role;
      _email = email;
      final rawId = res.data['tempUserId'];
      if (rawId is int) {
        _tempUserId = rawId;
      } else if (rawId is num) {
        _tempUserId = rawId.toInt();
      } else if (rawId != null) {
        _tempUserId = int.tryParse(rawId.toString());
      } else {
        _tempUserId = null;
      }
      _lastOtpDemo = res.data['otp_demo']?.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<String?> verifyOtp(String otp) async {
    if (_tempUserId == null) {
      throw StateError('No temp user; complete login step first.');
    }
    _isLoading = true;
    notifyListeners();
    try {
      final res = await _api.post('/auth/verify-otp', data: {
        'otp': otp,
        'tempUserId': _tempUserId,
      });
      final token = res.data['token']?.toString();
      if (token == null || token.isEmpty) {
        throw StateError('No token in response');
      }

      final user = res.data['user'] as Map<String, dynamic>?;
      _role = user?['role']?.toString() ?? _role;
      _email = user?['email']?.toString() ?? _email;

      await LocalDb.saveToken(token);
      if (_role != null) await LocalDb.saveRole(_role!);
      if (_email != null) await LocalDb.saveEmail(_email!);

      _lastOtpDemo = null;
      _tempUserId = null;

      return dashboardRouteForRole();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await LocalDb.clearAuth();
    await LocalDb.clearCache();
    _role = null;
    _email = null;
    _tempUserId = null;
    _lastOtpDemo = null;
    notifyListeners();
  }

  bool canAccessRole(String requiredRole) {
    if (_role == null) return false;
    if (_role == 'admin') return true;
    return _role == requiredRole;
  }
}
