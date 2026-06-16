import 'package:expense_tracker/config/di/riverpod_providers.dart';
import 'package:expense_tracker/models/expense_currency.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// FILE: currency_notifier.dart
/// DESCRIZIONE: Gestore dello stato della valuta dell'applicazione (CurrencyState).
/// Utilizza un Notifier sincrono di Riverpod, reso possibile dall'iniezione di
/// SharedPreferences tramite override in main.dart. Espone utility per la
/// formattazione degli importi monetari e persiste la valuta preferita tramite
/// il servizio locale dedicato; in caso di errore ricade su Euro come default.

// --- STATO ---
class CurrencyState {
  final ExpenseCurrency currentCurrency;

  const CurrencyState({this.currentCurrency = ExpenseCurrency.euro});

  // Shortcut di convenienza per l'accesso rapido alle proprietà della valuta
  String get currencySymbol => currentCurrency.symbol;
  String get currencyCode => currentCurrency.code;
  String get currencyName => currentCurrency.name;

  /// Formatta un importo numerico in base alla valuta attiva (es. "1.250,00 €" o "$1,250.00").
  String formatAmount(double amount, {bool showSymbol = true}) {
    return currentCurrency.format(amount, showSymbol: showSymbol);
  }

  CurrencyState copyWith({ExpenseCurrency? currentCurrency}) {
    return CurrencyState(
      currentCurrency: currentCurrency ?? this.currentCurrency,
    );
  }
}

// --- NOTIFIER ---
/// Controller sincrono dello stato della valuta. La build() legge la preferenza
/// persistita tramite CurrencyService; in caso di errore ricade su ExpenseCurrency.euro.
class CurrencyNotifier extends Notifier<CurrencyState> {
  @override
  CurrencyState build() {
    try {
      final currencyService = ref.watch(currencyServiceProvider);
      final currency = currencyService.getCurrency();
      return CurrencyState(currentCurrency: currency);
    } catch (e) {
      // Fallback: Euro se la preferenza non è leggibile
      return const CurrencyState(currentCurrency: ExpenseCurrency.euro);
    }
  }

  // --- AZIONI ED OPERAZIONI ---
  /// Aggiorna la valuta attiva solo se diversa da quella corrente,
  /// poi persiste la scelta tramite CurrencyService.
  Future<void> setCurrency(ExpenseCurrency currency) async {
    if (state.currentCurrency == currency) return;
    state = state.copyWith(currentCurrency: currency);
    final currencyService = ref.read(currencyServiceProvider);
    await currencyService.saveCurrency(currency);
  }
}