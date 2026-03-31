// FILE: expense_model_test.dart
// DESCRIZIONE: Test suite per ExpenseModel
// Testa serializzazione, deserializzazione, copyWith e logica di conversione valuta

import 'package:expense_tracker/models/expense_currency.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/models/expense_model.dart';
import 'package:expense_tracker/models/expense_category.dart';

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
      testRates = {'EUR': 1.0, 'USD': 1.10, 'GBP': 0.85, 'JPY': 130.0};

      sampleExpense = ExpenseModel(
        uuid: 'test-uuid-123',
        value: 100.0,
        description: 'Test expense',
        createdOn: testDate,
        userId: 'user-123',
        currency: ExpenseCurrency.euro,
        exchangeRates: testRates,
        category: ExpenseCategory.food,
      );
    });

    // =================================================================
    // TEST 1: Creazione base del modello - Test superfluo
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
      expect(expense.currency, ExpenseCurrency.euro);
      expect(expense.exchangeRates, testRates);
      expect(expense.category, ExpenseCategory.food);
    });

    // =================================================================
    // TEST 2: Categoria default (other) quando non specificata
    // =================================================================
    test('Should default category to other when not provided', () {
      // ARRANGE
      // Creiamo una spesa senza specificare la categoria

      // ACT
      final expense = ExpenseModel(
        uuid: 'test-uuid',
        value: 10.0,
        description: null,
        createdOn: testDate,
        userId: 'user-123',
        currency: ExpenseCurrency.euro,
        exchangeRates: {},
        // category non passata → default
      );

      // ASSERT
      // La categoria di default deve essere other per retrocompatibilità
      expect(expense.category, ExpenseCategory.other);
    });

    // =================================================================
    // TEST 3: Serializzazione (toMap - da oggetto a database)
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
      expect(
        map['createdOn'],
        testDate.millisecondsSinceEpoch,
      ); // Timestamp numerico
      expect(map['userId'], 'user-123');
      expect(map['currency'], 'EUR'); // Enum serializzato come codice ISO
      expect(map['exchangeRates'], testRates);
      expect(
        map['category'],
        'food',
      ); // Enum serializzato come stringa leggibile
    });

    // =================================================================
    // TEST 4: Deserializzazione (fromMap - da database a oggetto)
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
        'exchangeRates': {'EUR': 1.0, 'USD': 1.10},
        'category': 'shopping',
      };

      // ACT
      final expense = ExpenseModel.fromMap(mapData);

      // ASSERT
      expect(expense.uuid, 'test-uuid-456');
      expect(expense.value, 50.5);
      expect(expense.description, 'Grocery shopping');
      expect(expense.createdOn, testDate);
      expect(expense.userId, 'user-456');
      expect(expense.currency, ExpenseCurrency.usd); // Stringa DB → Enum App
      expect(expense.exchangeRates, {'EUR': 1.0, 'USD': 1.10});
      expect(expense.category, ExpenseCategory.shopping);
    });

    // =================================================================
    // TEST 5: Retrocompatibilità (vecchie spese senza currency e senza category)
    // =================================================================
    test(
      'Should handle legacy expenses without currency and category fields',
      () {
        // ARRANGE
        // Simuliamo una vecchia spesa salvata prima dell'introduzione
        // della multi-valuta e delle categorie
        final legacyMap = {
          'uuid': 'legacy-123',
          'value': 75.0,
          'description': 'Old expense',
          'createdOn': testDate.millisecondsSinceEpoch,
          'userId': 'user-789',
          // Niente 'currency', 'exchangeRates', né 'category'
        };

        // ACT
        final expense = ExpenseModel.fromMap(legacyMap);

        // ASSERT
        expect(expense.currency, ExpenseCurrency.euro); // fallback valuta
        expect(expense.category, ExpenseCategory.other); // fallback categoria
        // La mappa dei tassi deve essere vuota (non null)
        expect(expense.exchangeRates, isEmpty);
      },
    );

    // =================================================================
    // TEST 6: Retrocompatibilità — categoria con stringa sconosciuta
    // =================================================================
    test('Should fallback to other for unknown category string from DB', () {
      // ARRANGE: simula un valore corrotto o deprecato nel DB
      final mapData = {
        'uuid': 'corrupted-cat',
        'value': 20.0,
        'description': null,
        'createdOn': testDate.millisecondsSinceEpoch,
        'userId': 'user-123',
        'currency': 'EUR',
        'exchangeRates': <String, dynamic>{},
        'category': 'nonexistent_category', // valore non valido
      };

      // ACT
      final expense = ExpenseModel.fromMap(mapData);

      // ASSERT
      // fromJson deve gestire silenziosamente valori sconosciuti
      expect(expense.category, ExpenseCategory.other);
    });

    // =================================================================
    // TEST 7: copyWith - Immutabilità e clonazione parziale (campi esistenti)
    // =================================================================
    test(
      'Should create modified copy with copyWith while preserving original',
      () {
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
        expect(modified.category, original.category); // categoria preservata

        // L'oggetto originale NON è stato modificato (immutabilità)
        expect(original.value, 100.0);
        expect(original.description, 'Test expense');
      },
    );

    // =================================================================
    // TEST 8: copyWith - Modifica della categoria
    // =================================================================
    test('Should correctly update category via copyWith', () {
      // ARRANGE
      final original = sampleExpense; // category: food

      // ACT
      final modified = original.copyWith(category: ExpenseCategory.travel);

      // ASSERT
      expect(modified.category, ExpenseCategory.travel);
      // L'oggetto originale NON è stato modificato (immutabilità)
      expect(original.category, ExpenseCategory.food);
    });

    // =================================================================
    // TEST 9: Conversione valuta - Stessa valuta
    // =================================================================
    test('Should return original value when converting to same currency', () {
      // ARRANGE
      final expense = sampleExpense; // EUR 100

      // ACT
      final converted = expense.getValueIn(ExpenseCurrency.euro);

      // ASSERT
      // Conversione EUR -> EUR = valore originale
      expect(converted, 100.0);
    });

    // =================================================================
    // TEST 10: Conversione valuta - EUR to USD
    // =================================================================
    test('Should correctly convert EUR to USD using exchange rates', () {
      // ARRANGE
      final expense = sampleExpense; // EUR 100
      // Tassi: EUR=1.0, USD=1.10

      // ACT
      final converted = expense.getValueIn(ExpenseCurrency.usd);

      // ASSERT
      // Formula: (100 / 1.0) * 1.10 = 110.0
      expect(
        converted,
        closeTo(110.0, 0.01),
      ); // closeTo() per gestire errori di arrotondamento floating-point
    });

    // =================================================================
    // TEST 11: Conversione valuta - USD to GBP
    // =================================================================
    test('Should correctly convert between non-base currencies', () {
      // ARRANGE
      final expenseInUSD = ExpenseModel(
        uuid: 'usd-expense',
        value: 110.0, // 110 USD
        description: 'USD expense',
        createdOn: testDate,
        userId: 'user-123',
        currency: ExpenseCurrency.usd,
        category: ExpenseCategory.food,
        exchangeRates: testRates, // USD=1.10, GBP=0.85
      );

      // ACT
      final convertedToGBP = expenseInUSD.getValueIn(ExpenseCurrency.gbp);

      // ASSERT
      // Formula: (110 / 1.10) * 0.85 = 85.0
      expect(
        convertedToGBP,
        closeTo(85.0, 0.01),
      ); // closeTo per gestire errori arrotondamento floating-point
    });

    // =================================================================
    // TEST 12: Fallback quando mancano i tassi di cambio
    // =================================================================
    test('Should return original value when exchange rates are empty', () {
      // ARRANGE
      final expenseNoRates = ExpenseModel(
        uuid: 'no-rates',
        value: 50.0,
        description: 'Offline expense',
        createdOn: testDate,
        userId: 'user-123',
        currency: ExpenseCurrency.euro,
        exchangeRates: {}, // VUOTO - situazione offline
      );

      // ACT
      final converted = expenseNoRates.getValueIn(ExpenseCurrency.usd);

      // ASSERT
      // Senza tassi, ritorna il valore originale (failsafe)
      expect(converted, 50.0);
    });

    // =================================================================
    // TEST 13: Protezione divisione per zero
    // =================================================================
    test('Should handle zero exchange rate safely to prevent division by zero', () {
      // ARRANGE
      final expense = ExpenseModel(
        uuid: 'incomplete-rates',
        value: 100.0,
        description: 'Incomplete rates',
        createdOn: testDate,
        userId: 'user-123',
        currency: ExpenseCurrency.euro,
        exchangeRates: {'USD': 0.0, 'EUR': 1.0}, // tasso sorgente corrotto
      );

      // ACT
      final converted = expense.getValueIn(ExpenseCurrency.usd);

      // ASSERT
      // Il metodo deve gestire la valuta mancante senza crashare
      // Fallback: ritorna valore originale
      expect(converted, 100.0);
    });

    // =================================================================
    // TEST 14: Serializzazione round-trip (toMap -> fromMap)
    // =================================================================
    test('Should maintain data integrity through serialization cycle', () {
      // ARRANGE
      final original = sampleExpense;

      // ACT
      final reconstructed = ExpenseModel.fromMap(original.toMap());

      // ASSERT
      // L'oggetto ricostruito deve essere identico all'originale
      expect(reconstructed.uuid, original.uuid);
      expect(reconstructed.value, original.value);
      expect(reconstructed.description, original.description);
      expect(reconstructed.createdOn, original.createdOn);
      expect(reconstructed.userId, original.userId);
      expect(reconstructed.currency, original.currency);
      expect(reconstructed.exchangeRates, original.exchangeRates);
      expect(reconstructed.category, original.category);
    });

    // =================================================================
    // TEST 15: Round-trip per ogni categoria (tutte le varianti)
    // =================================================================
    test('Should correctly serialize and deserialize all category values', () {
      // ARRANGE + ACT + ASSERT in loop
      // Verifichiamo che ogni variante dell'enum sopravviva al ciclo toMap -> fromMap
      for (final cat in ExpenseCategory.values) {
        final expense = ExpenseModel(
          uuid: 'cat-test',
          value: 1.0,
          description: null,
          createdOn: testDate,
          userId: 'user-123',
          currency: ExpenseCurrency.euro,
          exchangeRates: {},
          category: cat,
        );

        final reconstructed = ExpenseModel.fromMap(expense.toMap());
        expect(
          reconstructed.category,
          cat,
          reason: 'Failed round-trip for category: ${cat.name}',
        );
      }
    });
  });
}
