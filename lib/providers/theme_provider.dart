import 'package:flutter/material.dart';
import 'package:expense_tracker/services/theme_service.dart';

/// FILE: theme_provider.dart
/// DESCRIZIONE: Provider che gestisce lo stato globale del tema (Chiaro/Scuro) dell'applicazione.
/// Estende ChangeNotifier per notificare l'interfaccia utente quando la modalità cambia
/// e utilizza un servizio dedicato per persistere la scelta dell'utente.

class ThemeProvider extends ChangeNotifier {
  // --- DIPENDENZE E STATO INTERNO ---
  // Iniezione del servizio che si occupa del salvataggio fisico del dato (SharedPreferences).
  final ThemeService _themeService;

  ThemeProvider({required ThemeService themeService})
      : _themeService = themeService;

  // Variabile privata che mantiene lo stato corrente (true = Dark Mode).
  bool _isDarkMode = false;
  
  // --- GETTERS PUBBLICI ---
  // Espone lo stato booleano per gli switch UI e converte lo stato
  // nel formato ThemeMode richiesto dal widget MaterialApp.
  bool get isDarkMode => _isDarkMode;
  ThemeMode get themeMode => _isDarkMode ? ThemeMode.dark : ThemeMode.light;

  // --- INIZIALIZZAZIONE ---
  // Metodo asincrono chiamato all'avvio dell'app. Recupera l'ultima preferenza
  // salvata dall'utente per garantire continuità tra le sessioni.
  Future<void> initialize() async {
    _isDarkMode = _themeService.loadThemePreference();
    notifyListeners();
  }

  // --- LOGICA DI CAMBIO TEMA ---
  // Aggiorna lo stato locale, forza il rebuild della UI tramite notifyListeners()
  // e salva la nuova preferenza in modo persistente tramite il servizio.
  Future<void> toggleTheme(bool isOn) async {
    _isDarkMode = isOn;
    notifyListeners();
    await _themeService.saveThemePreference(_isDarkMode);
  }
}