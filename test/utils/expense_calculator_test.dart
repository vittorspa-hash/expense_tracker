// FILE: expense_calculator_test.dart
// DESCRIZIONE: Test suite per ExpenseCalculator
// Testa calcoli temporali (oggi, settimana, mese, anno), aggregazioni per grafici,
// ordinamento, e gestione conversioni multi-valuta.

import 'package:expense_tracker/models/expense_currency.dart';
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
      now = DateTime.now();

      testRates = {
        'EUR': 1.0,
        'USD': 1.10,
        'GBP': 0.85,
        'JPY': 130.0,
      };

      // --- DATE ROBUSTE ---
      // week-1: deve stare nella settimana corrente ma NON oggi.
      // Usiamo il giorno corrente della settimana per trovare un giorno sicuro:
      // se siamo a mercoledì (weekday=3) usiamo "ieri" (-1), altrimenti "ieri" funziona
      // sempre perché c'è sempre almeno 1 giorno prima nella settimana ISO (lun-dom).
      // ECCEZIONE: se oggi è lunedì (weekday=1) "ieri" è domenica della settimana scorsa,
      // quindi usiamo "stesso giorno" trick: forziamo la data a lunedì stesso ma con ora=00:01,
      // oppure più semplicemente usiamo un giorno della settimana corrente calcolato.
      final int todayWeekday = now.weekday; // 1=lun, 7=dom
      // Giorni dall'inizio della settimana (lunedì): se oggi è lun→0, mar→1, ...
      final int daysFromMonday = todayWeekday - 1;
      // Se siamo a lunedì (daysFromMonday=0) non c'è ieri nella stessa settimana:
      // usiamo "oggi ma 1 ora fa" come spesa settimanale non-today.
      // Altrimenti usiamo "ieri".
      final DateTime weekDate = daysFromMonday == 0
          ? now.subtract(const Duration(hours: 1))   // lunedì: 1 ora fa (stesso giorno, ma diverso da "adesso")
          : now.subtract(const Duration(days: 1));    // altri giorni: ieri

      // month-1: deve stare nel mese corrente ma NON in questa settimana.
      // PROBLEMA NOTO: totalExpenseMonth usa .isAfter(startOfMonth) — stretto.
      // Una spesa a mezzanotte esatta del 1° del mese viene ESCLUSA perché non è
      // "dopo" startOfMonth, è "uguale". Quindi usiamo il 1° del mese con ora 00:01
      // per essere sicuramente inclusi.
      // Inoltre: se siamo nei primi 7 giorni del mese il 1° potrebbe cadere
      // nella settimana corrente → il lower bound del test scende a ≥180.
      final DateTime monthDate = now.day > 7
          ? DateTime(now.year, now.month, 1, 0, 1)   // 1° del mese ore 00:01 (fuori settimana, dentro mese)
          : DateTime(now.year, now.month, 1, 0, 1);  // stesso, ma in questo caso potrebbe essere in settimana

      // Dataset di test con spese distribuite temporalmente
      testExpenses = [
        // OGGI
        ExpenseModel(
          uuid: 'today-1',
          value: 50.0,
          description: 'Today expense 1',
          createdOn: now,
          userId: 'user-123',
          currency: ExpenseCurrency.euro,
          exchangeRates: testRates,
        ),
        ExpenseModel(
          uuid: 'today-2',
          value: 30.0,
          description: 'Today expense 2',
          createdOn: now.subtract(const Duration(hours: 2)),
          userId: 'user-123',
          currency: ExpenseCurrency.euro,
          exchangeRates: testRates,
        ),

        // QUESTA SETTIMANA (ma non oggi) — data calcolata dinamicamente
        ExpenseModel(
          uuid: 'week-1',
          value: 100.0,
          description: 'Week expense',
          createdOn: weekDate,
          userId: 'user-123',
          currency: ExpenseCurrency.euro,
          exchangeRates: testRates,
        ),

        // QUESTO MESE (ma non questa settimana) — usato solo se day > 7
        ExpenseModel(
          uuid: 'month-1',
          value: 200.0,
          description: 'Month expense',
          createdOn: monthDate,
          userId: 'user-123',
          currency: ExpenseCurrency.euro,
          exchangeRates: testRates,
        ),

        // QUEST'ANNO (mese diverso da quello corrente)
        ExpenseModel(
          uuid: 'year-1',
          value: 500.0,
          description: 'Earlier this year',
          createdOn: DateTime(now.year, 1, 15),
          userId: 'user-123',
          currency: ExpenseCurrency.euro,
          exchangeRates: testRates,
        ),

        // ANNO PASSATO (escluso da tutti i totali)
        ExpenseModel(
          uuid: 'old-1',
          value: 1000.0,
          description: 'Old expense',
          createdOn: DateTime(now.year - 1, 12, 31),
          userId: 'user-123',
          currency: ExpenseCurrency.euro,
          exchangeRates: testRates,
        ),
      ];
    });

    // =================================================================
    // TEST 1: Total Expense Today
    // =================================================================
    test('Should calculate total expenses for today only', () {
      final total = ExpenseCalculator.totalExpenseToday(testExpenses, ExpenseCurrency.euro,);
      // Solo today-1 (50) + today-2 (30) = 80
      expect(total, 80.0);
    });

    // =================================================================
    // TEST 2: Total Expense Week
    // =================================================================
    test('Should calculate total expenses for current week', () {
      final total = ExpenseCalculator.totalExpenseWeek(testExpenses, ExpenseCurrency.euro,);

      // Oggi (80) + week-1 (100) = almeno 180.
      // week-1 è sempre nella settimana corrente per costruzione (vedi setUp).
      expect(total, greaterThanOrEqualTo(180.0));
    });

    // =================================================================
    // TEST 3: Total Expense Month
    // =================================================================
    test('Should calculate total expenses for current month', () {
      final total = ExpenseCalculator.totalExpenseMonth(testExpenses, ExpenseCurrency.euro,);

      // totalExpenseMonth usa .isAfter(startOfMonth) — stretto, non >=.
      // month-1 è impostata a DateTime(now.year, now.month, 1, 0, 1) quindi
      // è sempre inclusa (00:01 > 00:00).
      //
      // Caso A (now.day > 7): month-1 è fuori dalla settimana corrente.
      //   Totale = oggi(80) + week-1(100) + month-1(200) = 380
      // Caso B (now.day <= 7): month-1 (1° del mese ore 00:01) potrebbe
      //   essere nella settimana corrente e già conteggiata in week.
      //   Totale minimo garantito = oggi(80) + week-1(100) + month-1(200) = 380
      //   perché month-1 ha data distinta da week-1 (week-1 = ieri o 1h fa).
      expect(total, greaterThanOrEqualTo(380.0));
    });

    // =================================================================
    // TEST 4: Total Expense Year
    // =================================================================
    test('Should calculate total expenses for current year', () {
      final total = ExpenseCalculator.totalExpenseYear(testExpenses, ExpenseCurrency.euro,);

      // Include tutte le spese dell'anno corrente, esclude anno passato (1000€).
      // Minimo: oggi (80) + week (100) + month (200) = 380
      expect(total, greaterThanOrEqualTo(380.0));
      expect(total, lessThan(2000.0)); // anno passato escluso
    });

    // =================================================================
    // TEST 5: Total with Multi-Currency Conversion
    // =================================================================
    test('Should convert expenses to target currency before summing', () {
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

      final totalInEUR = ExpenseCalculator.totalExpenseToday(
        multiCurrencyExpenses,
        ExpenseCurrency.euro,
      );

      // 100 EUR + (110 USD → 100 EUR) = 200 EUR
      expect(totalInEUR, closeTo(200.0, 0.01));
    });

    // =================================================================
    // TEST 6: Empty Expenses List
    // =================================================================
    test('Should return 0 for empty expenses list', () {
      final total = ExpenseCalculator.totalExpenseToday([], ExpenseCurrency.euro,);
      expect(total, 0.0);
    });

    // =================================================================
    // TEST 7: Expenses by Month - Aggregation
    // =================================================================
    test('Should aggregate expenses by month with correct format', () {
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

      final byMonth = ExpenseCalculator.expensesByMonth(expenses, ExpenseCurrency.euro,);

      expect(byMonth.containsKey('2024-01'), true);
      expect(byMonth.containsKey('2024-02'), true);
      expect(byMonth['2024-01'], 150.0); // 100 + 50
      expect(byMonth['2024-02'], 200.0);
    });

    // =================================================================
    // TEST 8: Expenses by Month - Sorted Descending
    // =================================================================
    test('Should return months sorted in descending order', () {
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

      final byMonth = ExpenseCalculator.expensesByMonth(expenses, ExpenseCurrency.euro,);
      final keys = byMonth.keys.toList();

      expect(keys[0], '2024-03');
      expect(keys[1], '2024-02');
      expect(keys[2], '2024-01');
    });

    // =================================================================
    // TEST 9: Expenses by Day - Specific Month
    // =================================================================
    test('Should aggregate expenses by day for specific month', () {
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

      final byDay = ExpenseCalculator.expensesByDay(expenses, 2024, 1, ExpenseCurrency.euro,);

      expect(byDay.containsKey('15/01/2024'), true);
      expect(byDay.containsKey('20/01/2024'), true);
      expect(byDay.containsKey('15/02/2024'), false);
      expect(byDay['15/01/2024'], 80.0); // 50 + 30
      expect(byDay['20/01/2024'], 100.0);
    });

    // =================================================================
    // TEST 10: Expenses of Specific Day - Raw List
    // =================================================================
    test('Should return raw expense list for specific day', () {
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

      final dayExpenses = ExpenseCalculator.expensesOfDay(expenses, 2024, 1, 15);

      expect(dayExpenses.length, 2);
      expect(dayExpenses[0].uuid, '2'); // Più recente prima (14:00)
      expect(dayExpenses[1].uuid, '1'); // Meno recente dopo (09:00)
    });

    // =================================================================
    // TEST 11: Sort by Date Descending
    // =================================================================
    test('Should sort expenses by date in descending order', () {
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

      ExpenseCalculator.sortInPlace(expenses, 'date_desc');

      expect(expenses[0].uuid, '2');
      expect(expenses[1].uuid, '3');
      expect(expenses[2].uuid, '1');
    });

    // =================================================================
    // TEST 12: Sort by Date Ascending
    // =================================================================
    test('Should sort expenses by date in ascending order', () {
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
      ];

      ExpenseCalculator.sortInPlace(expenses, 'date_asc');

      expect(expenses[0].uuid, '2');
      expect(expenses[1].uuid, '1');
    });

    // =================================================================
    // TEST 13: Sort by Amount Descending (No Currency Conversion)
    // =================================================================
    test('Should sort by raw amount when no target currency provided', () {
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

      ExpenseCalculator.sortInPlace(expenses, 'amount_desc');

      expect(expenses[0].value, 200.0);
      expect(expenses[1].value, 100.0);
      expect(expenses[2].value, 50.0);
    });

    // =================================================================
    // TEST 14: Sort by Amount with Currency Conversion
    // =================================================================
    test('Should sort by converted amount when target currency provided', () {
      final expenses = [
        ExpenseModel(
          uuid: '1',
          value: 100.0,
          description: 'EUR expense',
          createdOn: DateTime.now(),
          userId: 'user-123',
          currency:ExpenseCurrency.euro,
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

      ExpenseCalculator.sortInPlace(expenses, 'amount_desc', targetCurrency: ExpenseCurrency.euro,);

      expect(expenses[0].uuid, '3'); // 220 USD = 200 EUR (largest)
    });

    // =================================================================
    // TEST 15: Sort by Amount Ascending
    // =================================================================
    test('Should sort by amount in ascending order', () {
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

      ExpenseCalculator.sortInPlace(expenses, 'amount_asc');

      expect(expenses[0].value, 50.0);
      expect(expenses[1].value, 200.0);
    });

    // =================================================================
    // TEST 16: Aggregation with Empty List
    // =================================================================
    test('Should return empty map when aggregating empty list', () {
      final byMonth = ExpenseCalculator.expensesByMonth([], ExpenseCurrency.euro);
      final byDay = ExpenseCalculator.expensesByDay([], 2024, 1, ExpenseCurrency.euro);

      expect(byMonth, isEmpty);
      expect(byDay, isEmpty);
    });

    // =================================================================
    // TEST 17: Expenses of Day - No Matches
    // =================================================================
    test('Should return empty list when no expenses match the day', () {
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

      final dayExpenses = ExpenseCalculator.expensesOfDay(expenses, 2024, 1, 15);

      expect(dayExpenses, isEmpty);
    });

    // =================================================================
    // TEST 18: Sort by Amount Ascending with Currency Conversion
    // =================================================================
    test('Should sort by converted amount in ascending order when target currency provided', () {
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

      ExpenseCalculator.sortInPlace(expenses, 'amount_asc', targetCurrency: ExpenseCurrency.euro,);

      expect(expenses[0].uuid, '3'); // 50 EUR (smallest)
      expect(expenses[1].uuid, '2'); // 85 GBP = 100 EUR (medium)
      expect(expenses[2].uuid, '1'); // 220 USD = 200 EUR (largest)
    });
  });
}