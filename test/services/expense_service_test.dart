// FILE: expense_service_test.dart
// DESCRIZIONE: Test suite per ExpenseService
// Testa la business logic: creazione, modifica, eliminazione, calcoli aggregati,
// verifiche budget, e strategie soft-fail/smart-update.
// Utilizza MOCK per simulare Firebase e CurrencyService senza dipendenze esterne.

import 'package:expense_tracker/models/expense_category.dart';
import 'package:expense_tracker/models/expense_currency.dart';
import 'package:expense_tracker/models/expense_model.dart';
import 'package:expense_tracker/repositories/firebase_repository.dart';
import 'package:expense_tracker/services/currency_service.dart';
import 'package:expense_tracker/services/expense_service.dart';
import 'package:expense_tracker/utils/repository_failure.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

// Questa annotazione genera i mock automaticamente
// Esegui: flutter pub run build_runner build
@GenerateMocks([
  FirebaseRepository,
  FirebaseAuth,
  User,
  CurrencyService,
])
import 'expense_service_test.mocks.dart';

void main() {
  group('ExpenseService Tests', () {
    // --- SETUP: Mock e dipendenze ---
    late ExpenseService expenseService;
    late MockFirebaseRepository mockRepository;
    late MockFirebaseAuth mockAuth;
    late MockUser mockUser;
    late MockCurrencyService mockCurrencyService;

    // Dati di test riutilizzabili
    late ExpenseModel sampleExpense;
    late Map<String, double> testRates;

    setUp(() {
      // IMPORTANTE: setUp() ricrea TUTTI i mock prima di ogni test
      // Questo garantisce test isolation (nessun test inquina l'altro)

      mockRepository = MockFirebaseRepository();
      mockAuth = MockFirebaseAuth();
      mockUser = MockUser();
      mockCurrencyService = MockCurrencyService();

      // Configurazione default: utente autenticato
      when(mockAuth.currentUser).thenReturn(mockUser);
      when(mockUser.uid).thenReturn('test-user-123');

      // Inietta i MOCK invece delle dipendenze reali
      expenseService = ExpenseService(
        firebaseRepository: mockRepository,
        firebaseAuth: mockAuth,
        currencyService: mockCurrencyService,
      );

      // Dati di test
      testRates = {
        'EUR': 1.0,
        'USD': 1.10,
        'GBP': 0.85,
      };

      sampleExpense = ExpenseModel(
        uuid: 'expense-123',
        value: 100.0,
        description: 'Test expense',
        createdOn: DateTime(2024, 1, 15),
        userId: 'test-user-123',
        currency: ExpenseCurrency.euro,
        exchangeRates: testRates,
        category: ExpenseCategory.food, // categoria esplicita nel campione base
      );
    });

    // =================================================================
    // TEST 1: Load User Expenses - Success
    // =================================================================
    test('Should load and sort user expenses by date (newest first)', () async {
      // ARRANGE
      final expense1 = sampleExpense.copyWith(
        createdOn: DateTime(2024, 1, 10),
      );
      final expense2 = sampleExpense.copyWith(
        uuid: 'expense-456',
        createdOn: DateTime(2024, 1, 20), // Più recente
      );

      when(mockRepository.allExpensesForUser('test-user-123'))
          .thenAnswer((_) async => [expense1, expense2]);

      // ACT
      final expenses = await expenseService.loadUserExpenses();

      // ASSERT
      verify(mockRepository.allExpensesForUser('test-user-123')).called(1);
      expect(expenses.length, 2);
      expect(expenses[0].createdOn, DateTime(2024, 1, 20));
      expect(expenses[1].createdOn, DateTime(2024, 1, 10));
    });

    // =================================================================
    // TEST 2: Load User Expenses - No User Authenticated
    // =================================================================
    test('Should return empty list when no user is authenticated', () async {
      // ARRANGE
      when(mockAuth.currentUser).thenReturn(null);

      // ACT
      final expenses = await expenseService.loadUserExpenses();

      // ASSERT
      expect(expenses, isEmpty);
      verifyNever(mockRepository.allExpensesForUser(any));
    });

    // =================================================================
    // TEST 3: Create Expense - Success (Online)
    // =================================================================
    test('Should create expense with real exchange rates when online', () async {
      // ARRANGE
      when(mockCurrencyService.getExchangeRates('USD'))
          .thenAnswer((_) async => testRates);
      when(mockRepository.createExpense(any))
          .thenAnswer((_) async => {});

      // ACT
      final result = await expenseService.createExpense(
        value: 50.0,
        description: 'Grocery',
        date: DateTime(2024, 1, 15),
        currency: ExpenseCurrency.usd,
        category: ExpenseCategory.food,
      );

      // ASSERT
      expect(result.warning, isNull);
      expect(result.expense.value, 50.0);
      expect(result.expense.description, 'Grocery');
      expect(result.expense.currency, ExpenseCurrency.usd);
      expect(result.expense.exchangeRates, testRates);
      expect(result.expense.category, ExpenseCategory.food);
      verify(mockRepository.createExpense(any)).called(1);
      verify(mockCurrencyService.getExchangeRates('USD')).called(1);
    });

    // =================================================================
    // TEST 4: Create Expense - Soft Fail (Offline)
    // =================================================================
    test('Should create expense with fallback rates when currency fetch fails', () async {
      // ARRANGE
      when(mockCurrencyService.getExchangeRates('EUR'))
          .thenThrow(CurrencyFetchException('Network error'));
      when(mockRepository.createExpense(any))
          .thenAnswer((_) async => {});

      // ACT
      final result = await expenseService.createExpense(
        value: 75.0,
        description: 'Offline expense',
        date: DateTime(2024, 1, 15),
        currency: ExpenseCurrency.euro,
        category: ExpenseCategory.other,
      );

      // ASSERT
      expect(result.warning, 'offline_currency_create');
      expect(result.expense.exchangeRates, {'EUR': 1.0});
      expect(result.expense.category, ExpenseCategory.other);
      verify(mockRepository.createExpense(any)).called(1);
    });

    // =================================================================
    // TEST 5: Create Expense - No User Authenticated
    // =================================================================
    test('Should throw exception when creating expense without authentication', () async {
      // ARRANGE
      when(mockAuth.currentUser).thenReturn(null);

      // ACT & ASSERT
      expect(
        () => expenseService.createExpense(
          value: 50.0,
          description: 'Test',
          date: DateTime.now(),
          currency: ExpenseCurrency.euro,
          category: ExpenseCategory.other,
        ),
        throwsA(isA<RepositoryFailure>()),
      );
    });

    // =================================================================
    // TEST 6: Edit Expense - Success (No Repair Needed)
    // =================================================================
    test('Should edit expense without repairing rates when rates are valid', () async {
      // ARRANGE
      final expenseWithValidRates = sampleExpense; // Ha 3 valute

      when(mockRepository.updateExpense(any))
          .thenAnswer((_) async => {});

      // ACT
      final result = await expenseService.editExpense(
        expenseWithValidRates,
        value: 150.0,
        description: 'Updated',
        date: DateTime(2024, 1, 16),
        currency: ExpenseCurrency.euro,
        category: ExpenseCategory.transport,
      );

      // ASSERT
      expect(result.warning, isNull);
      expect(result.expense.value, 150.0);
      expect(result.expense.description, 'Updated');
      expect(result.expense.exchangeRates, testRates);
      expect(result.expense.category, ExpenseCategory.transport);
      verifyNever(mockCurrencyService.getExchangeRates(any));
      verify(mockRepository.updateExpense(any)).called(1);
    });

    // =================================================================
    // TEST 7: Edit Expense - Smart Update (Repair Success)
    // =================================================================
    test('Should repair broken exchange rates during edit when online', () async {
      // ARRANGE
      final brokenExpense = sampleExpense.copyWith(
        exchangeRates: {'USD': 1.0}, // Solo 1 = broken!
      );

      when(mockCurrencyService.getExchangeRates('USD'))
          .thenAnswer((_) async => testRates);
      when(mockRepository.updateExpense(any))
          .thenAnswer((_) async => {});

      // ACT
      final result = await expenseService.editExpense(
        brokenExpense,
        value: 200.0,
        description: 'Repaired',
        date: DateTime(2024, 1, 17),
        currency: ExpenseCurrency.usd,
        category: ExpenseCategory.shopping,
      );

      // ASSERT
      expect(result.warning, isNull);
      expect(result.expense.exchangeRates, testRates);
      expect(result.expense.exchangeRates.length, 3);
      expect(result.expense.category, ExpenseCategory.shopping);
      verify(mockCurrencyService.getExchangeRates('USD')).called(1);
    });

    // =================================================================
    // TEST 8: Edit Expense - Smart Update (Repair Fails)
    // =================================================================
    test('Should keep fallback rates when repair fails (still offline)', () async {
      // ARRANGE
      final brokenExpense = sampleExpense.copyWith(
        exchangeRates: {'GBP': 1.0},
      );

      when(mockCurrencyService.getExchangeRates('GBP'))
          .thenThrow(CurrencyFetchException('Still offline'));
      when(mockRepository.updateExpense(any))
          .thenAnswer((_) async => {});

      // ACT
      final result = await expenseService.editExpense(
        brokenExpense,
        value: 80.0,
        description: 'Still broken',
        date: DateTime(2024, 1, 18),
        currency: ExpenseCurrency.gbp,
        category: ExpenseCategory.health,
      );

      // ASSERT
      expect(result.warning, 'offline_currency_edit');
      expect(result.expense.exchangeRates, {'GBP': 1.0});
      expect(result.expense.category, ExpenseCategory.health);
      verify(mockRepository.updateExpense(any)).called(1);
    });

    // =================================================================
    // TEST 9: Delete Expense - Success
    // =================================================================
    test('Should delete expense when user is authorized', () async {
      // ARRANGE
      when(mockRepository.deleteExpense(sampleExpense))
          .thenAnswer((_) async => {});

      // ACT
      await expenseService.deleteExpense(sampleExpense);

      // ASSERT
      verify(mockRepository.deleteExpense(sampleExpense)).called(1);
    });

    // =================================================================
    // TEST 10: Delete Expense - Permission Denied
    // =================================================================
    test('Should throw exception when deleting another user\'s expense', () async {
      // ARRANGE
      final otherUserExpense = sampleExpense.copyWith(
        userId: 'other-user-999',
      );

      // ACT & ASSERT
      expect(
        () => expenseService.deleteExpense(otherUserExpense),
        throwsA(isA<RepositoryFailure>()),
      );
      verifyNever(mockRepository.deleteExpense(any));
    });

    // =================================================================
    // TEST 11: Calculate Totals
    // =================================================================
    test('Should calculate expense totals for different time periods', () {
      // ARRANGE
      final now = DateTime.now();
      final expenses = [
        sampleExpense.copyWith(createdOn: now, value: 50.0),
        sampleExpense.copyWith(
          createdOn: now.subtract(const Duration(days: 2)),
          value: 30.0,
        ),
        sampleExpense.copyWith(
          createdOn: DateTime(now.year, now.month, 1),
          value: 20.0,
        ),
        sampleExpense.copyWith(
          createdOn: DateTime(now.year, 1, 1),
          value: 100.0,
        ),
      ];

      // ACT
      final totals = expenseService.calculateTotals(expenses, ExpenseCurrency.euro);

      // ASSERT
      expect(totals.today, greaterThan(0));
      expect(totals.week, greaterThanOrEqualTo(totals.today));
      expect(totals.month, greaterThanOrEqualTo(totals.week));
      expect(totals.year, greaterThanOrEqualTo(totals.month));
    });

    // =================================================================
    // TEST 12: Budget Check - Should Notify
    // =================================================================
    test('Should notify when monthly expenses exceed budget limit', () {
      // ARRANGE
      final now = DateTime.now();
      final expenses = [
        sampleExpense.copyWith(createdOn: now, value: 600.0),
      ];

      // ACT
      final result = expenseService.checkBudgetStatus(
        expenses: expenses,
        expenseDate: now,
        targetCurrency: ExpenseCurrency.euro,
        budgetLimit: 500.0,
        alertEnabled: true,
      );

      // ASSERT
      expect(result.shouldNotify, true);
      expect(result.currentTotal, greaterThanOrEqualTo(500.0));
    });

    // =================================================================
    // TEST 13: Budget Check - Should NOT Notify (Alert Disabled)
    // =================================================================
    test('Should not notify when budget alerts are disabled', () {
      // ARRANGE
      final expenses = [
        sampleExpense.copyWith(value: 1000.0),
      ];

      // ACT
      final result = expenseService.checkBudgetStatus(
        expenses: expenses,
        expenseDate: DateTime.now(),
        targetCurrency: ExpenseCurrency.euro,
        budgetLimit: 100.0,
        alertEnabled: false,
      );

      // ASSERT
      expect(result.shouldNotify, false);
    });

    // =================================================================
    // TEST 14: Budget Check - Should NOT Notify (Different Month)
    // =================================================================
    test('Should not notify for expenses from different months', () {
      // ARRANGE
      final lastMonth = DateTime.now().subtract(const Duration(days: 60));
      final expenses = [
        sampleExpense.copyWith(createdOn: lastMonth, value: 1000.0),
      ];

      // ACT
      final result = expenseService.checkBudgetStatus(
        expenses: expenses,
        expenseDate: lastMonth,
        targetCurrency: ExpenseCurrency.euro,
        budgetLimit: 100.0,
        alertEnabled: true,
      );

      // ASSERT
      expect(result.shouldNotify, false);
    });

    // =================================================================
    // TEST 15: Sort Expenses by Date (Descending)
    // =================================================================
    test('Should sort expenses by date in descending order', () {
      // ARRANGE
      final expenses = [
        sampleExpense.copyWith(createdOn: DateTime(2024, 1, 10)),
        sampleExpense.copyWith(createdOn: DateTime(2024, 1, 20)),
        sampleExpense.copyWith(createdOn: DateTime(2024, 1, 15)),
      ];

      // ACT
      final sorted = expenseService.sortExpenses(expenses, 'date_desc', ExpenseCurrency.euro);

      // ASSERT
      expect(sorted[0].createdOn, DateTime(2024, 1, 20));
      expect(sorted[1].createdOn, DateTime(2024, 1, 15));
      expect(sorted[2].createdOn, DateTime(2024, 1, 10));
    });

    // =================================================================
    // TEST 16: Get Expenses by Month (Aggregation)
    // =================================================================
    test('Should aggregate expenses by month for current year', () {
      // ARRANGE
      final now = DateTime.now();
      final expenses = [
        sampleExpense.copyWith(
          createdOn: DateTime(now.year, 1, 15),
          value: 100.0,
        ),
        sampleExpense.copyWith(
          createdOn: DateTime(now.year, 1, 20),
          value: 50.0,
        ),
        sampleExpense.copyWith(
          createdOn: DateTime(now.year, 2, 10),
          value: 75.0,
        ),
      ];

      // ACT
      final byMonth = expenseService.getExpensesByMonth(expenses, ExpenseCurrency.euro);

      // ASSERT
      expect(byMonth, isNotEmpty);
      final totalValues = byMonth.values.fold<double>(0, (sum, val) => sum + val);
      expect(totalValues, closeTo(225.0, 0.01));
    });

    // =================================================================
    // TEST 17: Restore Expense - Success
    // =================================================================
    test('Should restore expense when user is authorized', () async {
      // ARRANGE
      when(mockRepository.createExpense(sampleExpense))
          .thenAnswer((_) async => {});

      // ACT
      final restored = await expenseService.restoreExpense(sampleExpense);

      // ASSERT
      expect(restored.uuid, sampleExpense.uuid);
      expect(restored.value, sampleExpense.value);
      expect(restored.category, sampleExpense.category);
      verify(mockRepository.createExpense(sampleExpense)).called(1);
    });

    // =================================================================
    // TEST 18: Restore Expense - Not Authenticated
    // =================================================================
    test('Should throw when restoring expense without authentication', () async {
      // ARRANGE
      when(mockAuth.currentUser).thenReturn(null);

      // ACT & ASSERT
      expect(
        () => expenseService.restoreExpense(sampleExpense),
        throwsA(isA<RepositoryFailure>()),
      );
      verifyNever(mockRepository.createExpense(any));
    });

    // =================================================================
    // TEST 19: Restore Expense - Permission Denied
    // =================================================================
    test('Should throw when restoring another user\'s expense', () async {
      // ARRANGE
      final otherUserExpense = sampleExpense.copyWith(
        userId: 'other-user-999',
      );

      // ACT & ASSERT
      expect(
        () => expenseService.restoreExpense(otherUserExpense),
        throwsA(isA<RepositoryFailure>()),
      );
      verifyNever(mockRepository.createExpense(any));
    });

    // =================================================================
    // TEST 20: Edit Expense - Permission Denied (User Mismatch)
    // =================================================================
    test('Should throw when editing expense with mismatched user', () async {
      // ARRANGE
      final otherUserExpense = sampleExpense.copyWith(
        userId: 'other-user-999',
      );

      // ACT & ASSERT
      expect(
        () => expenseService.editExpense(
          otherUserExpense,
          value: 100.0,
          description: 'Try to edit',
          date: DateTime.now(),
          currency: ExpenseCurrency.euro,
          category: ExpenseCategory.other,
        ),
        throwsA(isA<RepositoryFailure>()),
      );
      verifyNever(mockRepository.updateExpense(any));
    });

    // =================================================================
    // TEST 21: Budget Check for List - Should Notify
    // =================================================================
    test('Should notify when restoring expenses exceeds budget', () {
      // ARRANGE
      final now = DateTime.now();
      final currentMonthExpenses = [
        sampleExpense.copyWith(createdOn: now, value: 400.0),
      ];
      final restoredExpenses = [
        sampleExpense.copyWith(uuid: 'restored-1', createdOn: now, value: 200.0),
      ];
      final allExpenses = [...currentMonthExpenses, ...restoredExpenses];

      // ACT
      final result = expenseService.checkBudgetStatusForList(
        allExpenses: allExpenses,
        newExpenses: restoredExpenses,
        targetCurrency: ExpenseCurrency.euro,
        budgetLimit: 500.0,
        alertEnabled: true,
      );

      // ASSERT
      expect(result.shouldNotify, true);
      expect(result.currentTotal, greaterThanOrEqualTo(500.0));
    });

    // =================================================================
    // TEST 22: Budget Check for List - No Current Month Expense
    // =================================================================
    test('Should not notify when restored expenses are from past months', () {
      // ARRANGE
      final oldExpense = sampleExpense.copyWith(
        createdOn: DateTime(2023, 1, 15),
        value: 1000.0,
      );

      // ACT
      final result = expenseService.checkBudgetStatusForList(
        allExpenses: [oldExpense],
        newExpenses: [oldExpense],
        targetCurrency: ExpenseCurrency.euro,
        budgetLimit: 100.0,
        alertEnabled: true,
      );

      // ASSERT
      expect(result.shouldNotify, false);
    });

    // =================================================================
    // TEST 23: Budget Check for List - Alert Disabled
    // =================================================================
    test('Should not notify when budget alerts are disabled for list', () {
      // ARRANGE
      final now = DateTime.now();
      final expenses = [
        sampleExpense.copyWith(createdOn: now, value: 1000.0),
      ];

      // ACT
      final result = expenseService.checkBudgetStatusForList(
        allExpenses: expenses,
        newExpenses: expenses,
        targetCurrency: ExpenseCurrency.euro,
        budgetLimit: 100.0,
        alertEnabled: false,
      );

      // ASSERT
      expect(result.shouldNotify, false);
    });
  });
}