import 'dart:convert';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:expense_tracker/providers/currency_provider.dart';

/// FILE: services/currency_service.dart
/// DESCRIZIONE: Service responsabile della gestione delle valute.
/// Implementa strategia "Network First, Cache Fallback".
/// Se nessun dato è disponibile (né rete, né cache), LANCIA UN'ECCEZIONE 
/// permettendo al Provider di gestire il "Soft Fail" (fallback 1:1 e avviso UI).

// --- ECCEZIONE CUSTOM ---
class CurrencyFetchException implements Exception {
  final String message;
  CurrencyFetchException(this.message);
  
  @override
  String toString() => "CurrencyFetchException: $message";
}

class CurrencyService {
  static const String _currencyKey = 'selected_currency';
  static const String _rateCachePrefix = 'rates_cache_'; 
  
  static const String _apiBaseUrl = 'https://api.frankfurter.app/latest';
  static const List<String> _supportedCodes = ['EUR', 'USD', 'GBP', 'JPY'];

  // --- PERSISTENZA PREFERENZA UTENTE ---
  
  Future<void> saveCurrency(Currency currency) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_currencyKey, currency.code);
    } catch (e) {
      throw Exception('Error saving currency: $e');
    }
  }

  Future<Currency> getCurrency() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final currencyCode = prefs.getString(_currencyKey);
      
      if (currencyCode == null) return Currency.euro;
      
      return Currency.fromCode(currencyCode);
    } catch (e) {
      return Currency.euro;
    }
  }

  Future<void> clearCurrency() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_currencyKey);
    } catch (e) {
      throw Exception('Error clearing currency: $e');
    }
  }

  // --- API TASSI DI CAMBIO CON CACHING ---
  
  // 1. Tenta Network (con timeout) -> Se OK, Salva in Cache e restituisce.
  // 2. Se Network fallisce -> Tenta di leggere dalla Cache.
  // 3. Se Cache manca o corrotta -> LANCIA ECCEZIONE (Il Provider attiverà il warning).
  Future<Map<String, double>> getExchangeRates(String baseCurrencyCode) async {
    // Validazione: se la valuta non è supportata dall'API, restituisci 1:1 standard.
    if (!_supportedCodes.contains(baseCurrencyCode)) {
      return {baseCurrencyCode: 1.0};
    }

    final prefs = await SharedPreferences.getInstance();
    final cacheKey = '$_rateCachePrefix$baseCurrencyCode';
    final targets = _supportedCodes.where((c) => c != baseCurrencyCode).join(',');

    // 1. TENTATIVO NETWORK
    try {
      final url = Uri.parse('$_apiBaseUrl?from=$baseCurrencyCode&to=$targets');
      final response = await http.get(url).timeout(const Duration(seconds: 6));

      if (response.statusCode == 200) {
        // Successo: Salviamo in cache per usi futuri offline
        await prefs.setString(cacheKey, response.body);
        return _parseRatesJson(response.body, baseCurrencyCode);
      } else {
        debugPrint('CurrencyService API Error: ${response.statusCode}. Trying cache...');
      }
    } catch (e) {
      debugPrint('CurrencyService Network Error: $e. Switching to cache...');
    }

    // 2. TENTATIVO CACHE (FALLBACK)
    if (prefs.containsKey(cacheKey)) {
      try {
        final cachedJson = prefs.getString(cacheKey);
        if (cachedJson != null) {
          debugPrint('CurrencyService: Using cached rates for $baseCurrencyCode');
          return _parseRatesJson(cachedJson, baseCurrencyCode);
        }
      } catch (e) {
        debugPrint('CurrencyService Cache Error: Could not parse cache. $e');
      }
    }

    // 3. FALLIMENTO TOTALE (Critical Path)
    // Nessuna rete e nessuna cache valida.
    // L'app deve sapere che la conversione è impossibile per attivare il warning.
    debugPrint('CurrencyService: No data available (No Net, No Cache). Throwing exception.');
    throw CurrencyFetchException("Impossible to retrieve exchange rates for $baseCurrencyCode");
  }

  // --- HELPER PRIVATI ---
  
  Map<String, double> _parseRatesJson(String jsonString, String baseCurrencyCode) {
    final data = json.decode(jsonString);
    final Map<String, dynamic> ratesJson = data['rates'];
    
    final Map<String, double> rates = {};
    
    // Assicuriamo che il tasso base sia sempre presente e uguale a 1.0
    rates[baseCurrencyCode] = 1.0; 

    ratesJson.forEach((key, value) {
      rates[key] = (value as num).toDouble();
    });

    return rates;
  }
}