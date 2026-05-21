import 'package:expense_tracker/config/di/riverpod_providers.dart';
import 'package:expense_tracker/models/expense_currency.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// FILE: currency_notifier.dart
/// DESCRIZIONE: Gestore dello stato della valuta dell'applicazione (CurrencyState).
/// Espone utility per la formattazione degli importi monetari e persiste la scelta
/// della valuta preferita (Euro, Dollaro, ecc.) tramite il servizio locale dedicato.

// --- STATO ---
class CurrencyState {
  final ExpenseCurrency currentCurrency;

  const CurrencyState({
    this.currentCurrency = ExpenseCurrency.euro,
  });

  // Shortcut di convenienza per l'accesso rapido alle proprietà della valuta
  String get currencySymbol => currentCurrency.symbol;
  String get currencyCode => currentCurrency.code;
  String get currencyName => currentCurrency.name;

  /// Formatta un importo numerico in base alla valuta attiva (es. "1.250,00 €" o "$1,250.00").
  String formatAmount(double amount, {bool showSymbol = true}) {
    return currentCurrency.format(amount, showSymbol: showSymbol);
  }

  CurrencyState copyWith({
    ExpenseCurrency? currentCurrency,
  }) {
    return CurrencyState(
      currentCurrency: currentCurrency ?? this.currentCurrency,
    );
  }
}

// --- NOTIFIER ---
class CurrencyNotifier extends Notifier<CurrencyState> {
  @override
  CurrencyState build() {
    return const CurrencyState();
  }

  // --- CARICAMENTO E SALVATAGGIO ---
  /// Recupera la valuta memorizzata sul dispositivo o effettua il fallback sull'Euro.
  Future<void> loadCurrency() async {
    try {
      final currencyService = await ref.read(currencyServiceProvider.future);
      final currency = currencyService.getCurrency();
      state = state.copyWith(currentCurrency: currency);
    } catch (e) {
      state = state.copyWith(currentCurrency: ExpenseCurrency.euro);
    }
  }

  /// Cambia reattivamente la valuta di sistema e ne persiste la preferenza.
  Future<void> setCurrency(ExpenseCurrency currency) async {
    if (state.currentCurrency == currency) return;

    state = state.copyWith(currentCurrency: currency);
    
    final currencyService = await ref.read(currencyServiceProvider.future);
    await currencyService.saveCurrency(currency);
  }
}