// FILE: currency_service_test.dart
// DESCRIZIONE: Test suite per CurrencyService
// Testa persistenza valuta, recupero tassi di cambio dall'API,
// sistema di caching locale, e strategie di fallback offline.
// Utilizza MOCK per simulare HTTP e SharedPreferences.

import 'dart:async';

import 'package:expense_tracker/models/expense_currency.dart';
import 'package:expense_tracker/services/currency_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

// Annotazione per generare i mock
// Esegui: flutter pub run build_runner build
@GenerateMocks([SharedPreferences, http.Client])
import 'currency_service_test.mocks.dart';

void main() {
  group('CurrencyService Tests', () {
    // --- SETUP: Mock e dipendenze ---
    late CurrencyService currencyService;
    late MockSharedPreferences mockPrefs;
    late MockClient mockHttpClient;

    setUp(() {
      // Ricrea i mock prima di ogni test per garantire test isolation
      mockPrefs = MockSharedPreferences();
      mockHttpClient = MockClient();

      currencyService = CurrencyService(
        sharedPreferences: mockPrefs,
        httpClient: mockHttpClient,
      );
    });

    // =================================================================
    // TEST 1: Save Currency - Success
    // =================================================================
    test('Should save currency code to SharedPreferences', () async {
      // ARRANGE
      // MOCK: SharedPreferences.setString restituisce true (successo)
      when(
        mockPrefs.setString('selected_currency', 'USD'),
      ).thenAnswer((_) async => true);

      // ACT
      await currencyService.saveCurrency(ExpenseCurrency.usd);

      // ASSERT
      // Verifica che setString sia stato chiamato con i parametri corretti
      verify(mockPrefs.setString('selected_currency', 'USD')).called(1);
    });

    // =================================================================
    // TEST 2: Save Currency - Failure
    // =================================================================
    test('Should throw exception when saving currency fails', () async {
      // ARRANGE
      // MOCK: Simuliamo un errore durante il salvataggio
      when(
        mockPrefs.setString('selected_currency', 'EUR'),
      ).thenThrow(Exception('Storage error'));

      // ACT & ASSERT
      // Verifica che lanci CurrencyFetchException
      await expectLater(
        () => currencyService.saveCurrency(ExpenseCurrency.euro),
        throwsA(isA<CurrencyFetchException>()),
      );
    });

    // =================================================================
    // TEST 3: Get Currency - Fallback to EUR (No Saved Preference)
    // =================================================================
    test('Should return EUR as default when no currency is saved', () {
      // ARRANGE
      // MOCK: SharedPreferences restituisce null (nessuna preferenza salvata)
      when(mockPrefs.getString('selected_currency')).thenReturn(null);

      // ACT
      final currency = currencyService.getCurrency();

      // ASSERT
      // Deve tornare EUR come fallback
      expect(currency, ExpenseCurrency.euro);
    });

    // =================================================================
    // TEST 4: Get Currency - Fallback to EUR (Error)
    // =================================================================
    test('Should return EUR as default when retrieval fails', () {
      // ARRANGE
      // MOCK: Simuliamo un errore durante il recupero
      when(
        mockPrefs.getString('selected_currency'),
      ).thenThrow(Exception('Read error'));

      // ACT
      final currency = currencyService.getCurrency();

      // ASSERT
      // Deve tornare EUR come fallback (non deve crashare!)
      expect(currency, ExpenseCurrency.euro);
    });

    // =================================================================
    // TEST 5: Clear Currency - Success
    // =================================================================
    test('Should remove saved currency from SharedPreferences', () async {
      // ARRANGE
      when(mockPrefs.remove('selected_currency')).thenAnswer((_) async => true);

      // ACT
      await currencyService.clearCurrency();

      // ASSERT
      verify(mockPrefs.remove('selected_currency')).called(1);
    });

    // =================================================================
    // TEST 6: Clear Currency - Failure
    // =================================================================
    test('Should throw exception when clearing currency fails', () async {
      // ARRANGE
      when(
        mockPrefs.remove('selected_currency'),
      ).thenThrow(Exception('Remove error'));

      // ACT & ASSERT
      await expectLater(
        () => currencyService.clearCurrency(),
        throwsA(isA<CurrencyFetchException>()),
      );
    });

    // =================================================================
    // TEST 7: Get Exchange Rates - Unsupported Currency (Fallback)
    // =================================================================
    test('Should return 1:1 rate for unsupported currency', () async {
      // ARRANGE
      const unsupportedCode = 'XYZ'; // Valuta non supportata

      // ACT
      final rates = await currencyService.getExchangeRates(unsupportedCode);

      // ASSERT
      // Deve restituire fallback 1:1 senza chiamare l'API
      expect(rates, {'XYZ': 1.0});

      // Verifica che abbia tentato di chiamare l'API
      verifyNever(mockHttpClient.get(any));

      // Verifica che NON abbia tentato di salvare in cache
      verifyNever(mockPrefs.setString(any, any));
    });

    // =================================================================
    // TEST 8: Get Exchange Rates - Network Success
    // =================================================================
    test(
      'Should fetch and cache exchange rates when network succeeds',
      () async {
        // ARRANGE
        const baseCurrency = 'EUR';
        const mockApiResponse = '''
      {
        "amount": 1.0,
        "base": "EUR",
        "date": "2024-01-15",
        "rates": {
          "USD": 1.10,
          "GBP": 0.85,
          "JPY": 130.0
        }
      }
      ''';

        // MOCK: HTTP Client restituisce successo (200)
        when(
          mockHttpClient.get(any),
        ).thenAnswer((_) async => http.Response(mockApiResponse, 200));

        // MOCK: SharedPreferences salva con successo
        when(mockPrefs.setString(any, any)).thenAnswer((_) async => true);

        // ACT
        final rates = await currencyService.getExchangeRates(baseCurrency);

        // ASSERT
        // 1. Verifica che i tassi siano corretti
        expect(rates, {'EUR': 1.0, 'USD': 1.10, 'GBP': 0.85, 'JPY': 130.0});

        // 2. Verifica che HTTP sia stato chiamato
        verify(mockHttpClient.get(any)).called(1);

        // 3. Verifica che la risposta sia stata salvata in cache
        verify(
          mockPrefs.setString('rates_cache_EUR', mockApiResponse),
        ).called(1);
      },
    );

    // =================================================================
    // TEST 9: Get Exchange Rates - Network Timeout, Cache Hit
    // =================================================================
    test('Should return cached rates when network times out', () async {
      // ARRANGE
      const cachedJson = '''
      {
        "amount": 1.0,
        "base": "USD",
        "date": "2024-01-10",
        "rates": {
          "EUR": 0.91,
          "GBP": 0.77,
          "JPY": 118.0
        }
      }
      ''';

      // MOCK: HTTP timeout (simula network lento)
      when(mockHttpClient.get(any)).thenAnswer((_) async {
        throw TimeoutException('Simulated timeout');
      });

      // MOCK: Cache contiene dati vecchi
      when(mockPrefs.getString('rates_cache_USD')).thenReturn(cachedJson);

      // ACT
      final rates = await currencyService.getExchangeRates('USD');

      // ASSERT
      // 1. Deve usare i tassi dalla cache
      expect(rates, {'USD': 1.0, 'EUR': 0.91, 'GBP': 0.77, 'JPY': 118.0});

      // 2. Verifica che abbia tentato il network
      verify(mockHttpClient.get(any)).called(1);

      // 3. Verifica che abbia fatto fallback su cache
      verify(mockPrefs.getString('rates_cache_USD')).called(1);
    });

    // =================================================================
    // TEST 10: Get Exchange Rates - Network Fails, Cache Hit
    // =================================================================
    test('Should use cache when network returns error status', () async {
      // ARRANGE
      const cachedJson = '''
      {
        "amount": 1.0,
        "base": "GBP",
        "date": "2024-01-12",
        "rates": {
          "EUR": 1.18,
          "USD": 1.30,
          "JPY": 152.0
        }
      }
      ''';

      // MOCK: HTTP restituisce 500 → non entra nel blocco if (statusCode == 200)
      // → non lancia eccezione → cade direttamente nel fallback cache
      when(
        mockHttpClient.get(any),
      ).thenAnswer((_) async => http.Response('Internal Server Error', 500));

      // MOCK: Cache contiene dati
      when(mockPrefs.getString('rates_cache_GBP')).thenReturn(cachedJson);

      // ACT
      final rates = await currencyService.getExchangeRates('GBP');

      // ASSERT
      expect(rates, {'GBP': 1.0, 'EUR': 1.18, 'USD': 1.30, 'JPY': 152.0});

      verify(mockHttpClient.get(any)).called(1);
      verify(mockPrefs.getString('rates_cache_GBP')).called(1);
    });

    // =================================================================
    // TEST 11: Get Exchange Rates - Both Network and Cache Fail
    // =================================================================
    test('Should throw exception when both network and cache fail', () async {
      // ARRANGE
      // MOCK: HTTP lancia eccezione (no internet)
      when(
        mockHttpClient.get(any),
      ).thenThrow(Exception('No internet connection'));

      // MOCK: Cache vuota
      when(mockPrefs.getString('rates_cache_JPY')).thenReturn(null);

      // ACT & ASSERT
      await expectLater(
        () => currencyService.getExchangeRates('JPY'),
        throwsA(isA<CurrencyFetchException>()),
      );

      // Verifica che abbia tentato entrambi
      verify(mockHttpClient.get(any)).called(1);
      verify(mockPrefs.getString('rates_cache_JPY')).called(1);
    });

    // =================================================================
    // TEST 12: Get Exchange Rates - Network Success Updates Old Cache
    // =================================================================
    test('Should update cache with fresh data when network succeeds', () async {
      // ARRANGE
      const oldCache = '{"rates":{"USD":1.05}}'; // Dati vecchi
      const newApiResponse = '''
      {
        "amount": 1.0,
        "base": "EUR",
        "date": "2024-01-20",
        "rates": {
          "USD": 1.12,
          "GBP": 0.88,
          "JPY": 135.0
        }
      }
      ''';

      // MOCK: Cache contiene dati vecchi
      when(mockPrefs.getString('rates_cache_EUR')).thenReturn(oldCache);

      // MOCK: HTTP restituisce dati freschi
      when(
        mockHttpClient.get(any),
      ).thenAnswer((_) async => http.Response(newApiResponse, 200));

      when(mockPrefs.setString(any, any)).thenAnswer((_) async => true);

      // ACT
      final rates = await currencyService.getExchangeRates('EUR');

      // ASSERT
      // 1. Deve usare i dati FRESCHI dall'API, non la cache vecchia
      expect(rates['USD'], 1.12); // Non 1.05 dalla cache!

      // 2. Verifica che la cache sia stata aggiornata
      verify(mockPrefs.setString('rates_cache_EUR', newApiResponse)).called(1);

      // 3. Non deve chiamare la cache locale
      verifyNever(mockPrefs.getString('rates_cache_EUR'));
    });

    // =================================================================
    // TEST 13: Multiple Currency Codes - Supported Codes
    // =================================================================
    test('Should retrieve correct currency for all supported codes', () {
      final testCases = {
        'EUR': ExpenseCurrency.euro,
        'USD': ExpenseCurrency.usd,
        'GBP': ExpenseCurrency.gbp,
        'JPY': ExpenseCurrency.jpy,
      };

      for (final entry in testCases.entries) {
        when(mockPrefs.getString('selected_currency')).thenReturn(entry.key);
        expect(
          currencyService.getCurrency(),
          entry.value,
          reason: 'Failed for currency: ${entry.key}',
        );
      }
    });

    // =================================================================
    // TEST 14: Cache Corrupted JSON
    // =================================================================
    test('Should throw exception when cache contains malformed JSON', () async {
      when(mockHttpClient.get(any)).thenThrow(Exception('No internet'));
      when(mockPrefs.getString('rates_cache_EUR')).thenReturn('NOT_VALID_JSON');

      await expectLater(
        () => currencyService.getExchangeRates('EUR'),
        throwsA(isA<CurrencyFetchException>()),
      );
    });
  });
}
