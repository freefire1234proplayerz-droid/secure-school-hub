import 'package:flutter/material.dart';

import 'api_service.dart';
import 'local_db.dart';

class AuthService extends ChangeNotifier {
  bool _isLoading = false;
  String? _role; // 'teacher' or 'parent'
  int? _tempUserId; // from backend after login, sent with verify-otp
  String? _lastOtpDemo; // demo OTP shown by backend (for testing only)

  bool get isLoading => _isLoading;
  String? get role => _role;
  String? get lastOtpDemo => _lastOtpDemo;
  int? get tempUserId => _tempUserId;

  final ApiService _api = ApiService();

  Future<void> login(String email, String password, String role) async {
    _isLoading = true;
    _lastOtpDemo = null;
    _tempUserId = null;
    notifyListeners();
    try {
      final res = await _api.post('/auth/login', data: {
        'email': email,
        'password': password,
        'role': role,
      });
      _role = role;
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

  Future<void> verifyOtp(String otp) async {
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
      await LocalDb.saveToken(token);
      _lastOtpDemo = null;
      _tempUserId = null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    await LocalDb.clearAuth();
    _role = null;
    notifyListeners();
  }
}
