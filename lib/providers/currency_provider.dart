import 'package:flutter/foundation.dart';
import 'package:expense_tracker/services/currency_service.dart';

/// FILE: providers/currency_provider.dart
/// DESCRIZIONE: Provider per la gestione della valuta dell'applicazione.
/// Gestisce lo stato della valuta corrente e notifica i listener dei cambiamenti.

class CurrencyProvider with ChangeNotifier {
  final CurrencyService _currencyService;
  
  Currency _currentCurrency = Currency.euro;

  CurrencyProvider({required CurrencyService currencyService})
      : _currencyService = currencyService; 

  // --- GETTERS ---
  Currency get currentCurrency => _currentCurrency;
  String get currencySymbol => _currentCurrency.symbol;
  String get currencyCode => _currentCurrency.code;
  String get currencyName => _currentCurrency.name;

  // --- METODI PUBBLICI ---
  
  /// Carica la valuta salvata dalle preferenze
  Future<void> loadCurrency() async {
    _currentCurrency = await _currencyService.getCurrency();
    notifyListeners();
  }

  /// Imposta una nuova valuta
  Future<void> setCurrency(Currency currency) async {
    if (_currentCurrency == currency) return;
    
    _currentCurrency = currency;
    await _currencyService.saveCurrency(currency);
    notifyListeners();
  }

  /// Formatta un importo con la valuta corrente
  String formatAmount(double amount, {bool showSymbol = true}) {
    return _currentCurrency.format(amount, showSymbol: showSymbol);
  }
}

/// Enum per le valute supportate
enum Currency {
  euro('EUR', 'Euro', '€'),
  usd('USD', 'US Dollar', '\$'),
  gbp('GBP', 'British Pound', '£'),
  jpy('JPY', 'Japanese Yen', '¥');

  final String code;
  final String name;
  final String symbol;

  const Currency(this.code, this.name, this.symbol);

 /// Formatta un importo con questa valuta
  String format(double amount, {bool showSymbol = true}) {
    final formattedAmount = amount.toStringAsFixed(2);
    
    if (!showSymbol) return formattedAmount;

    // Per lo Yen: Simbolo prima, niente decimali
    if (this == Currency.jpy) {
      return '$symbol${amount.toStringAsFixed(0)}';
    }

    // Per Dollaro E Sterlina: Simbolo prima
    if (this == Currency.usd || this == Currency.gbp) {
      return '$symbol$formattedAmount';
    }

    // Per Euro (uso italiano): Simbolo dopo
    return '$formattedAmount$symbol'; 
  }

  /// Ottiene una Currency dal suo code
  static Currency fromCode(String code) {
    return Currency.values.firstWhere(
      (c) => c.code == code,
      orElse: () => Currency.euro,
    );
  }
}