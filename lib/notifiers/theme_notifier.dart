import 'package:expense_tracker/config/di/riverpod_providers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// --- STATO ---
// In Riverpod 3.x lo stato è una classe immutabile separata dal Notifier.
class ThemeState {
  final bool isDarkMode;

  const ThemeState({this.isDarkMode = false});

  ThemeMode get themeMode => isDarkMode ? ThemeMode.dark : ThemeMode.light;

  ThemeState copyWith({bool? isDarkMode}) {
    return ThemeState(isDarkMode: isDarkMode ?? this.isDarkMode);
  }
}

// --- NOTIFIER ---
// Estende Notifier<ThemeState> invece di ChangeNotifier.
// Non usa più notifyListeners(): basta assegnare a state.
class ThemeNotifier extends Notifier<ThemeState> {
  @override
  ThemeState build() {
    // build() è il nuovo "costruttore": restituisce lo stato iniziale.
    // L'inizializzazione asincrona la gestiamo in main.dart.
    return const ThemeState();
  }

  Future<void> initialize() async {
    final themeService = ref.read(themeServiceProvider).requireValue;
    final isDark = themeService.loadThemePreference();
    state = state.copyWith(isDarkMode: isDark);
  }

  Future<void> toggleTheme(bool isOn) async {
    state = state.copyWith(isDarkMode: isOn);
    final themeService = ref.read(themeServiceProvider).requireValue;
    await themeService.saveThemePreference(isOn);
  }
}