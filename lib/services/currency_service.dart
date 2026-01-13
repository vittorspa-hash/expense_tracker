import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:expense_tracker/providers/currency_provider.dart';

/// FILE: services/currency_service.dart
/// DESCRIZIONE: Service responsabile della gestione delle valute.
/// Gestisce la persistenza locale della preferenza utente tramite SharedPreferences
/// e comunica con API esterne (Frankfurter) per ottenere i tassi di cambio aggiornati.

class CurrencyService {
  static const String _currencyKey = 'selected_currency';
  
  static const String _apiBaseUrl = 'https://api.frankfurter.app/latest';
  
  static const List<String> _supportedCodes = ['EUR', 'USD', 'GBP', 'JPY'];

  // --- PERSISTENZA ---
  // Salva il codice della valuta selezionata (Enum) nella memoria locale
  // per mantenerla attiva ai successivi avvii dell'app.
  Future<void> saveCurrency(Currency currency) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_currencyKey, currency.code);
    } catch (e) {
      throw Exception('Error saving currency: $e');
    }
  }

  // Recupera la valuta salvata dalle preferenze.
  // Se non viene trovata alcuna preferenza (es. primo avvio), restituisce Euro come default.
  Future<Currency> getCurrency() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currencyCode = prefs.getString(_currencyKey);
      
      if (currencyCode == null) {
        return Currency.euro;
      }
      
      return Currency.fromCode(currencyCode);
    } catch (e) {
      return Currency.euro;
    }
  }

  // Rimuove la preferenza salvata, riportando l'app allo stato iniziale per la valuta.
  Future<void> clearCurrency() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_currencyKey);
    } catch (e) {
      throw Exception('Error clearing currency: $e');
    }
  }

  // --- API TASSI DI CAMBIO ---
  // Scarica i tassi di cambio attuali da un'API pubblica (Frankfurter).
  // Costruisce la richiesta escludendo la valuta base e richiedendo solo le valute supportate.
  // Gestisce errori di rete o offline restituendo una mappa sicura (fallback) 
  // che contiene solo la valuta base a valore 1.0.
  Future<Map<String, double>> getExchangeRates(String baseCurrencyCode) async {
    // 1. Validazione preliminare
    if (!_supportedCodes.contains(baseCurrencyCode)) {
      return {baseCurrencyCode: 1.0};
    }

    // 2. Preparazione target
    final targets = _supportedCodes.where((c) => c != baseCurrencyCode).join(',');

    try {
      // 3. Chiamata API
      final url = Uri.parse('$_apiBaseUrl?from=$baseCurrencyCode&to=$targets');
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final Map<String, dynamic> ratesJson = data['rates'];

        // 4. Mapping e normalizzazione
        final Map<String, double> rates = {};
        
        // Aggiungiamo la base stessa per semplificare i calcoli futuri
        rates[baseCurrencyCode] = 1.0; 

        ratesJson.forEach((key, value) {
          rates[key] = (value as num).toDouble();
        });

        return rates;
      } else {
        debugPrint('CurrencyService Error: API returned ${response.statusCode}');
        return {baseCurrencyCode: 1.0};
      }
    } catch (e) {
      debugPrint('CurrencyService Error: $e');
      return {baseCurrencyCode: 1.0};
    }
  }
}