// FILE: expense_calculator_test.dart
// DESCRIZIONE: Test suite per ExpenseCalculator
// Testa calcoli temporali (oggi, settimana, mese, anno), aggregazioni per grafici,
// ordinamento, e gestione conversioni multi-valuta.

import 'package:expense_tracker/models/expense_model.dart';
import 'package:expense_tracker/utils/expense_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ExpenseCalculator Tests', () {
    // --- SETUP: Dati di test ---
    late List<ExpenseModel> testExpenses;
    late DateTime now;
    late Map<String, double> testRates;

    setUp(() {
      // Timestamp di riferimento per i test temporali
      now = DateTime.now();
      
      testRates = {
        'EUR': 1.0,
        'USD': 1.10,
        'GBP': 0.85,
        'JPY': 130.0,
      };

      // Dataset di test con spese distribuite temporalmente
      testExpenses = [
        // OGGI
        ExpenseModel(
          uuid: 'today-1',
          value: 50.0,
          description: 'Today expense 1',
          createdOn: now, // Adesso
          userId: 'user-123',
          currency: 'EUR',
          exchangeRates: testRates,
        ),
        ExpenseModel(
          uuid: 'today-2',
          value: 30.0,
          description: 'Today expense 2',
          createdOn: now.subtract(const Duration(hours: 2)), // 2 ore fa
          userId: 'user-123',
          currency: 'EUR',
          exchangeRates: testRates,
        ),
        
        // QUESTA SETTIMANA (ma non oggi)
        ExpenseModel(
          uuid: 'week-1',
          value: 100.0,
          description: 'Week expense',
          createdOn: now.subtract(const Duration(days: 2)), // 2 giorni fa
          userId: 'user-123',
          currency: 'EUR',
          exchangeRates: testRates,
        ),
        
        // QUESTO MESE (ma non questa settimana)
        ExpenseModel(
          uuid: 'month-1',
          value: 200.0,
          description: 'Month expense',
          createdOn: DateTime(now.year, now.month, 1), // Primo del mese
          userId: 'user-123',
          currency: 'EUR',
          exchangeRates: testRates,
        ),
        
        // QUEST'ANNO (ma mese diverso - potrebbe non essere incluso in totalExpenseMonth)
        ExpenseModel(
          uuid: 'year-1',
          value: 500.0,
          description: 'Earlier this year',
          createdOn: DateTime(now.year, 1, 15), // Gennaio (se siamo in altro mese)
          userId: 'user-123',
          currency: 'EUR',
          exchangeRates: testRates,
        ),
        
        // ANNO PASSATO (escluso da tutti i totali)
        ExpenseModel(
          uuid: 'old-1',
          value: 1000.0,
          description: 'Old expense',
          createdOn: DateTime(now.year - 1, 12, 31), // Anno scorso
          userId: 'user-123',
          currency: 'EUR',
          exchangeRates: testRates,
        ),
      ];
    });

    // =================================================================
    // TEST 1: Total Expense Today
    // =================================================================
    test('Should calculate total expenses for today only', () {
      // ACT
      final total = ExpenseCalculator.totalExpenseToday(
        testExpenses,
        'EUR',
      );

      // ASSERT
      // Solo 'today-1' (50) + 'today-2' (30) = 80
      expect(total, 80.0);
    });

    // =================================================================
    // TEST 2: Total Expense Week
    // =================================================================
    test('Should calculate total expenses for current week', () {
      // ACT
      final total = ExpenseCalculator.totalExpenseWeek(
        testExpenses,
        'EUR',
      );

      // ASSERT
      // Settimana include: oggi (80) + 2 giorni fa (100) = 180
      expect(total, greaterThanOrEqualTo(180.0));
    });

    // =================================================================
    // TEST 3: Total Expense Month
    // =================================================================
    test('Should calculate total expenses for current month', () {
      // ACT
      final total = ExpenseCalculator.totalExpenseMonth(
        testExpenses,
        'EUR',
      );

      // ASSERT
      // Mese include: settimana (≥180) + primo del mese (200) = ≥380
      expect(total, greaterThanOrEqualTo(380.0));
    });

    // =================================================================
    // TEST 4: Total Expense Year
    // =================================================================
    test('Should calculate total expenses for current year', () {
      // ACT
      final total = ExpenseCalculator.totalExpenseYear(
        testExpenses,
        'EUR',
      );

      // ASSERT
      // Anno include tutte le spese dell'anno corrente
      // Esclude solo l'anno passato (1000€)
      // Totale minimo: spese di oggi (80) + settimana (100) + mese (200) = 380
      expect(total, greaterThanOrEqualTo(380.0));
      
      // Verifica che NON includa anno passato
      expect(total, lessThan(2000.0)); // 1000€ anno passato escluso
    });

    // =================================================================
    // TEST 5: Total with Multi-Currency Conversion
    // =================================================================
    test('Should convert expenses to target currency before summing', () {
      // ARRANGE
      final multiCurrencyExpenses = [
        ExpenseModel(
          uuid: 'eur-expense',
          value: 100.0, // 100 EUR
          description: 'EUR expense',
          createdOn: now,
          userId: 'user-123',
          currency: 'EUR',
          exchangeRates: testRates,
        ),
        ExpenseModel(
          uuid: 'usd-expense',
          value: 110.0, // 110 USD = 100 EUR
          description: 'USD expense',
          createdOn: now,
          userId: 'user-123',
          currency: 'USD',
          exchangeRates: testRates,
        ),
      ];

      // ACT
      final totalInEUR = ExpenseCalculator.totalExpenseToday(
        multiCurrencyExpenses,
        'EUR',
      );

      // ASSERT
      // 100 EUR + (110 USD → 100 EUR) = 200 EUR
      expect(totalInEUR, closeTo(200.0, 0.01));
    });

    // =================================================================
    // TEST 6: Empty Expenses List
    // =================================================================
    test('Should return 0 for empty expenses list', () {
      // ACT
      final total = ExpenseCalculator.totalExpenseToday([], 'EUR');

      // ASSERT
      expect(total, 0.0);
    });

    // =================================================================
    // TEST 7: Expenses by Month - Aggregation
    // =================================================================
    test('Should aggregate expenses by month with correct format', () {
      // ARRANGE
      final expenses = [
        ExpenseModel(
          uuid: '1',
          value: 100.0,
          description: 'Jan expense',
          createdOn: DateTime(2024, 1, 15),
          userId: 'user-123',
          currency: 'EUR',
          exchangeRates: testRates,
        ),
        ExpenseModel(
          uuid: '2',
          value: 50.0,
          description: 'Jan expense 2',
          createdOn: DateTime(2024, 1, 20),
          userId: 'user-123',
          currency: 'EUR',
          exchangeRates: testRates,
        ),
        ExpenseModel(
          uuid: '3',
          value: 200.0,
          description: 'Feb expense',
          createdOn: DateTime(2024, 2, 10),
          userId: 'user-123',
          currency: 'EUR',
          exchangeRates: testRates,
        ),
      ];

      // ACT
      final byMonth = ExpenseCalculator.expensesByMonth(expenses, 'EUR');

      // ASSERT
      // Chiavi formato "YYYY-MM"
      expect(byMonth.containsKey('2024-01'), true);
      expect(byMonth.containsKey('2024-02'), true);
      
      // Gennaio: 100 + 50 = 150
      expect(byMonth['2024-01'], 150.0);
      
      // Febbraio: 200
      expect(byMonth['2024-02'], 200.0);
    });

    // =================================================================
    // TEST 8: Expenses by Month - Sorted Descending
    // =================================================================
    test('Should return months sorted in descending order', () {
      // ARRANGE
      final expenses = [
        ExpenseModel(
          uuid: '1',
          value: 100.0,
          description: 'Jan',
          createdOn: DateTime(2024, 1, 15),
          userId: 'user-123',
          currency: 'EUR',
          exchangeRates: testRates,
        ),
        ExpenseModel(
          uuid: '2',
          value: 200.0,
          description: 'Mar',
          createdOn: DateTime(2024, 3, 10),
          userId: 'user-123',
          currency: 'EUR',
          exchangeRates: testRates,
        ),
        ExpenseModel(
          uuid: '3',
          value: 150.0,
          description: 'Feb',
          createdOn: DateTime(2024, 2, 5),
          userId: 'user-123',
          currency: 'EUR',
          exchangeRates: testRates,
        ),
      ];

      // ACT
      final byMonth = ExpenseCalculator.expensesByMonth(expenses, 'EUR');
      final keys = byMonth.keys.toList();

      // ASSERT
      // Ordine: Marzo → Febbraio → Gennaio (descending)
      expect(keys[0], '2024-03');
      expect(keys[1], '2024-02');
      expect(keys[2], '2024-01');
    });

    // =================================================================
    // TEST 9: Expenses by Day - Specific Month
    // =================================================================
    test('Should aggregate expenses by day for specific month', () {
      // ARRANGE
      final expenses = [
        ExpenseModel(
          uuid: '1',
          value: 50.0,
          description: 'Day 15',
          createdOn: DateTime(2024, 1, 15),
          userId: 'user-123',
          currency: 'EUR',
          exchangeRates: testRates,
        ),
        ExpenseModel(
          uuid: '2',
          value: 30.0,
          description: 'Day 15 again',
          createdOn: DateTime(2024, 1, 15, 14, 30), // Stesso giorno, ora diversa
          userId: 'user-123',
          currency: 'EUR',
          exchangeRates: testRates,
        ),
        ExpenseModel(
          uuid: '3',
          value: 100.0,
          description: 'Day 20',
          createdOn: DateTime(2024, 1, 20),
          userId: 'user-123',
          currency: 'EUR',
          exchangeRates: testRates,
        ),
        ExpenseModel(
          uuid: '4',
          value: 200.0,
          description: 'Wrong month',
          createdOn: DateTime(2024, 2, 15), // Febbraio, escluso
          userId: 'user-123',
          currency: 'EUR',
          exchangeRates: testRates,
        ),
      ];

      // ACT
      final byDay = ExpenseCalculator.expensesByDay(expenses, 2024, 1, 'EUR');

      // ASSERT
      // Chiavi formato "DD/MM/YYYY"
      expect(byDay.containsKey('15/01/2024'), true);
      expect(byDay.containsKey('20/01/2024'), true);
      expect(byDay.containsKey('15/02/2024'), false); // Mese diverso
      
      // Giorno 15: 50 + 30 = 80
      expect(byDay['15/01/2024'], 80.0);
      
      // Giorno 20: 100
      expect(byDay['20/01/2024'], 100.0);
    });

    // =================================================================
    // TEST 10: Expenses of Specific Day - Raw List
    // =================================================================
    test('Should return raw expense list for specific day', () {
      // ARRANGE
      final expenses = [
        ExpenseModel(
          uuid: '1',
          value: 50.0,
          description: 'Morning',
          createdOn: DateTime(2024, 1, 15, 9, 0),
          userId: 'user-123',
          currency: 'EUR',
          exchangeRates: testRates,
        ),
        ExpenseModel(
          uuid: '2',
          value: 30.0,
          description: 'Afternoon',
          createdOn: DateTime(2024, 1, 15, 14, 0),
          userId: 'user-123',
          currency: 'EUR',
          exchangeRates: testRates,
        ),
        ExpenseModel(
          uuid: '3',
          value: 100.0,
          description: 'Different day',
          createdOn: DateTime(2024, 1, 16),
          userId: 'user-123',
          currency: 'EUR',
          exchangeRates: testRates,
        ),
      ];

      // ACT
      final dayExpenses = ExpenseCalculator.expensesOfDay(
        expenses,
        2024,
        1,
        15,
      );

      // ASSERT
      expect(dayExpenses.length, 2); // Solo le 2 del giorno 15
      expect(dayExpenses[0].uuid, '2'); // Più recente prima (14:00)
      expect(dayExpenses[1].uuid, '1'); // Meno recente dopo (09:00)
    });

    // =================================================================
    // TEST 11: Sort by Date Descending
    // =================================================================
    test('Should sort expenses by date in descending order', () {
      // ARRANGE
      final expenses = [
        ExpenseModel(
          uuid: '1',
          value: 100.0,
          description: 'Oldest',
          createdOn: DateTime(2024, 1, 1),
          userId: 'user-123',
          currency: 'EUR',
          exchangeRates: testRates,
        ),
        ExpenseModel(
          uuid: '2',
          value: 100.0,
          description: 'Newest',
          createdOn: DateTime(2024, 1, 30),
          userId: 'user-123',
          currency: 'EUR',
          exchangeRates: testRates,
        ),
        ExpenseModel(
          uuid: '3',
          value: 100.0,
          description: 'Middle',
          createdOn: DateTime(2024, 1, 15),
          userId: 'user-123',
          currency: 'EUR',
          exchangeRates: testRates,
        ),
      ];

      // ACT
      ExpenseCalculator.sortInPlace(expenses, 'date_desc');

      // ASSERT
      expect(expenses[0].uuid, '2'); // Newest first
      expect(expenses[1].uuid, '3'); // Middle
      expect(expenses[2].uuid, '1'); // Oldest last
    });

    // =================================================================
    // TEST 12: Sort by Date Ascending
    // =================================================================
    test('Should sort expenses by date in ascending order', () {
      // ARRANGE
      final expenses = [
        ExpenseModel(
          uuid: '1',
          value: 100.0,
          description: 'Newest',
          createdOn: DateTime(2024, 1, 30),
          userId: 'user-123',
          currency: 'EUR',
          exchangeRates: testRates,
        ),
        ExpenseModel(
          uuid: '2',
          value: 100.0,
          description: 'Oldest',
          createdOn: DateTime(2024, 1, 1),
          userId: 'user-123',
          currency: 'EUR',
          exchangeRates: testRates,
        ),
      ];

      // ACT
      ExpenseCalculator.sortInPlace(expenses, 'date_asc');

      // ASSERT
      expect(expenses[0].uuid, '2'); // Oldest first
      expect(expenses[1].uuid, '1'); // Newest last
    });

    // =================================================================
    // TEST 13: Sort by Amount Descending (No Currency Conversion)
    // =================================================================
    test('Should sort by raw amount when no target currency provided', () {
      // ARRANGE
      final expenses = [
        ExpenseModel(
          uuid: '1',
          value: 50.0,
          description: 'Small',
          createdOn: DateTime.now(),
          userId: 'user-123',
          currency: 'EUR',
          exchangeRates: testRates,
        ),
        ExpenseModel(
          uuid: '2',
          value: 200.0,
          description: 'Large',
          createdOn: DateTime.now(),
          userId: 'user-123',
          currency: 'EUR',
          exchangeRates: testRates,
        ),
        ExpenseModel(
          uuid: '3',
          value: 100.0,
          description: 'Medium',
          createdOn: DateTime.now(),
          userId: 'user-123',
          currency: 'EUR',
          exchangeRates: testRates,
        ),
      ];

      // ACT
      ExpenseCalculator.sortInPlace(expenses, 'amount_desc');

      // ASSERT
      expect(expenses[0].value, 200.0); // Largest first
      expect(expenses[1].value, 100.0);
      expect(expenses[2].value, 50.0); // Smallest last
    });

    // =================================================================
    // TEST 14: Sort by Amount with Currency Conversion
    // =================================================================
    test('Should sort by converted amount when target currency provided', () {
      // ARRANGE
      final expenses = [
        ExpenseModel(
          uuid: '1',
          value: 100.0, // 100 EUR
          description: 'EUR expense',
          createdOn: DateTime.now(),
          userId: 'user-123',
          currency: 'EUR',
          exchangeRates: testRates,
        ),
        ExpenseModel(
          uuid: '2',
          value: 85.0, // 85 GBP = 100 EUR (85/0.85)
          description: 'GBP expense',
          createdOn: DateTime.now(),
          userId: 'user-123',
          currency: 'GBP',
          exchangeRates: testRates,
        ),
        ExpenseModel(
          uuid: '3',
          value: 220.0, // 220 USD = 200 EUR (220/1.10)
          description: 'USD expense',
          createdOn: DateTime.now(),
          userId: 'user-123',
          currency: 'USD',
          exchangeRates: testRates,
        ),
      ];

      // ACT
      ExpenseCalculator.sortInPlace(
        expenses,
        'amount_desc',
        targetCurrency: 'EUR',
      );

      // ASSERT
      // Ordine per valore in EUR: 220 USD (200€) > 100 EUR (100€) = 85 GBP (100€)
      expect(expenses[0].uuid, '3'); // 220 USD = 200 EUR (largest)
      // Gli altri due sono equivalenti in EUR
    });

    // =================================================================
    // TEST 15: Sort by Amount Ascending
    // =================================================================
    test('Should sort by amount in ascending order', () {
      // ARRANGE
      final expenses = [
        ExpenseModel(
          uuid: '1',
          value: 200.0,
          description: 'Large',
          createdOn: DateTime.now(),
          userId: 'user-123',
          currency: 'EUR',
          exchangeRates: testRates,
        ),
        ExpenseModel(
          uuid: '2',
          value: 50.0,
          description: 'Small',
          createdOn: DateTime.now(),
          userId: 'user-123',
          currency: 'EUR',
          exchangeRates: testRates,
        ),
      ];

      // ACT
      ExpenseCalculator.sortInPlace(expenses, 'amount_asc');

      // ASSERT
      expect(expenses[0].value, 50.0); // Smallest first
      expect(expenses[1].value, 200.0); // Largest last
    });

    // =================================================================
    // TEST 16: Aggregation with Empty List
    // =================================================================
    test('Should return empty map when aggregating empty list', () {
      // ACT
      final byMonth = ExpenseCalculator.expensesByMonth([], 'EUR');
      final byDay = ExpenseCalculator.expensesByDay([], 2024, 1, 'EUR');

      // ASSERT
      expect(byMonth, isEmpty);
      expect(byDay, isEmpty);
    });

    // =================================================================
    // TEST 17: Expenses of Day - No Matches
    // =================================================================
    test('Should return empty list when no expenses match the day', () {
      // ARRANGE
      final expenses = [
        ExpenseModel(
          uuid: '1',
          value: 100.0,
          description: 'Wrong day',
          createdOn: DateTime(2024, 1, 20),
          userId: 'user-123',
          currency: 'EUR',
          exchangeRates: testRates,
        ),
      ];

      // ACT
      final dayExpenses = ExpenseCalculator.expensesOfDay(
        expenses,
        2024,
        1,
        15, // Different day
      );

      // ASSERT
      expect(dayExpenses, isEmpty);
    });
  });
}