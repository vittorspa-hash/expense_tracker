import 'package:expense_tracker/models/currency_model.dart';
import 'package:flutter/foundation.dart';
import 'package:expense_tracker/services/currency_service.dart';

/// FILE: currency_provider.dart
/// DESCRIZIONE: State Manager per la gestione della valuta (ChangeNotifier).
/// Agisce come intermediario tra la UI e il CurrencyService, gestendo la valuta
/// corrente dell'applicazione e propagando le modifiche a tutti i listener.

class CurrencyProvider with ChangeNotifier {
  // --- STATO E DIPENDENZE ---
  // Iniezione del servizio di gestione valuta e mantenimento dello stato
  // della valuta correntemente selezionata dall'utente.
  
  final CurrencyService _currencyService;
  Currency _currentCurrency = Currency.euro;

  CurrencyProvider({required CurrencyService currencyService})
      : _currencyService = currencyService;

  // --- GETTERS ---
  // Espongono lo stato della valuta corrente e le sue proprietà
  // per l'accesso dalla UI senza esporre direttamente l'oggetto interno.
  
  Currency get currentCurrency => _currentCurrency;

  // Shortcuts di convenienza per accesso rapido alle proprietà della valuta
  // senza dover accedere all'oggetto Currency completo.
  String get currencySymbol => _currentCurrency.symbol;
  String get currencyCode => _currentCurrency.code;
  String get currencyName => _currentCurrency.name;

  // --- LIFECYCLE ---
  // Carica la valuta salvata nelle preferenze utente all'avvio dell'app.
  // In caso di errore applica un fallback sicuro (Euro) per evitare stati inconsistenti.
  Future<void> loadCurrency() async {
    try {
      _currentCurrency = _currencyService.getCurrency();
    } catch (e) {
      _currentCurrency = Currency.euro; // Fallback esplicito
    } finally {
      notifyListeners();
    }
  }

  // --- AGGIORNAMENTO VALUTA ---
  // Aggiorna la valuta corrente e persiste la modifica nelle preferenze.
  // Evita notifiche superflue se la valuta selezionata è già quella corrente.
  Future<void> setCurrency(Currency currency) async {
    if (_currentCurrency == currency) return;
    
    _currentCurrency = currency;
    await _currencyService.saveCurrency(currency);
    notifyListeners();
  }

  // --- UTILITY DI FORMATTAZIONE ---
  // Wrapper di convenienza per permettere alla UI di formattare importi
  // senza accedere direttamente all'oggetto Currency.
  // Esempio: currencyProvider.formatAmount(100) invece di
  // currencyProvider.currentCurrency.format(100)
  String formatAmount(double amount, {bool showSymbol = true}) {
    return _currentCurrency.format(amount, showSymbol: showSymbol);
  }
}