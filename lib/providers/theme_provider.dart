// theme_provider.dart
// Gestisce il tema dell’app (chiaro/scuro) e ne salva la preferenza localmente.
// Utilizza SharedPreferences per ricordare la scelta dell’utente tra le sessioni.

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeProvider extends ChangeNotifier {
  // Chiave utilizzata per salvare la preferenza del tema nelle SharedPreferences
  static const _key = "isDarkMode";

  // Stato interno che indica se la dark mode è attiva
  bool _isDarkMode = false;

  // Getter pubblico per conoscere se la dark mode è attiva
  bool get isDarkMode => _isDarkMode;

  // Restituisce il ThemeMode corrente in base allo stato
  ThemeMode get themeMode => _isDarkMode ? ThemeMode.dark : ThemeMode.light;

  // 🚀 NUOVO: Metodo di inizializzazione esplicita
  // Da chiamare nel main prima di runApp
  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _isDarkMode = prefs.getBool(_key) ?? false;
    notifyListeners();
  }

  // Cambia il tema e salva la nuova impostazione nelle SharedPreferences
  Future<void> toggleTheme(bool isOn) async {
    _isDarkMode = isOn;
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_key, _isDarkMode);
  }
}