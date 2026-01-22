import 'dart:convert';
import 'dart:async';
import 'package:expense_tracker/models/currency_model.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class CurrencyFetchException implements Exception {
  final String message;
  CurrencyFetchException(this.message);
  @override
  String toString() => "CurrencyFetchException: $message";
}

/// FILE: services/currency_service.dart
class CurrencyService {
  final SharedPreferences _prefs;

  CurrencyService({required SharedPreferences sharedPreferences})
      : _prefs = sharedPreferences;

  static const String _currencyKey = 'selected_currency';
  static const String _rateCachePrefix = 'rates_cache_'; 
  static const String _apiBaseUrl = 'https://api.frankfurter.app/latest';
  static List<String> get _supportedCodes => Currency.values.map((c) => c.code).toList();

  // --- PERSISTENZA PREFERENZA UTENTE ---
  
  Future<void> saveCurrency(Currency currency) async {
    try {
      await _prefs.setString(_currencyKey, currency.code);
    } catch (e) {
      throw Exception('Error saving currency: $e');
    }
  }

  Currency getCurrency() {
    try {
      final currencyCode = _prefs.getString(_currencyKey);
      if (currencyCode == null) return Currency.euro;
      return Currency.fromCode(currencyCode);
    } catch (e) {
      return Currency.euro;
    }
  }

  Future<void> clearCurrency() async {
    try {
      await _prefs.remove(_currencyKey);
    } catch (e) {
      throw Exception('Error clearing currency: $e');
    }
  }

  // --- API TASSI DI CAMBIO CON CACHING ---
  
  Future<Map<String, double>> getExchangeRates(String baseCurrencyCode) async {
    if (!_supportedCodes.contains(baseCurrencyCode)) {
      return {baseCurrencyCode: 1.0};
    }

    final cacheKey = '$_rateCachePrefix$baseCurrencyCode';
    final targets = _supportedCodes.where((c) => c != baseCurrencyCode).join(',');

    // 1. TENTATIVO NETWORK
    try {
      final url = Uri.parse('$_apiBaseUrl?from=$baseCurrencyCode&to=$targets');
      final response = await http.get(url).timeout(const Duration(seconds: 6));

      if (response.statusCode == 200) {
        await _prefs.setString(cacheKey, response.body);
        return _parseRatesJson(response.body, baseCurrencyCode);
      }
    } catch (e) {
      debugPrint('CurrencyService Network Error: $e. Switching to cache...');
    }

    // 2. TENTATIVO CACHE (FALLBACK)
    final cachedJson = _prefs.getString(cacheKey);
    if (cachedJson != null) {
      try {
        return _parseRatesJson(cachedJson, baseCurrencyCode);
      } catch (e) {
        debugPrint('CurrencyService Cache Error: $e');
      }
    }

    throw CurrencyFetchException("Impossible to retrieve exchange rates for $baseCurrencyCode");
  }

  Map<String, double> _parseRatesJson(String jsonString, String baseCurrencyCode) {
    final data = json.decode(jsonString);
    final Map<String, dynamic> ratesJson = data['rates'];
    final Map<String, double> rates = {baseCurrencyCode: 1.0};
    ratesJson.forEach((key, value) => rates[key] = (value as num).toDouble());
    return rates;
  }
}