import 'package:shared_preferences/shared_preferences.dart';
import 'package:expense_tracker/providers/currency_provider.dart';

/// FILE: services/currency_service.dart
/// DESCRIZIONE: Service per la persistenza della valuta selezionata.
/// Gestisce il salvataggio e il recupero della valuta dalle SharedPreferences.

class CurrencyService {
  static const String _currencyKey = 'selected_currency';

  /// Salva la valuta selezionata
  Future<void> saveCurrency(Currency currency) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_currencyKey, currency.code);
    } catch (e) {
      throw Exception('Errore nel salvataggio della valuta: $e');
    }
  }

  /// Recupera la valuta salvata (default: Euro)
  Future<Currency> getCurrency() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currencyCode = prefs.getString(_currencyKey);
      
      if (currencyCode == null) {
        return Currency.euro;
      }
      
      return Currency.fromCode(currencyCode);
    } catch (e) {
      // In caso di errore, ritorna la valuta di default
      return Currency.euro;
    }
  }

  /// Rimuove la valuta salvata (reset alle impostazioni di default)
  Future<void> clearCurrency() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_currencyKey);
    } catch (e) {
      throw Exception('Errore nella rimozione della valuta: $e');
    }
  }
}