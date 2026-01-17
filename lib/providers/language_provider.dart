import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:expense_tracker/services/language_service.dart';

/// FILE: language_provider.dart
/// DESCRIZIONE: Provider che gestisce lo stato globale della lingua nell'applicazione.
/// Estende ChangeNotifier per permettere alla UI (es. MaterialApp) di reagire
/// ai cambiamenti di lingua. Si interfaccia con LanguageService per la persistenza
/// delle preferenze dell'utente.

class LanguageProvider extends ChangeNotifier {
  // --- DIPENDENZE ---
  final LanguageService _languageService;

  LanguageProvider({required LanguageService languageService})
      : _languageService = languageService;

  // --- STATO ---
  // Variabile interna che mantiene la locale attualmente attiva.
  // Viene inizializzata di default su Italiano ('it').
  Locale _currentLocale = const Locale('it');

  Locale get currentLocale => _currentLocale;

  // --- INIZIALIZZAZIONE ---
  // Recupera il codice lingua salvato precedentemente nello storage locale.
  // Se esiste un salvataggio lo applica, altrimenti mantiene il default o usa quella di sistema.
  Future<void> fetchLocale() async {
    final savedCode = await _languageService.getSavedLanguageCode();
    
    if (savedCode != null) {
      // 1. C'è una preferenza salvata: usiamo quella
      _currentLocale = Locale(savedCode);
    } else {
      // 2. Nessun salvataggio: rileviamo la lingua del dispositivo
      final systemLocale = ui.PlatformDispatcher.instance.locale;
      
      // Lista delle lingue supportate dalla tua app
      const supportedCodes = ['it', 'en', 'fr', 'es', 'de', 'pt'];

      // Se la lingua del telefono è tra quelle supportate, la usiamo.
      // Altrimenti (es. Tedesco), usiamo l'Inglese (o Italiano) come fallback.
      if (supportedCodes.contains(systemLocale.languageCode)) {
        _currentLocale = Locale(systemLocale.languageCode);
      } else {
        _currentLocale = const Locale('en'); // Fallback internazionale
      }
    }
    notifyListeners();
  }

  // --- GESTIONE CAMBIO LINGUA ---
  // Aggiorna lo stato della lingua corrente e persiste la scelta tramite il service.
  // Notifica i listener per scatenare la ricostruzione dell'interfaccia con la nuova lingua.
  Future<void> changeLanguage(Locale newLocale) async {
    if (_currentLocale == newLocale) return;

    _currentLocale = newLocale;
    await _languageService.saveLanguageCode(newLocale.languageCode);
    
    notifyListeners(); 
  }
}