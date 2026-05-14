import 'dart:ui';
import 'package:expense_tracker/config/di/riverpod_providers.dart';
import 'package:expense_tracker/config/supported_locales.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// --- STATO ---
class LanguageState {
  final Locale currentLocale;

  const LanguageState({this.currentLocale = const Locale('en')});

  LanguageState copyWith({Locale? currentLocale}) {
    return LanguageState(currentLocale: currentLocale ?? this.currentLocale);
  }
}

// --- NOTIFIER ---
class LanguageNotifier extends Notifier<LanguageState> {
  @override
  LanguageState build() {
    return const LanguageState(currentLocale: AppLocales.defaultLocale);
  }

  Future<void> fetchLocale() async {
    final languageService = ref.read(languageServiceProvider).requireValue;
    final savedCode = languageService.getSavedLanguageCode();

    if (savedCode != null) {
      state = state.copyWith(currentLocale: Locale(savedCode));
      debugPrint('🌍 Loaded saved language: $savedCode');
    } else {
      final systemLocale = PlatformDispatcher.instance.locale;
      if (AppLocales.supportedCodes.contains(systemLocale.languageCode)) {
        state = state.copyWith(currentLocale: Locale(systemLocale.languageCode));
        debugPrint('🌍 Using system language: ${systemLocale.languageCode}');
      } else {
        state = state.copyWith(currentLocale: AppLocales.fallback);
        debugPrint('🌍 Using fallback: ${AppLocales.fallback.languageCode}');
      }
    }
  }

  Future<void> changeLanguage(Locale newLocale) async {
    if (state.currentLocale == newLocale) return;
    state = state.copyWith(currentLocale: newLocale);
    final languageService = ref.read(languageServiceProvider).requireValue;
    await languageService.saveLanguageCode(newLocale.languageCode);
    debugPrint('🌍 Language changed to: ${newLocale.languageCode}');
  }
}