import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AppLocalizations {
  AppLocalizations(this.locale);

  final Locale locale;

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  static AppLocalizations of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations)!;
  }

  static final Map<String, Map<String, String>> _localizedValues = {
    'en': {
      'app_title': 'SecureSchoolHub',
      'login': 'Login',
      'teacher': 'Teacher',
      'parent': 'Parent',
      'email': 'Email',
      'password': 'Password',
      'otp': 'OTP',
      'send_otp': 'Send OTP',
      'verify_otp': 'Verify OTP',
      'logout': 'Logout',
      'attendance': 'Attendance',
      'scan_qr': 'Scan QR',
      'homework': 'Homework',
      'fee_reminders': 'Fee reminders',
      'grades': 'Grades',
      'chat': 'Chat',
      'network_security': 'Network security',
      'run_scan': 'Run scan',
      'language': 'Language',
      'english': 'English',
      'hindi': 'Hindi',
    },
    'hi': {
      'app_title': 'सिक्योर स्कूल हब',
      'login': 'लॉगिन',
      'teacher': 'अध्यापक',
      'parent': 'अभिभावक',
      'email': 'ईमेल',
      'password': 'पासवर्ड',
      'otp': 'ओटीपी',
      'send_otp': 'ओटीपी भेजें',
      'verify_otp': 'ओटीपी सत्यापित करें',
      'logout': 'लॉगआउट',
      'attendance': 'उपस्थिति',
      'scan_qr': 'क्यूआर स्कैन करें',
      'homework': 'होमवर्क',
      'fee_reminders': 'शुल्क याद दिलाना',
      'grades': 'अंक',
      'chat': 'चैट',
      'network_security': 'नेटवर्क सुरक्षा',
      'run_scan': 'स्कैन चलाएँ',
      'language': 'भाषा',
      'english': 'अंग्रेज़ी',
      'hindi': 'हिंदी',
    },
  };

  String _t(String key) {
    return _localizedValues[locale.languageCode]?[key] ??
        _localizedValues['en']![key] ??
        key;
  }

  String get appTitle => _t('app_title');
  String get login => _t('login');
  String get teacher => _t('teacher');
  String get parent => _t('parent');
  String get email => _t('email');
  String get password => _t('password');
  String get otp => _t('otp');
  String get sendOtp => _t('send_otp');
  String get verifyOtp => _t('verify_otp');
  String get logout => _t('logout');
  String get attendance => _t('attendance');
  String get scanQr => _t('scan_qr');
  String get homework => _t('homework');
  String get feeReminders => _t('fee_reminders');
  String get grades => _t('grades');
  String get chat => _t('chat');
  String get networkSecurity => _t('network_security');
  String get runScan => _t('run_scan');
  String get language => _t('language');
  String get english => _t('english');
  String get hindi => _t('hindi');
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => ['en', 'hi'].contains(locale.languageCode);

  @override
  Future<AppLocalizations> load(Locale locale) async {
    Intl.defaultLocale = locale.languageCode;
    return AppLocalizations(locale);
  }

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}
