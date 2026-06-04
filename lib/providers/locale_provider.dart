import 'package:flutter/material.dart';

class LocaleProvider extends ChangeNotifier {
  Locale _locale = const Locale('en');

  Locale get locale => _locale;

  void toggleLocale() {
    _locale =
        _locale.languageCode == 'en' ? const Locale('hi') : const Locale('en');
    notifyListeners();
  }
}
