import 'package:expense_tracker/config/di/riverpod_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// FILE: theme_notifier.dart
/// DESCRIZIONE: Gestisce lo stato del tema grafico dell'applicazione (Light/Dark Mode).
/// Utilizza un Notifier sincrono di Riverpod, reso possibile dall'iniezione di
/// SharedPreferences tramite override in main.dart, che elimina la necessità di
/// un'inizializzazione asincrona e garantisce la disponibilità immediata dello stato.

// --- STATO ---
/// Rappresentazione immutabile dello stato del tema.
class ThemeState {
  final bool isDarkMode;
  const ThemeState({this.isDarkMode = false});

  /// Getter per convertire il booleano nel tipo `ThemeMode` richiesto da Flutter.
  ThemeMode get themeMode => isDarkMode ? ThemeMode.dark : ThemeMode.light;

  /// Metodo per creare una copia dello stato modificando solo i campi necessari.
  ThemeState copyWith({bool? isDarkMode}) {
    return ThemeState(isDarkMode: isDarkMode ?? this.isDarkMode);
  }
}

// --- NOTIFIER ---
/// Controller sincrono dello stato del tema. La build() è sincrona perché
/// ThemeService opera su un'istanza di SharedPreferences già disponibile
/// a runtime, iniettata tramite override nel ProviderScope di main.dart.
class ThemeNotifier extends Notifier<ThemeState> {
  @override
  ThemeState build() {
    final themeService = ref.watch(themeServiceProvider);
    final isDark = themeService.loadThemePreference();
    return ThemeState(isDarkMode: isDark);
  }

  // --- AZIONI ED OPERAZIONI ---
  /// Alterna il tema tra Light e Dark Mode, aggiornando lo stato in memoria
  /// e persistendo la preferenza tramite ThemeService.
  Future<void> toggleTheme(bool isOn) async {
    state = state.copyWith(isDarkMode: isOn);
    final themeService = ref.read(themeServiceProvider);
    await themeService.saveThemePreference(isOn);
  }
}