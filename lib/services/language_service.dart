import 'package:shared_preferences/shared_preferences.dart';

/// FILE: language_service.dart
/// DESCRIZIONE: Service che gestisce la persistenza della preferenza della lingua.
/// Utilizza SharedPreferences per salvare e recuperare il codice della lingua
/// selezionata dall'utente (es. 'it', 'en'), permettendo di mantenere la scelta
/// tra i riavvii dell'app.

class LanguageService {
  // --- COSTANTI ---
  // Chiave univoca utilizzata per salvare il codice lingua nello storage locale.
  static const String _languageKey = 'selected_language_code';

  // --- OPERAZIONI DI SCRITTURA ---
  // Salva in modo asincrono il codice della lingua fornito nelle SharedPreferences.
  Future<void> saveLanguageCode(String languageCode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, languageCode);
  }

  // --- OPERAZIONI DI LETTURA ---
  // Recupera il codice lingua salvato in precedenza.
  // Restituisce null se non è stata salvata alcuna preferenza (es. al primo avvio).
  Future<String?> getSavedLanguageCode() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_languageKey);
  }
}