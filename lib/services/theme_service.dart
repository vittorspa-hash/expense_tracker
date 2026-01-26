import 'package:shared_preferences/shared_preferences.dart';

/// FILE: theme_service.dart
/// DESCRIZIONE: Service Layer per la gestione della persistenza del tema (chiaro/scuro).
/// Si occupa del salvataggio e recupero della preferenza del tema dell'utente
/// tramite SharedPreferences. Fornisce metodi semplici per caricare, salvare
/// e cancellare la preferenza del tema.

class ThemeService {
  // --- STATO E DIPENDENZE ---
  // Iniezione di SharedPreferences per la persistenza della preferenza tema.
  
  final SharedPreferences _prefs;

  // Il costruttore richiede l'istanza già inizializzata di SharedPreferences,
  // evitando chiamate async nel costruttore e semplificando la dependency injection.
  ThemeService({required SharedPreferences sharedPreferences})
      : _prefs = sharedPreferences;

  // --- COSTANTI ---
  // Chiave utilizzata per salvare/recuperare la preferenza tema in SharedPreferences.
  
  static const _key = "isDarkMode";

  // --- CARICAMENTO PREFERENZA ---
  // Recupera la preferenza del tema salvata.
  // Restituisce false come valore di default se la chiave non esiste o si verifica un errore.
  // Nota: Metodo sincrono poiché SharedPreferences è già inizializzato,
  // rendendo il codice più veloce e leggibile.
  bool loadThemePreference() {
    try {
      return _prefs.getBool(_key) ?? false;
    } catch (e) {
      return false;
    }
  }

  // --- SALVATAGGIO PREFERENZA ---
  // Salva la preferenza del tema (true per tema scuro, false per tema chiaro).
  // Persiste il valore in SharedPreferences per mantenerlo tra sessioni dell'app.
  Future<void> saveThemePreference(bool isDarkMode) async {
    await _prefs.setBool(_key, isDarkMode);
  }

  // --- CANCELLAZIONE PREFERENZA ---
  // Rimuove la preferenza del tema salvata.
  // Utile durante reset delle impostazioni o logout dell'utente.
  Future<void> clearThemePreference() async {
    await _prefs.remove(_key);
  }
}