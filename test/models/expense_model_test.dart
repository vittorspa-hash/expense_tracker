// FILE: expense_model_test.dart
// DESCRIZIONE: Test suite per ExpenseModel
// Testa serializzazione, deserializzazione, copyWith e logica di conversione valuta

import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/models/expense_model.dart';

void main() {
  // Raggruppamento logico dei test
  group('ExpenseModel Tests', () {
    
    // --- SETUP: Dati di test riutilizzabili ---
    // Creiamo oggetti di esempio da riutilizzare nei vari test
    late ExpenseModel sampleExpense;
    late DateTime testDate;
    late Map<String, double> testRates;

    setUp(() {
      // Questo metodo viene eseguito PRIMA di ogni test
      // Garantisce che ogni test parta con dati freschi e isolati
      testDate = DateTime(2024, 1, 15, 10, 30);
      testRates = {
        'EUR': 1.0,
        'USD': 1.10,
        'GBP': 0.85,
        'JPY': 130.0,
      };

      sampleExpense = ExpenseModel(
        uuid: 'test-uuid-123',
        value: 100.0,
        description: 'Test expense',
        createdOn: testDate,
        userId: 'user-123',
        currency: 'EUR',
        exchangeRates: testRates,
      );
    });

    // =================================================================
    // TEST 1: Creazione base del modello
    // =================================================================
    test('Should create ExpenseModel with all required fields', () {
      // ARRANGE (preparazione)
      // Dati già preparati nel setUp()

      // ACT (azione)
      final expense = sampleExpense;

      // ASSERT (verifica)
      // Verifichiamo che tutti i campi siano stati assegnati correttamente
      expect(expense.uuid, 'test-uuid-123');
      expect(expense.value, 100.0);
      expect(expense.description, 'Test expense');
      expect(expense.createdOn, testDate);
      expect(expense.userId, 'user-123');
      expect(expense.currency, 'EUR');
      expect(expense.exchangeRates, testRates);
    });

    // =================================================================
    // TEST 2: Serializzazione (toMap - da oggetto a database)
    // =================================================================
    test('Should correctly serialize to Map for database storage', () {
      // ARRANGE
      final expense = sampleExpense;

      // ACT
      final map = expense.toMap();

      // ASSERT
      // Verifichiamo che il Map contenga tutti i campi corretti
      expect(map['uuid'], 'test-uuid-123');
      expect(map['value'], 100.0);
      expect(map['description'], 'Test expense');
      expect(map['createdOn'], testDate.millisecondsSinceEpoch); // Timestamp numerico
      expect(map['userId'], 'user-123');
      expect(map['currency'], 'EUR');
      expect(map['exchangeRates'], testRates);
    });

    // =================================================================
    // TEST 3: Deserializzazione (fromMap - da database a oggetto)
    // =================================================================
    test('Should correctly deserialize from Map retrieved from database', () {
      // ARRANGE
      final mapData = {
        'uuid': 'test-uuid-456',
        'value': 50.5,
        'description': 'Grocery shopping',
        'createdOn': testDate.millisecondsSinceEpoch,
        'userId': 'user-456',
        'currency': 'USD',
        'exchangeRates': {
          'EUR': 1.0,
          'USD': 1.10,
        },
      };

      // ACT
      final expense = ExpenseModel.fromMap(mapData);

      // ASSERT
      expect(expense.uuid, 'test-uuid-456');
      expect(expense.value, 50.5);
      expect(expense.description, 'Grocery shopping');
      expect(expense.createdOn, testDate);
      expect(expense.userId, 'user-456');
      expect(expense.currency, 'USD');
      expect(expense.exchangeRates['EUR'], 1.0);
      expect(expense.exchangeRates['USD'], 1.10);
    });

    // =================================================================
    // TEST 4: Retrocompatibilità (vecchie spese senza currency)
    // =================================================================
    test('Should handle legacy expenses without currency field', () {
      // ARRANGE
      // Simuliamo una vecchia spesa salvata prima dell'introduzione della multi-valuta
      final legacyMap = {
        'uuid': 'legacy-123',
        'value': 75.0,
        'description': 'Old expense',
        'createdOn': testDate.millisecondsSinceEpoch,
        'userId': 'user-789',
        // NOTA: Niente 'currency' e 'exchangeRates'
      };

      // ACT
      final expense = ExpenseModel.fromMap(legacyMap);

      // ASSERT
      // La valuta di default deve essere EUR
      expect(expense.currency, 'EUR');
      // La mappa dei tassi deve essere vuota (non null)
      expect(expense.exchangeRates, isEmpty);
    });

    // =================================================================
    // TEST 5: copyWith - Immutabilità e clonazione parziale
    // =================================================================
    test('Should create modified copy with copyWith while preserving original', () {
      // ARRANGE
      final original = sampleExpense;

      // ACT
      final modified = original.copyWith(
        value: 200.0,
        description: 'Modified description',
      );

      // ASSERT
      // L'oggetto modificato ha i nuovi valori
      expect(modified.value, 200.0);
      expect(modified.description, 'Modified description');
      
      // Gli altri campi rimangono invariati
      expect(modified.uuid, original.uuid);
      expect(modified.currency, original.currency);
      
      // L'oggetto originale NON è stato modificato (immutabilità)
      expect(original.value, 100.0);
      expect(original.description, 'Test expense');
    });

    // =================================================================
    // TEST 6: Conversione valuta - Stessa valuta
    // =================================================================
    test('Should return original value when converting to same currency', () {
      // ARRANGE
      final expense = sampleExpense; // EUR 100

      // ACT
      final converted = expense.getValueIn('EUR');

      // ASSERT
      // Conversione EUR -> EUR = valore originale
      expect(converted, 100.0);
    });

    // =================================================================
    // TEST 7: Conversione valuta - EUR to USD
    // =================================================================
    test('Should correctly convert EUR to USD using exchange rates', () {
      // ARRANGE
      final expense = sampleExpense; // EUR 100
      // Tassi: EUR=1.0, USD=1.10

      // ACT
      final converted = expense.getValueIn('USD'); 

      // ASSERT
      // Formula: (100 / 1.0) * 1.10 = 110.0
      expect(converted, closeTo(110.0, 0.01));  // closeTo() per gestire errori di arrotondamento floating-point
    });

    // =================================================================
    // TEST 8: Conversione valuta - USD to GBP
    // =================================================================
    test('Should correctly convert between non-base currencies', () {
      // ARRANGE
      final expenseInUSD = ExpenseModel(
        uuid: 'usd-expense',
        value: 110.0, // 110 USD
        description: 'USD expense',
        createdOn: testDate,
        userId: 'user-123',
        currency: 'USD',
        exchangeRates: testRates, // USD=1.10, GBP=0.85
      );

      // ACT
      final convertedToGBP = expenseInUSD.getValueIn('GBP');

      // ASSERT
      // Formula: (110 / 1.10) * 0.85 = 85.0
      expect(convertedToGBP, closeTo(85.0, 0.01)); // closeTo per gestire errori arrotondamento floating-point
    });

    // =================================================================
    // TEST 9: Fallback quando mancano i tassi di cambio
    // =================================================================
    test('Should return original value when exchange rates are empty', () {
      // ARRANGE
      final expenseNoRates = ExpenseModel(
        uuid: 'no-rates',
        value: 50.0,
        description: 'Offline expense',
        createdOn: testDate,
        userId: 'user-123',
        currency: 'EUR',
        exchangeRates: {}, // VUOTO - situazione offline
      );

      // ACT
      final converted = expenseNoRates.getValueIn('USD');

      // ASSERT
      // Senza tassi, ritorna il valore originale (failsafe)
      expect(converted, 50.0);
    });

    // =================================================================
    // TEST 10: Protezione divisione per zero
    // =================================================================
    test('Should handle missing currency in exchange rates map safely', () {
      // ARRANGE
      final expense = ExpenseModel(
        uuid: 'incomplete-rates',
        value: 100.0,
        description: 'Incomplete rates',
        createdOn: testDate,
        userId: 'user-123',
        currency: 'EUR',
        exchangeRates: {
          'EUR': 1.0,
          // USD mancante!
        },
      );

      // ACT
      final converted = expense.getValueIn('USD');

      // ASSERT
      // Il metodo deve gestire la valuta mancante senza crashare
      // Fallback: ritorna valore originale
      expect(converted, 100.0);
    });

    // =================================================================
    // TEST 11: Serializzazione round-trip (toMap -> fromMap)
    // =================================================================
    test('Should maintain data integrity through serialization cycle', () {
      // ARRANGE
      final original = sampleExpense;

      // ACT
      final map = original.toMap();
      final reconstructed = ExpenseModel.fromMap(map);

      // ASSERT
      // L'oggetto ricostruito deve essere identico all'originale
      expect(reconstructed.uuid, original.uuid);
      expect(reconstructed.value, original.value);
      expect(reconstructed.description, original.description);
      expect(reconstructed.createdOn, original.createdOn);
      expect(reconstructed.userId, original.userId);
      expect(reconstructed.currency, original.currency);
      expect(reconstructed.exchangeRates, original.exchangeRates);
    });
  });
}