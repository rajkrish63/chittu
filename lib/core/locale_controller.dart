import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AppLocaleController extends ChangeNotifier {
  AppLocaleController._();
  static final AppLocaleController instance = AppLocaleController._();

  static const _prefKey = 'selected_language_code';
  String _languageCode = 'en'; // English is default

  String get languageCode => _languageCode;
  bool get isTamil => _languageCode == 'ta';

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _languageCode = prefs.getString(_prefKey) ?? 'en';
    notifyListeners();
  }

  Future<void> setLanguage(String code) async {
    if (_languageCode == code) return;
    _languageCode = code;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, code);
  }
}
