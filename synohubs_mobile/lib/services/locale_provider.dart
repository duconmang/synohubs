import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocaleProvider extends ChangeNotifier {
  LocaleProvider._();
  static final LocaleProvider instance = LocaleProvider._();

  static const _key = 'app_locale';

  static const supportedLocales = [
    Locale('en'),
    Locale('vi'),
    Locale('zh'),
    Locale('ja'),
    Locale('fr'),
    Locale('pt'),
  ];

  Locale _locale = const Locale('en');
  Locale get locale => _locale;

  /// Call once at app start (before runApp or in splash).
  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    final saved = prefs.getString(_key);
    if (saved != null) {
      _locale = Locale(saved);
    } else {
      // Auto-detect OS language
      final systemLocale = PlatformDispatcher.instance.locale;
      final match = supportedLocales.where(
        (l) => l.languageCode == systemLocale.languageCode,
      );
      _locale = match.isNotEmpty ? match.first : const Locale('en');
    }
    notifyListeners();
  }

  Future<void> setLocale(Locale locale) async {
    if (_locale == locale) return;
    _locale = locale;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_key, locale.languageCode);
  }
}
