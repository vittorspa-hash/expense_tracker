import 'dart:convert';
import 'dart:async';
import 'package:expense_tracker/models/currency_model.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

/// FILE: currency_service.dart
/// DESCRIZIONE: Servizio per la gestione della valuta e dei tassi di cambio.
/// Gestisce la persistenza della valuta preferita dall'utente tramite SharedPreferences
/// e il recupero dei tassi di cambio dall'API Frankfurter con sistema di caching locale.

class CurrencyService {
  // --- STATO E DIPENDENZE ---
  // Iniezione di SharedPreferences per la persistenza locale dei dati.
  
  final SharedPreferences _prefs;

  CurrencyService({required SharedPreferences sharedPreferences})
      : _prefs = sharedPreferences;

  // --- COSTANTI ---
  // Chiavi per la persistenza e configurazione API.
  
  static const String _currencyKey = 'selected_currency';
  static const String _rateCachePrefix = 'rates_cache_'; 
  static const String _apiBaseUrl = 'https://api.frankfurter.app/latest';
  
  // Lista dei codici valuta supportati dall'applicazione.
  static List<String> get _supportedCodes => Currency.values.map((c) => c.code).toList();

  // --- PERSISTENZA PREFERENZA UTENTE ---
  // Salva la valuta selezionata dall'utente nelle preferenze locali.
  // Lancia un'eccezione se il salvataggio fallisce.
  Future<void> saveCurrency(Currency currency) async {
    try {
      await _prefs.setString(_currencyKey, currency.code);
    } catch (e) {
      throw CurrencyFetchException('Error saving currency: $e');
    }
  }

  // Recupera la valuta salvata dalle preferenze.
  // Restituisce Euro come fallback se non è presente alcuna preferenza salvata
  // o se si verifica un errore durante il recupero.
  Currency getCurrency() {
    try {
      final currencyCode = _prefs.getString(_currencyKey);
      if (currencyCode == null) return Currency.euro;
      return Currency.fromCode(currencyCode);
    } catch (e) {
      return Currency.euro;
    }
  }

  // Rimuove la preferenza di valuta salvata.
  // Utile per il reset delle impostazioni o la disconnessione utente.
  Future<void> clearCurrency() async {
    try {
      await _prefs.remove(_currencyKey);
    } catch (e) {
      throw CurrencyFetchException('Error clearing currency: $e');
    }
  }

  // --- API TASSI DI CAMBIO CON CACHING ---
  // Recupera i tassi di cambio per una valuta base verso tutte le altre supportate.
  // Strategia a due livelli: prima tenta il network, poi fallback su cache locale.
  // Questo garantisce funzionamento offline e riduce le chiamate API.
  Future<Map<String, double>> getExchangeRates(String baseCurrencyCode) async {
    // Valida che la valuta richiesta sia supportata
    if (!_supportedCodes.contains(baseCurrencyCode)) {
      return {baseCurrencyCode: 1.0};
    }

    final cacheKey = '$_rateCachePrefix$baseCurrencyCode';
    final targets = _supportedCodes.where((c) => c != baseCurrencyCode).join(',');

    // 1. TENTATIVO NETWORK
    // Prova a recuperare i tassi aggiornati dall'API con timeout di 6 secondi.
    // Se la richiesta ha successo, aggiorna la cache locale.
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
    // Se il network fallisce, tenta di recuperare i tassi dalla cache locale.
    // Questo permette all'app di funzionare offline con gli ultimi dati disponibili.
    final cachedJson = _prefs.getString(cacheKey);
    if (cachedJson != null) {
      try {
        return _parseRatesJson(cachedJson, baseCurrencyCode);
      } catch (e) {
        debugPrint('CurrencyService Cache Error: $e');
      }
    }

    // Se sia network che cache falliscono, lancia un'eccezione
    throw CurrencyFetchException("Impossible to retrieve exchange rates for $baseCurrencyCode");
  }

  // --- PARSING JSON ---
  // Converte la risposta JSON dell'API in una mappa di tassi di cambio.
  // Include sempre il tasso 1.0 per la valuta base.
  Map<String, double> _parseRatesJson(String jsonString, String baseCurrencyCode) {
    final data = json.decode(jsonString);
    final Map<String, dynamic> ratesJson = data['rates'];
    final Map<String, double> rates = {baseCurrencyCode: 1.0};
    
    ratesJson.forEach((key, value) => rates[key] = (value as num).toDouble());
    
    return rates;
  }
}

/// ECCEZIONE PERSONALIZZATA ---
/// Lanciata quando si verificano errori durante il recupero dei tassi di cambio
/// o la gestione della persistenza della valuta.
class CurrencyFetchException implements Exception {
  final String message;
  CurrencyFetchException(this.message);
  
  @override
  String toString() => "CurrencyFetchException: $message";
}