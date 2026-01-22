import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:expense_tracker/config/supported_locales.dart';
import 'package:expense_tracker/services/language_service.dart';

/// FILE: language_provider.dart
/// DESCRIZIONE: Provider per la gestione dello stato globale della lingua.
/// Gestisce la logica di selezione iniziale (salvato vs sistema) e
/// persiste le preferenze tramite LanguageService.

class LanguageProvider extends ChangeNotifier {
  final LanguageService _languageService;

  LanguageProvider({required LanguageService languageService})
      : _languageService = languageService;

  // --- STATO ---
  Locale _currentLocale = AppLocales.defaultLocale;
  Locale get currentLocale => _currentLocale;

  // --- INIZIALIZZAZIONE ---
  /// Carica la lingua salvata o usa quella di sistema con fallback
  Future<void> fetchLocale() async {
    final savedCode = _languageService.getSavedLanguageCode();
    
    if (savedCode != null) {
      // 1. C'è una preferenza salvata: usiamo quella
      _currentLocale = Locale(savedCode);
      debugPrint('🌍 Loaded saved language: $savedCode');
    } else {
      // 2. Nessun salvataggio: rileviamo la lingua del dispositivo
      final systemLocale = ui.PlatformDispatcher.instance.locale;
      
      // Se la lingua del sistema è supportata, la usiamo
      if (AppLocales.supportedCodes.contains(systemLocale.languageCode)) {
        _currentLocale = Locale(systemLocale.languageCode);
        debugPrint('🌍 Using system language: ${systemLocale.languageCode}');
      } else {
        // Altrimenti usiamo il fallback
        _currentLocale = AppLocales.fallback;
        debugPrint('🌍 System language not supported, using fallback: ${AppLocales.fallback.languageCode}');
      }
    }
    
    notifyListeners();
  }

  // --- CAMBIO LINGUA ---
  /// Cambia la lingua corrente e persiste la preferenza
  Future<void> changeLanguage(Locale newLocale) async {
    if (_currentLocale == newLocale) return;
    
    _currentLocale = newLocale;
    await _languageService.saveLanguageCode(newLocale.languageCode);
    
    debugPrint('🌍 Language changed to: ${newLocale.languageCode}');
    notifyListeners();
  }
}