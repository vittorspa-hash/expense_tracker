import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// FILE: theme_provider.dart
/// DESCRIZIONE: Provider responsabile della gestione del tema (Chiaro/Scuro).
/// Utilizza SharedPreferences per persistere la scelta dell'utente e
/// notifica l'app per aggiornare l'interfaccia in tempo reale.

class ThemeProvider extends ChangeNotifier {
  // --- STATO E GETTERS ---
  // Gestione dello stato interno e mappatura verso le configurazioni del tema Flutter.
  static const _key = "isDarkMode";
  bool _isDarkMode = false;

  bool get isDarkMode => _isDarkMode;
  ThemeMode get themeMode => _isDarkMode ? ThemeMode.dark : ThemeMode.light;

  // --- INIZIALIZZAZIONE ---
  // Caricamento asincrono della preferenza salvata.
  // Viene chiamato esplicitamente nel main prima di runApp per evitare flash visivi.
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool(_key) ?? false;
    notifyListeners();
  }

  // --- LOGICA DI AGGIORNAMENTO ---
  // Cambia il tema corrente, notifica i listener e salva la nuova impostazione
  // in memoria persistente.
  Future<void> toggleTheme(bool isOn) async {
    _isDarkMode = isOn;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, _isDarkMode);
  }
}