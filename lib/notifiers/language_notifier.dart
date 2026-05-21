import 'dart:ui';
import 'package:expense_tracker/config/di/riverpod_providers.dart';
import 'package:expense_tracker/config/supported_locales.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// FILE: language_notifier.dart
/// DESCRIZIONE: Gestore dello stato della localizzazione dell'app (LanguageState).
/// Determina la lingua attiva all'avvio analizzando le preferenze salvate in locale,
/// effettuando un fallback sul linguaggio di sistema o sulla lingua predefinita globale.

// --- STATO ---
class LanguageState {
  final Locale currentLocale;

  const LanguageState({
    this.currentLocale = const Locale('en'),
  });

  LanguageState copyWith({
    Locale? currentLocale,
  }) {
    return LanguageState(
      currentLocale: currentLocale ?? this.currentLocale,
    );
  }
}

// --- NOTIFIER ---
class LanguageNotifier extends Notifier<LanguageState> {
  @override
  LanguageState build() {
    return const LanguageState(currentLocale: AppLocales.defaultLocale);
  }

  // --- CARICAMENTO PREFERENZE ---
  /// Recupera la lingua salvata sul dispositivo o negozia il miglior fallback possibile.
  Future<void> fetchLocale() async {
    final languageService = await ref.read(languageServiceProvider.future);
    final savedCode = languageService.getSavedLanguageCode();

    if (savedCode != null) {
      state = state.copyWith(currentLocale: Locale(savedCode));
      return;
    }

    final systemLocale = PlatformDispatcher.instance.locale;
    if (AppLocales.supportedCodes.contains(systemLocale.languageCode)) {
      state = state.copyWith(currentLocale: Locale(systemLocale.languageCode));
    } else {
      state = state.copyWith(currentLocale: AppLocales.fallback);
    }
  }

  // --- CAMBIO LINGUA ---
  /// Aggiorna reattivamente la lingua dell'applicazione e persiste la scelta in locale.
  Future<void> changeLanguage(Locale newLocale) async {
    if (state.currentLocale == newLocale) return;

    state = state.copyWith(currentLocale: newLocale);
    
    final languageService = await ref.read(languageServiceProvider.future);
    await languageService.saveLanguageCode(newLocale.languageCode);
  }
}