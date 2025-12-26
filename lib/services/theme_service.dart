import 'package:shared_preferences/shared_preferences.dart';

/// FILE: theme_service.dart
/// DESCRIZIONE: Servizio dedicato alla persistenza locale delle preferenze del tema.
/// Utilizza SharedPreferences per salvare e recuperare lo stato (Dark/Light)
/// sul dispositivo, disaccoppiando la logica di storage dallo stato dell'app.

class ThemeService {
  // --- COSTANTI DI STORAGE ---
  // Chiave univoca utilizzata per identificare il valore booleano nel key-value store.
  static const _key = "isDarkMode";

  // --- CARICAMENTO PREFERENZA ---
  // Recupera lo stato salvato in modo asincrono.
  // Se la chiave non esiste (es. primo avvio), restituisce false (Modalità Chiara) di default.
  Future<bool> loadThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_key) ?? false;
  }

  // --- SALVATAGGIO PREFERENZA ---
  // Scrive su disco la scelta attuale dell'utente per mantenerla
  // disponibile anche dopo la chiusura dell'applicazione.
  Future<void> saveThemePreference(bool isDarkMode) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, isDarkMode);
  }

  // --- RESET PREFERENZA ---
  // Rimuove la chiave dalle SharedPreferences.
  // Utile per ripristinare le impostazioni predefinite o in fase di debug/logout.
  Future<void> clearThemePreference() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_key);
  }
}