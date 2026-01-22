import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// FILE: language_service.dart
/// DESCRIZIONE: Service per la persistenza della preferenza lingua

class LanguageService {
  final SharedPreferences _prefs;

  LanguageService({required SharedPreferences sharedPreferences})
      : _prefs = sharedPreferences;

  static const String _languageKey = 'selected_language_code';

  /// Salva il codice lingua nelle preferenze
  Future<void> saveLanguageCode(String languageCode) async {
    try {
      await _prefs.setString(_languageKey, languageCode);
      debugPrint('✅ Language saved: $languageCode');
    } catch (e) {
      debugPrint('❌ Error saving language: $e');
      rethrow; // Opzionale: lascia gestire al Provider
    }
  }

  /// Recupera il codice lingua salvato (null se non presente)
  String? getSavedLanguageCode() {
    return _prefs.getString(_languageKey);
  }
}