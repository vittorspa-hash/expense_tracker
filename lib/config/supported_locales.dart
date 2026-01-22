import 'package:flutter/material.dart';

/// FILE: config/supported_locales.dart
/// DESCRIZIONE: Configurazione centralizzata delle lingue supportate dall'app

class AppLocales {
  // Lista codici lingua supportati (per validazione)
  static const List<String> supportedCodes = [
    'it', // Italiano
    'en', // English
    'fr', // Français
    'es', // Español
    'de', // Deutsch
    'pt', // Português
  ];
  
  // Lista Locale supportati (per MaterialApp)
  static const List<Locale> supportedLocales = [
    Locale('it'),
    Locale('en'),
    Locale('fr'),
    Locale('es'),
    Locale('de'),
    Locale('pt'),
  ];
  
  // Locale di fallback quando la lingua del sistema non è supportata
  static const Locale fallback = Locale('en');
  
  // Locale di default se nessuna preferenza salvata (opzionale)
  static const Locale defaultLocale = Locale('it');
}