import 'package:shared_preferences/shared_preferences.dart';

class ThemePreferenceService {
  static const String keyIsDarkMode = 'dompetku_is_dark_mode';

  static Future<bool> isDarkMode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(keyIsDarkMode) ?? false;
  }

  static Future<bool> setDarkMode(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    return await prefs.setBool(keyIsDarkMode, value);
  }
}
