import 'package:expense_tracker/models/currency_model.dart';
import 'package:flutter/foundation.dart';
import 'package:expense_tracker/services/currency_service.dart';

/// FILE: providers/currency_provider.dart
/// DESCRIZIONE: Provider per la gestione dello stato della valuta.
/// Gestisce la valuta corrente e orchestra il salvataggio delle preferenze.

class CurrencyProvider with ChangeNotifier {
  final CurrencyService _currencyService;
  Currency _currentCurrency = Currency.euro;

  CurrencyProvider({required CurrencyService currencyService})
    : _currencyService = currencyService;

  // --- GETTERS ---
  Currency get currentCurrency => _currentCurrency;

  // Opzionale: Shortcut per accesso rapido (se utili)
  String get currencySymbol => _currentCurrency.symbol;
  String get currencyCode => _currentCurrency.code;
  String get currencyName => _currentCurrency.name;

  // --- LIFECYCLE ---
  Future<void> loadCurrency() async {
    _currentCurrency = _currencyService.getCurrency();
    notifyListeners();
  }

  Future<void> setCurrency(Currency currency) async {
    if (_currentCurrency == currency) return;
    _currentCurrency = currency;
    await _currencyService.saveCurrency(currency);
    notifyListeners();
  }

  // OPZIONALE: Wrapper di convenienza
  // Se preferisci permettere alla UI di chiamare:
  // currencyProvider.formatAmount(100) invece di
  // currencyProvider.currentCurrency.format(100)
  String formatAmount(double amount, {bool showSymbol = true}) {
    return _currentCurrency.format(amount, showSymbol: showSymbol);
  }
}
