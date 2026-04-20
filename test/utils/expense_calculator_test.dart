// FILE: expense_calculator_test.dart
// DESCRIZIONE: Test suite per ExpenseCalculator
// Testa calcoli temporali (oggi, settimana, mese, anno), aggregazioni per grafici,
// ordinamento, e gestione conversioni multi-valuta.

import 'package:expense_tracker/models/expense_category.dart';
import 'package:expense_tracker/models/expense_currency.dart';
import 'package:expense_tracker/models/expense_model.dart';
import 'package:expense_tracker/utils/expense_calculator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ExpenseCalculator Tests', () {
    // --- SETUP: Dati di test ---
    late DateTime now;
    late Map<String, double> testRates;

    setUp(() {
      // now e testRates sono condivisi tra tutti i test.
      // I test 1-4 usano dataset dedicati per evitare ambiguità
      // sui confini temporali (settimana/mese/anno).
      // I test 5-26 costruiscono i propri dataset inline.
      now = DateTime.now();
      testRates = {'EUR': 1.0, 'USD': 1.10, 'GBP': 0.85, 'JPY': 130.0};
    });

    // =================================================================
    // TEST 1: Total Expense Today
    // =================================================================
    test('Should calculate total expenses for today only', () {
      // ARRANGE
      final expenses = [
        ExpenseModel(
          uuid: 'today-1',
          value: 50.0,
          description: null,
          createdOn: now,
          userId: 'user-123',
          currency: ExpenseCurrency.euro,
          exchangeRates: testRates,
        ),
        ExpenseModel(
          uuid: 'today-2',
          value: 30.0,
          description: null,
          createdOn: now.subtract(const Duration(hours: 2)),
          userId: 'user-123',
          currency: ExpenseCurrency.euro,
          exchangeRates: testRates,
        ),
        ExpenseModel(
          uuid: 'old',
          value: 1000.0,
          description: null,
          createdOn: DateTime(now.year - 1, 6, 15),
          userId: 'user-123',
          currency: ExpenseCurrency.euro,
          exchangeRates: testRates,
        ),
      ];

      // ACT
      final total = ExpenseCalculator.totalExpenseToday(
        expenses,
        ExpenseCurrency.euro,
      );

      // ASSERT
      expect(total, 80.0);
    });

    // =================================================================
    // TEST 2: Total Expense Week
    // =================================================================
    test('Should calculate total expenses for current week', () {
      // ARRANGE
      final weekDate = now.weekday == 1
          ? now.subtract(const Duration(hours: 1))
          : now.subtract(const Duration(days: 1));
      final expenses = [
        ExpenseModel(
          uuid: 'today',
          value: 80.0,
          description: null,
          createdOn: now,
          userId: 'user-123',
          currency: ExpenseCurrency.euro,
          exchangeRates: testRates,
        ),
        ExpenseModel(
          uuid: 'week',
          value: 100.0,
          description: null,
          createdOn: weekDate,
          userId: 'user-123',
          currency: ExpenseCurrency.euro,
          exchangeRates: testRates,
        ),
        ExpenseModel(
          uuid: 'old',
          value: 1000.0,
          description: null,
          createdOn: DateTime(now.year - 1, 6, 15),
          userId: 'user-123',
          currency: ExpenseCurrency.euro,
          exchangeRates: testRates,
        ),
      ];

      // ACT
      final total = ExpenseCalculator.totalExpenseWeek(
        expenses,
        ExpenseCurrency.euro,
      );

      // ASSERT
      expect(total, 180.0);
    });

    // =================================================================
    // TEST 3: Total Expense Month
    // =================================================================
    test('Should calculate total expenses for current month', () {
      // ARRANGE
      final expenses = [
        ExpenseModel(
          uuid: 'today',
          value: 80.0,
          description: null,
          createdOn: now,
          userId: 'user-123',
          currency: ExpenseCurrency.euro,
          exchangeRates: testRates,
        ),
        ExpenseModel(
          uuid: 'month',
          value: 200.0,
          description: null,
          createdOn: DateTime(now.year, now.month, 1),
          userId: 'user-123',
          currency: ExpenseCurrency.euro,
          exchangeRates: testRates,
        ),
        ExpenseModel(
          uuid: 'old',
          value: 1000.0,
          description: null,
          createdOn: DateTime(now.year - 1, 6, 15),
          userId: 'user-123',
          currency: ExpenseCurrency.euro,
          exchangeRates: testRates,
        ),
      ];

      // ACT
      final total = ExpenseCalculator.totalExpenseMonth(
        expenses,
        ExpenseCurrency.euro,
      );

      // ASSERT
      expect(total, 280.0);
    });

    // =================================================================
    // TEST 4: Total Expense Year
    // =================================================================
    test('Should calculate total expenses for current year', () {
      // ARRANGE
      final differentMonth = now.month == 1 ? 2 : 1;
      final expenses = [
        ExpenseModel(
          uuid: 'today',
          value: 80.0,
          description: null,
          createdOn: now,
          userId: 'user-123',
          currency: ExpenseCurrency.euro,
          exchangeRates: testRates,
        ),
        ExpenseModel(
          uuid: 'year',
          value: 500.0,
          description: null,
          createdOn: DateTime(now.year, differentMonth, 15),
          userId: 'user-123',
          currency: ExpenseCurrency.euro,
          exchangeRates: testRates,
        ),
        ExpenseModel(
          uuid: 'old',
          value: 1000.0,
          description: null,
          createdOn: DateTime(now.year - 1, 6, 15),
          userId: 'user-123',
          currency: ExpenseCurrency.euro,
          exchangeRates: testRates,
        ),
      ];

      // ACT
      final total = ExpenseCalculator.totalExpenseYear(
        expenses,
        ExpenseCurrency.euro,
      );

      // ASSERT
      expect(total, 580.0);
    });

    // =================================================================
    // TEST 5: Total with Multi-Currency Conversion
    // =================================================================
    test('Should convert expenses to target currency before summing', () {
      // ARRANGE
      final multiCurrencyExpenses = [
        ExpenseModel(
          uuid: 'eur-expense',
          value: 100.0,
          description: 'EUR expense',
          createdOn: now,
          userId: 'user-123',
          currency: ExpenseCurrency.euro,
          exchangeRates: testRates,
        ),
        ExpenseModel(
          uuid: 'usd-expense',
          value: 110.0, // 110 USD = 100 EUR
          description: 'USD expense',
          createdOn: now,
          userId: 'user-123',
          currency: ExpenseCurrency.usd,
          exchangeRates: testRates,
        ),
      ];

      // ACT
      final totalInEUR = ExpenseCalculator.totalExpenseToday(
        multiCurrencyExpenses,
        ExpenseCurrency.euro,
      );

      // ASSERT
      // 100 EUR + (110 USD → 100 EUR) = 200 EUR
      expect(totalInEUR, closeTo(200.0, 0.01));
    });

    // =================================================================
    // TEST 6: Empty Expenses List
    // =================================================================
    test('Should return 0 for empty expenses list', () {
      // ARRANGE + ACT + ASSERT
      // Lista vuota: nessun calcolo da effettuare, risultato atteso = 0
      final total = ExpenseCalculator.totalExpenseToday(
        [],
        ExpenseCurrency.euro,
      );
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
          currency: ExpenseCurrency.euro,
          exchangeRates: testRates,
        ),
        ExpenseModel(
          uuid: '2',
          value: 50.0,
          description: 'Jan expense 2',
          createdOn: DateTime(2024, 1, 20),
          userId: 'user-123',
          currency: ExpenseCurrency.euro,
          exchangeRates: testRates,
        ),
        ExpenseModel(
          uuid: '3',
          value: 200.0,
          description: 'Feb expense',
          createdOn: DateTime(2024, 2, 10),
          userId: 'user-123',
          currency: ExpenseCurrency.euro,
          exchangeRates: testRates,
        ),
      ];

      // ACT
      final byMonth = ExpenseCalculator.expensesByMonth(
        expenses,
        ExpenseCurrency.euro,
      );

      // ASSERT
      expect(byMonth, {'2024-01': 150.0, '2024-02': 200.0});
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
          currency: ExpenseCurrency.euro,
          exchangeRates: testRates,
        ),
        ExpenseModel(
          uuid: '2',
          value: 200.0,
          description: 'Mar',
          createdOn: DateTime(2024, 3, 10),
          userId: 'user-123',
          currency: ExpenseCurrency.euro,
          exchangeRates: testRates,
        ),
        ExpenseModel(
          uuid: '3',
          value: 150.0,
          description: 'Feb',
          createdOn: DateTime(2024, 2, 5),
          userId: 'user-123',
          currency: ExpenseCurrency.euro,
          exchangeRates: testRates,
        ),
      ];

      // ACT
      final byMonth = ExpenseCalculator.expensesByMonth(
        expenses,
        ExpenseCurrency.euro,
      );
      final keys = byMonth.keys.toList();

      // ASSERT
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
          currency: ExpenseCurrency.euro,
          exchangeRates: testRates,
        ),
        ExpenseModel(
          uuid: '2',
          value: 30.0,
          description: 'Day 15 again',
          createdOn: DateTime(2024, 1, 15, 14, 30),
          userId: 'user-123',
          currency: ExpenseCurrency.euro,
          exchangeRates: testRates,
        ),
        ExpenseModel(
          uuid: '3',
          value: 100.0,
          description: 'Day 20',
          createdOn: DateTime(2024, 1, 20),
          userId: 'user-123',
          currency: ExpenseCurrency.euro,
          exchangeRates: testRates,
        ),
        ExpenseModel(
          uuid: '4',
          value: 200.0,
          description: 'Wrong month',
          createdOn: DateTime(2024, 2, 15),
          userId: 'user-123',
          currency: ExpenseCurrency.euro,
          exchangeRates: testRates,
        ),
      ];

      // ACT
      final byDay = ExpenseCalculator.expensesByDay(
        expenses,
        2024,
        1,
        ExpenseCurrency.euro,
      );

      // ASSERT
      expect(byDay, {'15/01/2024': 80.0, '20/01/2024': 100.0});
      expect(byDay.containsKey('15/02/2024'), false); // mese diverso escluso
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
          currency: ExpenseCurrency.euro,
          exchangeRates: testRates,
        ),
        ExpenseModel(
          uuid: '2',
          value: 30.0,
          description: 'Afternoon',
          createdOn: DateTime(2024, 1, 15, 14, 0),
          userId: 'user-123',
          currency: ExpenseCurrency.euro,
          exchangeRates: testRates,
        ),
        ExpenseModel(
          uuid: '3',
          value: 100.0,
          description: 'Different day',
          createdOn: DateTime(2024, 1, 16),
          userId: 'user-123',
          currency: ExpenseCurrency.euro,
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
      expect(dayExpenses.length, 2);
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
          currency: ExpenseCurrency.euro,
          exchangeRates: testRates,
        ),
        ExpenseModel(
          uuid: '2',
          value: 100.0,
          description: 'Newest',
          createdOn: DateTime(2024, 1, 30),
          userId: 'user-123',
          currency: ExpenseCurrency.euro,
          exchangeRates: testRates,
        ),
        ExpenseModel(
          uuid: '3',
          value: 100.0,
          description: 'Middle',
          createdOn: DateTime(2024, 1, 15),
          userId: 'user-123',
          currency: ExpenseCurrency.euro,
          exchangeRates: testRates,
        ),
      ];

      // ACT
      ExpenseCalculator.sortInPlace(expenses, 'date_desc');

      // ASSERT
      expect(expenses[0].uuid, '2');
      expect(expenses[1].uuid, '3');
      expect(expenses[2].uuid, '1');
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
          currency: ExpenseCurrency.euro,
          exchangeRates: testRates,
        ),
        ExpenseModel(
          uuid: '2',
          value: 100.0,
          description: 'Oldest',
          createdOn: DateTime(2024, 1, 1),
          userId: 'user-123',
          currency: ExpenseCurrency.euro,
          exchangeRates: testRates,
        ),
        ExpenseModel(
          uuid: '3',
          value: 100.0,
          description: 'Oldest',
          createdOn: DateTime(2024, 1, 23),
          userId: 'user-123',
          currency: ExpenseCurrency.euro,
          exchangeRates: testRates,
        ),
      ];

      // ACT
      ExpenseCalculator.sortInPlace(expenses, 'date_asc');

      // ASSERT
      expect(expenses[0].uuid, '2');
      expect(expenses[1].uuid, '3');
      expect(expenses[2].uuid, '1');
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
          currency: ExpenseCurrency.euro,
          exchangeRates: testRates,
        ),
        ExpenseModel(
          uuid: '2',
          value: 200.0,
          description: 'Large',
          createdOn: DateTime.now(),
          userId: 'user-123',
          currency: ExpenseCurrency.euro,
          exchangeRates: testRates,
        ),
        ExpenseModel(
          uuid: '3',
          value: 100.0,
          description: 'Medium',
          createdOn: DateTime.now(),
          userId: 'user-123',
          currency: ExpenseCurrency.euro,
          exchangeRates: testRates,
        ),
      ];

      // ACT
      ExpenseCalculator.sortInPlace(expenses, 'amount_desc');

      // ASSERT
      expect(expenses[0].uuid, '2'); // 200.0
      expect(expenses[1].uuid, '3'); // 100.0
      expect(expenses[2].uuid, '1'); // 50.0
    });

    // =================================================================
    // TEST 14: Sort by Amount with Currency Conversion
    // =================================================================
    test('Should sort by converted amount when target currency provided', () {
      // ARRANGE
      final expenses = [
        ExpenseModel(
          uuid: '1',
          value: 100.0,
          description: 'EUR expense',
          createdOn: DateTime.now(),
          userId: 'user-123',
          currency: ExpenseCurrency.euro,
          exchangeRates: testRates,
        ),
        ExpenseModel(
          uuid: '2',
          value: 85.0, // 85 GBP = 100 EUR
          description: 'GBP expense',
          createdOn: DateTime.now(),
          userId: 'user-123',
          currency: ExpenseCurrency.gbp,
          exchangeRates: testRates,
        ),
        ExpenseModel(
          uuid: '3',
          value: 220.0, // 220 USD = 200 EUR
          description: 'USD expense',
          createdOn: DateTime.now(),
          userId: 'user-123',
          currency: ExpenseCurrency.usd,
          exchangeRates: testRates,
        ),
      ];

      // ACT
      ExpenseCalculator.sortInPlace(
        expenses,
        'amount_desc',
        targetCurrency: ExpenseCurrency.euro,
      );

      // ASSERT
      expect(expenses[0].uuid, '3'); // 220 USD = 200 EUR
      expect(expenses[1].uuid, '1'); // 100 EUR
      expect(expenses[2].uuid, '2'); // 85 GBP = 100 EUR
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
          currency: ExpenseCurrency.euro,
          exchangeRates: testRates,
        ),
        ExpenseModel(
          uuid: '2',
          value: 50.0,
          description: 'Small',
          createdOn: DateTime.now(),
          userId: 'user-123',
          currency: ExpenseCurrency.euro,
          exchangeRates: testRates,
        ),
      ];

      // ACT
      ExpenseCalculator.sortInPlace(expenses, 'amount_asc');

      // ASSERT
      expect(expenses[0].uuid, '2'); // 50.0
      expect(expenses[1].uuid, '1'); // 200.0
    });

    // =================================================================
    // TEST 16: Aggregation with Empty List
    // =================================================================
    test('Should return empty map when aggregating empty list', () {
      // ARRANGE + ACT + ASSERT
      // Lista vuota: nessuna aggregazione possibile, mappe attese vuote
      final byMonth = ExpenseCalculator.expensesByMonth(
        [],
        ExpenseCurrency.euro,
      );
      final byDay = ExpenseCalculator.expensesByDay(
        [],
        2024,
        1,
        ExpenseCurrency.euro,
      );

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
          currency: ExpenseCurrency.euro,
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
      expect(dayExpenses, isEmpty);
    });

    // =================================================================
    // TEST 18: Sort by Amount Ascending with Currency Conversion
    // =================================================================
    test(
      'Should sort by converted amount in ascending order when target currency provided',
      () {
        // ARRANGE
        final expenses = [
          ExpenseModel(
            uuid: '1',
            value: 220.0, // 220 USD = 200 EUR (largest)
            description: 'USD expense',
            createdOn: DateTime.now(),
            userId: 'user-123',
            currency: ExpenseCurrency.usd,
            exchangeRates: testRates,
          ),
          ExpenseModel(
            uuid: '2',
            value: 85.0, // 85 GBP = 100 EUR (medium)
            description: 'GBP expense',
            createdOn: DateTime.now(),
            userId: 'user-123',
            currency: ExpenseCurrency.gbp,
            exchangeRates: testRates,
          ),
          ExpenseModel(
            uuid: '3',
            value: 50.0, // 50 EUR (smallest)
            description: 'EUR expense',
            createdOn: DateTime.now(),
            userId: 'user-123',
            currency: ExpenseCurrency.euro,
            exchangeRates: testRates,
          ),
        ];

        // ACT
        ExpenseCalculator.sortInPlace(
          expenses,
          'amount_asc',
          targetCurrency: ExpenseCurrency.euro,
        );

        // ASSERT
        expect(expenses[0].uuid, '3'); // 50 EUR (smallest)
        expect(expenses[1].uuid, '2'); // 85 GBP = 100 EUR (medium)
        expect(expenses[2].uuid, '1'); // 220 USD = 200 EUR (largest)
      },
    );

    // =================================================================
    // TEST 19: Expenses by Category For Year - Aggregazione base
    // =================================================================
    test('Should aggregate expenses by category for a specific year', () {
      // ARRANGE
      final expenses = [
        ExpenseModel(
          uuid: '1',
          value: 100.0,
          description: 'Food Jan',
          createdOn: DateTime(2024, 1, 15),
          userId: 'user-123',
          currency: ExpenseCurrency.euro,
          exchangeRates: testRates,
          category: ExpenseCategory.food,
        ),
        ExpenseModel(
          uuid: '2',
          value: 50.0,
          description: 'Food Mar',
          createdOn: DateTime(2024, 3, 10),
          userId: 'user-123',
          currency: ExpenseCurrency.euro,
          exchangeRates: testRates,
          category: ExpenseCategory.food,
        ),
        ExpenseModel(
          uuid: '3',
          value: 200.0,
          description: 'Transport',
          createdOn: DateTime(2024, 2, 5),
          userId: 'user-123',
          currency: ExpenseCurrency.euro,
          exchangeRates: testRates,
          category: ExpenseCategory.transport,
        ),
      ];

      // ACT
      final byCategory = ExpenseCalculator.expensesByCategoryForYear(
        expenses,
        '2024',
        ExpenseCurrency.euro,
      );

      // ASSERT
      expect(byCategory, {
        ExpenseCategory.food: 150.0,
        ExpenseCategory.transport: 200.0,
      });
    });

    // =================================================================
    // TEST 20: Expenses by Category For Year - Filtro anno corretto
    // =================================================================
    test('Should exclude expenses from other years', () {
      // ARRANGE
      final expenses = [
        ExpenseModel(
          uuid: '1',
          value: 100.0,
          description: 'Food 2024',
          createdOn: DateTime(2024, 6, 1),
          userId: 'user-123',
          currency: ExpenseCurrency.euro,
          exchangeRates: testRates,
          category: ExpenseCategory.food,
        ),
        ExpenseModel(
          uuid: '2',
          value: 999.0,
          description: 'Food 2023 - deve essere esclusa',
          createdOn: DateTime(2023, 12, 31),
          userId: 'user-123',
          currency: ExpenseCurrency.euro,
          exchangeRates: testRates,
          category: ExpenseCategory.food,
        ),
        ExpenseModel(
          uuid: '3',
          value: 999.0,
          description: 'Food 2025 - deve essere esclusa',
          createdOn: DateTime(2025, 1, 1),
          userId: 'user-123',
          currency: ExpenseCurrency.euro,
          exchangeRates: testRates,
          category: ExpenseCategory.food,
        ),
      ];

      // ACT
      final byCategory = ExpenseCalculator.expensesByCategoryForYear(
        expenses,
        '2024',
        ExpenseCurrency.euro,
      );

      // ASSERT
      // Solo la spesa del 2024 deve essere inclusa
      expect(byCategory[ExpenseCategory.food], 100.0);
    });

    // =================================================================
    // TEST 21: Expenses by Category For Year - Multi-currency conversion
    // =================================================================
    test(
      'Should convert expenses to target currency before aggregating by category',
      () {
        // ARRANGE
        final expenses = [
          ExpenseModel(
            uuid: '1',
            value: 100.0,
            description: 'EUR food',
            createdOn: DateTime(2024, 1, 15),
            userId: 'user-123',
            currency: ExpenseCurrency.euro,
            exchangeRates: testRates,
            category: ExpenseCategory.food,
          ),
          ExpenseModel(
            uuid: '2',
            value: 110.0, // 110 USD = 100 EUR
            description: 'USD food',
            createdOn: DateTime(2024, 2, 10),
            userId: 'user-123',
            currency: ExpenseCurrency.usd,
            exchangeRates: testRates,
            category: ExpenseCategory.food,
          ),
        ];

        // ACT
        final byCategory = ExpenseCalculator.expensesByCategoryForYear(
          expenses,
          '2024',
          ExpenseCurrency.euro,
        );

        // ASSERT
        // 100 EUR + (110 USD → 100 EUR) = 200 EUR
        expect(byCategory[ExpenseCategory.food], closeTo(200.0, 0.01));
      },
    );

    // =================================================================
    // TEST 22: Expenses by Category For Year - Anno senza spese
    // =================================================================
    test(
      'Should return empty map when no expenses match the requested year',
      () {
        // ARRANGE
        final expenses = [
          ExpenseModel(
            uuid: '1',
            value: 100.0,
            description: 'Food 2023',
            createdOn: DateTime(2023, 6, 1),
            userId: 'user-123',
            currency: ExpenseCurrency.euro,
            exchangeRates: testRates,
            category: ExpenseCategory.food,
          ),
        ];

        // ACT
        final byCategory = ExpenseCalculator.expensesByCategoryForYear(
          expenses,
          '2024',
          ExpenseCurrency.euro,
        );

        // ASSERT
        expect(byCategory, isEmpty);
      },
    );

    // =================================================================
    // TEST 23: Expenses by Category For Year - Tutte le categorie distinte
    // =================================================================
    test('Should produce one entry per distinct category', () {
      // ARRANGE
      final expenses = [
        ExpenseModel(
          uuid: '1',
          value: 100.0,
          description: 'Food',
          createdOn: DateTime(2024, 1, 1),
          userId: 'user-123',
          currency: ExpenseCurrency.euro,
          exchangeRates: testRates,
          category: ExpenseCategory.food,
        ),
        ExpenseModel(
          uuid: '2',
          value: 200.0,
          description: 'Transport',
          createdOn: DateTime(2024, 2, 1),
          userId: 'user-123',
          currency: ExpenseCurrency.euro,
          exchangeRates: testRates,
          category: ExpenseCategory.transport,
        ),
        ExpenseModel(
          uuid: '3',
          value: 300.0,
          description: 'Health',
          createdOn: DateTime(2024, 3, 1),
          userId: 'user-123',
          currency: ExpenseCurrency.euro,
          exchangeRates: testRates,
          category: ExpenseCategory.health,
        ),
      ];

      // ACT
      final byCategory = ExpenseCalculator.expensesByCategoryForYear(
        expenses,
        '2024',
        ExpenseCurrency.euro,
      );

      // ASSERT
      expect(byCategory.length, 3);
      expect(byCategory[ExpenseCategory.food], 100.0);
      expect(byCategory[ExpenseCategory.transport], 200.0);
      expect(byCategory[ExpenseCategory.health], 300.0);
    });

    // =================================================================
    // TEST 24: Sort by unknown criteria - Lista non modificata
    // =================================================================
    test('Should not modify list for unknown sort criteria', () {
      final expenses = [
        ExpenseModel(
          uuid: '1',
          value: 100.0,
          description: null,
          createdOn: DateTime(2024, 1, 20),
          userId: 'user-123',
          currency: ExpenseCurrency.euro,
          exchangeRates: testRates,
        ),
        ExpenseModel(
          uuid: '2',
          value: 50.0,
          description: null,
          createdOn: DateTime(2024, 1, 10),
          userId: 'user-123',
          currency: ExpenseCurrency.euro,
          exchangeRates: testRates,
        ),
      ];

      ExpenseCalculator.sortInPlace(expenses, 'unknown_criteria');

      // Lista non modificata
      expect(expenses[0].uuid, '1');
      expect(expenses[1].uuid, '2');
    });

    // =================================================================
    // TEST 25: Expense created exactly at midnight - inclusa
    // =================================================================
    test('Should include expense created exactly at midnight of today', () {
      final midnight = DateTime(now.year, now.month, now.day, 0, 0, 0);
      final expenses = [
        ExpenseModel(
          uuid: 'midnight',
          value: 100.0,
          description: null,
          createdOn: midnight,
          userId: 'user-123',
          currency: ExpenseCurrency.euro,
          exchangeRates: testRates,
        ),
      ];

      final total = ExpenseCalculator.totalExpenseToday(
        expenses,
        ExpenseCurrency.euro,
      );

      expect(total, 100.0); // inclusa grazie a !isBefore
    });
  });
}
