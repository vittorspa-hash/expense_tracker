import 'dart:ui';
import 'package:expense_tracker/config/di/riverpod_providers.dart';
import 'package:expense_tracker/config/supported_locales.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// FILE: language_notifier.dart
/// DESCRIZIONE: Gestore dello stato della localizzazione dell'app (LanguageState).
/// Utilizza un Notifier sincrono di Riverpod, reso possibile dall'iniezione di
/// SharedPreferences tramite override in main.dart. La build() determina la lingua
/// attiva seguendo una priorità: preferenza salvata → lingua di sistema (se supportata)
/// → lingua di fallback globale definita in AppLocales.

// --- STATO ---
class LanguageState {
  final Locale currentLocale;

  const LanguageState({this.currentLocale = const Locale('en')});

  LanguageState copyWith({Locale? currentLocale}) {
    return LanguageState(currentLocale: currentLocale ?? this.currentLocale);
  }
}

// --- NOTIFIER ---
/// Controller sincrono dello stato della lingua. La build() risolve la lingua attiva
/// al primo accesso seguendo la catena di fallback: preferenza persistita →
/// locale di sistema → AppLocales.fallback.
class LanguageNotifier extends Notifier<LanguageState> {
  @override
  LanguageState build() {
    final languageService = ref.watch(languageServiceProvider);
    final savedCode = languageService.getSavedLanguageCode();

    if (savedCode != null) {
      return LanguageState(currentLocale: Locale(savedCode));
    }

    final systemLocale = PlatformDispatcher.instance.locale;
    if (AppLocales.supportedCodes.contains(systemLocale.languageCode)) {
      return LanguageState(currentLocale: Locale(systemLocale.languageCode));
    }

    return const LanguageState(currentLocale: AppLocales.fallback);
  }

  // --- CAMBIO LINGUA ---
  /// Aggiorna la lingua attiva solo se diversa da quella corrente,
  /// poi persiste la scelta tramite LanguageService.
  Future<void> changeLanguage(Locale newLocale) async {
    if (state.currentLocale == newLocale) return;
    state = state.copyWith(currentLocale: newLocale);
    final languageService = ref.read(languageServiceProvider);
    await languageService.saveLanguageCode(newLocale.languageCode);
  }
}