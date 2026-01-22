import 'package:shared_preferences/shared_preferences.dart';

class ThemeService {
  final SharedPreferences _prefs;

  // Il costruttore ora richiede l'istanza già inizializzata
  ThemeService({required SharedPreferences sharedPreferences})
      : _prefs = sharedPreferences;

  static const _key = "isDarkMode";

  // Nota: Ora i metodi non devono più attendere getInstance(), 
  // rendendo il codice più veloce e leggibile.
  bool loadThemePreference() {
    return _prefs.getBool(_key) ?? false;
  }

  Future<void> saveThemePreference(bool isDarkMode) async {
    await _prefs.setBool(_key, isDarkMode);
  }

  Future<void> clearThemePreference() async {
    await _prefs.remove(_key);
  }
}