import 'package:expense_tracker/config/di/riverpod_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// FILE: theme_notifier.dart
/// DESCRIZIONE: Gestisce lo stato del tema grafico dell'applicazione (Light/Dark Mode).
/// Sfrutta l'architettura Notifier di Riverpod per garantire l'immutabilità dello stato
/// e si interfaccia con ThemeService per la persistenza della preferenza dell'utente.

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
/// Controller dello stato del tema che espone i metodi di modifica alla UI.
class ThemeNotifier extends Notifier<ThemeState> {
  
  @override
  ThemeState build() {
    // Definisce lo stato iniziale del tema al momento della creazione del provider.
    return const ThemeState();
  }

  // --- AZIONI ED OPERAZIONI ---

  /// Inizializza lo stato del tema recuperando la preferenza salvata in locale.
  /// Viene invocato in fase di boot nel file main.dart.
  Future<void> initialize() async {
    final themeService = ref.read(themeServiceProvider).requireValue;
    final isDark = themeService.loadThemePreference();
    state = state.copyWith(isDarkMode: isDark);
  }

  /// Alterna il tema tra Light e Dark mode, aggiornando lo stato e salvando la preferenza.
  Future<void> toggleTheme(bool isOn) async {
    state = state.copyWith(isDarkMode: isOn);
    final themeService = ref.read(themeServiceProvider).requireValue;
    await themeService.saveThemePreference(isOn);
  }
}