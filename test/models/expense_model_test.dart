// FILE: expense_model_test.dart
// DESCRIZIONE: Test suite per ExpenseModel
// Testa serializzazione, deserializzazione, copyWith e logica di conversione valuta

import 'package:expense_tracker/models/expense_currency.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:expense_tracker/models/expense_model.dart';
import 'package:expense_tracker/models/expense_category.dart';

void main() {
  group('ExpenseModel Tests', () {

    // --- SETUP: Dati di test riutilizzabili ---
    late ExpenseModel sampleExpense;
    late DateTime testDate;
    late Map<String, double> testRates;

    setUp(() {
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
        currency: ExpenseCurrency.euro,
        exchangeRates: testRates,
        category: ExpenseCategory.food, // Categoria esplicita nel campione base
      );
    });

    // =================================================================
    // TEST 1: Creazione base del modello
    // =================================================================
    test('Should create ExpenseModel with all required fields', () {
      final expense = sampleExpense;

      expect(expense.uuid, 'test-uuid-123');
      expect(expense.value, 100.0);
      expect(expense.description, 'Test expense');
      expect(expense.createdOn, testDate);
      expect(expense.userId, 'user-123');
      expect(expense.currency, ExpenseCurrency.euro);
      expect(expense.exchangeRates, testRates);
      expect(expense.category, ExpenseCategory.food); // NUOVO
    });

    // =================================================================
    // TEST 2: Categoria default (other) quando non specificata
    // =================================================================
    test('Should default category to other when not provided', () {
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

      expect(expense.category, ExpenseCategory.other);
    });

    // =================================================================
    // TEST 3: Serializzazione (toMap - da oggetto a database)
    // =================================================================
    test('Should correctly serialize to Map for database storage', () {
      final map = sampleExpense.toMap();

      expect(map['uuid'], 'test-uuid-123');
      expect(map['value'], 100.0);
      expect(map['description'], 'Test expense');
      expect(map['createdOn'], testDate.millisecondsSinceEpoch);
      expect(map['userId'], 'user-123');
      expect(map['currency'], 'EUR');
      expect(map['exchangeRates'], testRates);
      expect(map['category'], 'food'); // NUOVO: salvata come stringa leggibile
    });

    // =================================================================
    // TEST 4: Deserializzazione (fromMap - da database a oggetto)
    // =================================================================
    test('Should correctly deserialize from Map retrieved from database', () {
      final mapData = {
        'uuid': 'test-uuid-456',
        'value': 50.5,
        'description': 'Grocery shopping',
        'createdOn': testDate.millisecondsSinceEpoch,
        'userId': 'user-456',
        'currency': 'USD',
        'exchangeRates': {'EUR': 1.0, 'USD': 1.10},
        'category': 'shopping', // NUOVO
      };

      final expense = ExpenseModel.fromMap(mapData);

      expect(expense.uuid, 'test-uuid-456');
      expect(expense.value, 50.5);
      expect(expense.description, 'Grocery shopping');
      expect(expense.createdOn, testDate);
      expect(expense.userId, 'user-456');
      expect(expense.currency, ExpenseCurrency.usd);
      expect(expense.exchangeRates['EUR'], 1.0);
      expect(expense.exchangeRates['USD'], 1.10);
      expect(expense.category, ExpenseCategory.shopping); // NUOVO
    });

    // =================================================================
    // TEST 5: Retrocompatibilità (vecchie spese senza currency e senza category)
    // =================================================================
    test('Should handle legacy expenses without currency and category fields', () {
      final legacyMap = {
        'uuid': 'legacy-123',
        'value': 75.0,
        'description': 'Old expense',
        'createdOn': testDate.millisecondsSinceEpoch,
        'userId': 'user-789',
        // Niente 'currency', 'exchangeRates', né 'category'
      };

      final expense = ExpenseModel.fromMap(legacyMap);

      expect(expense.currency, ExpenseCurrency.euro);           // fallback valuta
      expect(expense.exchangeRates, isEmpty);
      expect(expense.category, ExpenseCategory.other); // NUOVO: fallback categoria
    });

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
        'category': 'nonexistent_category', // Valore non valido
      };

      final expense = ExpenseModel.fromMap(mapData);

      expect(expense.category, ExpenseCategory.other);
    });

    // =================================================================
    // TEST 7: copyWith - Immutabilità e clonazione parziale (campi esistenti)
    // =================================================================
    test('Should create modified copy with copyWith while preserving original', () {
      final original = sampleExpense;

      final modified = original.copyWith(
        value: 200.0,
        description: 'Modified description',
      );

      expect(modified.value, 200.0);
      expect(modified.description, 'Modified description');
      expect(modified.uuid, original.uuid);
      expect(modified.currency, original.currency);
      expect(modified.category, original.category); // categoria preservata

      // Originale invariato
      expect(original.value, 100.0);
      expect(original.description, 'Test expense');
    });

    // =================================================================
    // TEST 8: copyWith - Modifica della categoria
    // =================================================================
    test('Should correctly update category via copyWith', () {
      final original = sampleExpense; // category: food

      final modified = original.copyWith(category: ExpenseCategory.travel);

      expect(modified.category, ExpenseCategory.travel);
      expect(original.category, ExpenseCategory.food); // originale invariato
      // Gli altri campi sono preservati
      expect(modified.uuid, original.uuid);
      expect(modified.value, original.value);
    });

    // =================================================================
    // TEST 9: Conversione valuta - Stessa valuta
    // =================================================================
    test('Should return original value when converting to same currency', () {
      final converted = sampleExpense.getValueIn(ExpenseCurrency.euro);
      expect(converted, 100.0);
    });

    // =================================================================
    // TEST 10: Conversione valuta - EUR to USD
    // =================================================================
    test('Should correctly convert EUR to USD using exchange rates', () {
      // Formula: (100 / 1.0) * 1.10 = 110.0
      final converted = sampleExpense.getValueIn(ExpenseCurrency.usd);
      expect(converted, closeTo(110.0, 0.01));
    });

    // =================================================================
    // TEST 11: Conversione valuta - USD to GBP
    // =================================================================
    test('Should correctly convert between non-base currencies', () {
      final expenseInUSD = ExpenseModel(
        uuid: 'usd-expense',
        value: 110.0,
        description: 'USD expense',
        createdOn: testDate,
        userId: 'user-123',
        currency: ExpenseCurrency.usd,
        exchangeRates: testRates,
      );

      // Formula: (110 / 1.10) * 0.85 = 85.0
      final convertedToGBP = expenseInUSD.getValueIn(ExpenseCurrency.gbp);
      expect(convertedToGBP, closeTo(85.0, 0.01));
    });

    // =================================================================
    // TEST 12: Fallback quando mancano i tassi di cambio
    // =================================================================
    test('Should return original value when exchange rates are empty', () {
      final expenseNoRates = ExpenseModel(
        uuid: 'no-rates',
        value: 50.0,
        description: 'Offline expense',
        createdOn: testDate,
        userId: 'user-123',
        currency: ExpenseCurrency.euro,
        exchangeRates: {},
      );

      expect(expenseNoRates.getValueIn(ExpenseCurrency.usd), 50.0);
    });

    // =================================================================
    // TEST 13: Protezione divisione per zero
    // =================================================================
    test('Should handle missing currency in exchange rates map safely', () {
      final expense = ExpenseModel(
        uuid: 'incomplete-rates',
        value: 100.0,
        description: 'Incomplete rates',
        createdOn: testDate,
        userId: 'user-123',
        currency: ExpenseCurrency.euro,
        exchangeRates: {'EUR': 1.0}, // USD mancante
      );

      expect(expense.getValueIn(ExpenseCurrency.usd), 100.0);
    });

    // =================================================================
    // TEST 14: Serializzazione round-trip (toMap -> fromMap)
    // =================================================================
    test('Should maintain data integrity through serialization cycle', () {
      final original = sampleExpense;

      final reconstructed = ExpenseModel.fromMap(original.toMap());

      expect(reconstructed.uuid, original.uuid);
      expect(reconstructed.value, original.value);
      expect(reconstructed.description, original.description);
      expect(reconstructed.createdOn, original.createdOn);
      expect(reconstructed.userId, original.userId);
      expect(reconstructed.currency, original.currency);
      expect(reconstructed.exchangeRates, original.exchangeRates);
      expect(reconstructed.category, original.category); // NUOVO
    });

    // =================================================================
    // TEST 15: Round-trip per ogni categoria (tutte le varianti)
    // =================================================================
    test('Should correctly serialize and deserialize all category values', () {
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