import 'package:expense_tracker/config/di/riverpod_providers.dart';
import 'package:expense_tracker/models/expense_currency.dart';
import 'package:expense_tracker/services/currency_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

// --- STATO ---
class CurrencyState {
  final ExpenseCurrency currentCurrency;

  const CurrencyState({this.currentCurrency = ExpenseCurrency.euro});

  // Shortcuts di convenienza identici a prima
  String get currencySymbol => currentCurrency.symbol;
  String get currencyCode => currentCurrency.code;
  String get currencyName => currentCurrency.name;

  String formatAmount(double amount, {bool showSymbol = true}) {
    return currentCurrency.format(amount, showSymbol: showSymbol);
  }

  CurrencyState copyWith({ExpenseCurrency? currentCurrency}) {
    return CurrencyState(currentCurrency: currentCurrency ?? this.currentCurrency);
  }
}

// --- NOTIFIER ---
class CurrencyNotifier extends Notifier<CurrencyState> {
  @override
  CurrencyState build() {
    return const CurrencyState();
  }

  CurrencyService get _currencyService => ref.read(currencyServiceProvider).requireValue;

  Future<void> loadCurrency() async {
    try {
      final currency = _currencyService.getCurrency();
      state = state.copyWith(currentCurrency: currency);
    } catch (e) {
      state = state.copyWith(currentCurrency: ExpenseCurrency.euro);
    }
  }

  Future<void> setCurrency(ExpenseCurrency currency) async {
    if (state.currentCurrency == currency) return;
    state = state.copyWith(currentCurrency: currency);
    await _currencyService.saveCurrency(currency);
  }
}