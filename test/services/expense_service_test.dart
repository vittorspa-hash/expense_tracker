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
@GenerateMocks([FirebaseRepository, User, CurrencyService])
import 'expense_service_test.mocks.dart';

void main() {
  group('ExpenseService Tests', () {
    // --- SETUP: Mock e dipendenze ---
    late ExpenseService expenseService;
    late MockFirebaseRepository mockRepository;
    late MockUser mockUser;
    late MockCurrencyService mockCurrencyService;

    // Dati di test riutilizzabili
    late ExpenseModel sampleExpense;
    late Map<String, double> testRates;

    setUp(() {
      // IMPORTANTE: setUp() ricrea TUTTI i mock prima di ogni test
      // Questo garantisce test isolation (nessun test inquina l'altro)

      mockRepository = MockFirebaseRepository();
      mockUser = MockUser();
      mockCurrencyService = MockCurrencyService();

      // Configurazione default: utente autenticato
      when(mockUser.uid).thenReturn('test-user-123');

      // Inietta i MOCK invece delle dipendenze reali
      expenseService = ExpenseService(
        firebaseRepository: mockRepository,
        currencyService: mockCurrencyService,
      );

      // Dati di test
      testRates = {'EUR': 1.0, 'USD': 1.10, 'GBP': 0.85, 'JPY': 130.0};

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
      final expense1 = sampleExpense.copyWith(createdOn: DateTime(2024, 1, 10));
      final expense2 = sampleExpense.copyWith(
        uuid: 'expense-456',
        createdOn: DateTime(2024, 1, 20), // Più recente
      );

      when(
        mockRepository.allExpensesForUser('test-user-123'),
      ).thenAnswer((_) async => [expense1, expense2]);

      // ACT
      final expenses = await expenseService.loadUserExpenses(user: mockUser);

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
      // Nessun setup aggiuntivo: user null simulato direttamente nella chiamata

      // ACT
      final expenses = await expenseService.loadUserExpenses(user: null);

      // ASSERT
      expect(expenses, isEmpty);
      verifyNever(mockRepository.allExpensesForUser(any));
    });

    // =================================================================
    // TEST 3: Create Expense - Success (Online)
    // =================================================================
    test(
      'Should create expense with real exchange rates when online',
      () async {
        // ARRANGE
        when(
          mockCurrencyService.getExchangeRates('USD'),
        ).thenAnswer((_) async => testRates);
        when(mockRepository.createExpense(any)).thenAnswer((_) async => {});

        // ACT
        final result = await expenseService.createExpense(
          value: 50.0,
          description: 'Grocery',
          date: DateTime(2024, 1, 15),
          currency: ExpenseCurrency.usd,
          category: ExpenseCategory.food,
          user: mockUser,
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
      },
    );

    // =================================================================
    // TEST 4: Create Expense - Soft Fail (Offline)
    // =================================================================
    test(
      'Should create expense with fallback rates when currency fetch fails',
      () async {
        // ARRANGE
        when(
          mockCurrencyService.getExchangeRates('EUR'),
        ).thenThrow(CurrencyFetchException('Network error'));
        when(mockRepository.createExpense(any)).thenAnswer((_) async => {});

        // ACT
        final result = await expenseService.createExpense(
          value: 75.0,
          description: 'Offline expense',
          date: DateTime(2024, 1, 15),
          currency: ExpenseCurrency.euro,
          category: ExpenseCategory.other,
          user: mockUser,
        );

        // ASSERT
        expect(result.warning, 'offline_currency_create');
        expect(result.expense.exchangeRates, {'EUR': 1.0});
        verify(mockRepository.createExpense(any)).called(1);
      },
    );

    // =================================================================
    // TEST 5: Create Expense - No User Authenticated
    // =================================================================
    test(
      'Should throw exception when creating expense without authentication',
      () async {
        // ARRANGE
        // Nessun setup aggiuntivo: user null simulato direttamente nella chiamata

        // ACT & ASSERT
        await expectLater(
          () => expenseService.createExpense(
            value: 50.0,
            description: 'Test',
            date: DateTime.now(),
            currency: ExpenseCurrency.euro,
            category: ExpenseCategory.other,
            user: null,
          ),
          throwsA(isA<RepositoryFailure>()),
        );
      },
    );

    // =================================================================
    // TEST 6: Edit Expense - Success (No Repair Needed)
    // =================================================================
    test(
      'Should edit expense without repairing rates when rates are valid',
      () async {
        // ARRANGE
        final expenseWithValidRates = sampleExpense;

        when(mockRepository.updateExpense(any)).thenAnswer((_) async => {});

        // ACT
        final result = await expenseService.editExpense(
          expenseWithValidRates,
          value: 150.0,
          description: 'Updated',
          date: DateTime(2024, 1, 16),
          currency: ExpenseCurrency.euro,
          category: ExpenseCategory.transport,
          user: mockUser,
        );

        // ASSERT
        expect(result.warning, isNull);
        expect(result.expense.value, 150.0);
        expect(result.expense.description, 'Updated');
        expect(result.expense.exchangeRates, testRates);
        expect(result.expense.category, ExpenseCategory.transport);
        verifyNever(mockCurrencyService.getExchangeRates(any));
        verify(mockRepository.updateExpense(any)).called(1);
      },
    );

    // =================================================================
    // TEST 7: Edit Expense - Smart Update (Repair Success)
    // =================================================================
    test(
      'Should repair broken exchange rates during edit when online',
      () async {
        // ARRANGE
        final brokenExpense = sampleExpense.copyWith(
          exchangeRates: {'USD': 1.0}, // Solo 1 = broken!
        );

        when(
          mockCurrencyService.getExchangeRates('USD'),
        ).thenAnswer((_) async => testRates);
        when(mockRepository.updateExpense(any)).thenAnswer((_) async => {});

        // ACT
        final result = await expenseService.editExpense(
          brokenExpense,
          value: 200.0,
          description: 'Repaired',
          date: DateTime(2024, 1, 17),
          currency: ExpenseCurrency.usd,
          category: ExpenseCategory.shopping,
          user: mockUser,
        );

        // ASSERT
        expect(result.warning, isNull);
        expect(result.expense.exchangeRates, testRates);
        verify(mockCurrencyService.getExchangeRates('USD')).called(1);
        verify(mockRepository.updateExpense(any)).called(1);
      },
    );

    // =================================================================
    // TEST 8: Edit Expense - Smart Update (Repair Fails)
    // =================================================================
    test(
      'Should keep fallback rates when repair fails (still offline)',
      () async {
        // ARRANGE
        final brokenExpense = sampleExpense.copyWith(
          exchangeRates: {'GBP': 1.0},
        );

        when(
          mockCurrencyService.getExchangeRates('GBP'),
        ).thenThrow(CurrencyFetchException('Still offline'));
        when(mockRepository.updateExpense(any)).thenAnswer((_) async => {});

        // ACT
        final result = await expenseService.editExpense(
          brokenExpense,
          value: 80.0,
          description: 'Still broken',
          date: DateTime(2024, 1, 18),
          currency: ExpenseCurrency.gbp,
          category: ExpenseCategory.health,
          user: mockUser,
        );

        // ASSERT
        expect(result.warning, 'offline_currency_edit');
        expect(result.expense.exchangeRates, {'GBP': 1.0});
        verify(mockRepository.updateExpense(any)).called(1);
      },
    );

    // =================================================================
    // TEST 9: Delete Expense - Success
    // =================================================================
    test('Should delete expense when user is authorized', () async {
      // ARRANGE
      when(
        mockRepository.deleteExpense(sampleExpense),
      ).thenAnswer((_) async => {});

      // ACT
      await expenseService.deleteExpense(sampleExpense, user: mockUser);

      // ASSERT
      verify(mockRepository.deleteExpense(sampleExpense)).called(1);
    });

    // =================================================================
    // TEST 10: Delete Expense - Permission Denied
    // =================================================================
    test(
      'Should throw exception when deleting another user\'s expense',
      () async {
        // ARRANGE
        final otherUserExpense = sampleExpense.copyWith(
          userId: 'other-user-999',
        );

        // ACT & ASSERT
        await expectLater(
          () => expenseService.deleteExpense(otherUserExpense, user: mockUser),
          throwsA(isA<RepositoryFailure>()),
        );
        verifyNever(mockRepository.deleteExpense(any));
      },
    );

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
          createdOn: DateTime(now.year, now.month, 1),
          value: 100.0,
        ), // stesso mese, non più anno fisso
      ];

      // ACT
      final totals = expenseService.calculateTotals(
        expenses,
        ExpenseCurrency.euro,
      );

      // ASSERT
      expect(totals.today, closeTo(50.0, 0.01)); // solo la spesa di oggi
      expect(totals.year, closeTo(200.0, 0.01)); // tutte e 4 le spese
    });

    // =================================================================
    // TEST 12: Budget Check - Should Notify
    // =================================================================
    test('Should notify when monthly expenses exceed budget limit', () {
      // ARRANGE
      final now = DateTime.now();
      final expenses = [sampleExpense.copyWith(createdOn: now, value: 600.0)];

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
      final expenses = [sampleExpense.copyWith(value: 1000.0)];

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
      final now = DateTime.now();
      final lastMonth = DateTime(now.year, now.month - 1, 15);
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
      final sorted = expenseService.sortExpenses(
        expenses,
        'date_desc',
        ExpenseCurrency.euro,
      );

      // ASSERT
      // Verifica immutabilità: la lista originale non deve essere stata modificata
      expect(expenses[0].createdOn, DateTime(2024, 1, 10));
      expect(expenses[1].createdOn, DateTime(2024, 1, 20));
      expect(expenses[2].createdOn, DateTime(2024, 1, 15));

      // Verifica ordinamento
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
      final byMonth = expenseService.getExpensesByMonth(
        expenses,
        ExpenseCurrency.euro,
      );

      // ASSERT
      final totalValues = byMonth.values.fold<double>(
        0,
        (sum, val) => sum + val,
      );

      expect(byMonth['${now.year}-01'], closeTo(150.0, 0.01));
      expect(byMonth['${now.year}-02'], closeTo(75.0, 0.01));
      expect(totalValues, closeTo(225.0, 0.01));
    });

    // =================================================================
    // TEST 17: Restore Expense - Success
    // =================================================================
    test('Should restore expense when user is authorized', () async {
      // ARRANGE
      when(
        mockRepository.createExpense(sampleExpense),
      ).thenAnswer((_) async => {});

      // ACT
      final restored = await expenseService.restoreExpense(
        sampleExpense,
        user: mockUser,
      );

      // ASSERT
      expect(restored, sampleExpense);
      verify(mockRepository.createExpense(sampleExpense)).called(1);
    });

    // =================================================================
    // TEST 18: Restore Expense - Not Authenticated
    // =================================================================
    test('Should throw when restoring expense without authentication', () async {
      // ARRANGE
      // Nessun setup aggiuntivo: user null simulato direttamente nella chiamata

      // ACT & ASSERT
      await expectLater(
        () => expenseService.restoreExpense(sampleExpense, user: null),
        throwsA(isA<RepositoryFailure>()),
      );
      verifyNever(mockRepository.createExpense(any));
    });

    // =================================================================
    // TEST 19: Restore Expense - Permission Denied
    // =================================================================
    test('Should throw when restoring another user\'s expense', () async {
      // ARRANGE
      final otherUserExpense = sampleExpense.copyWith(userId: 'other-user-999');

      // ACT & ASSERT
      await expectLater(
        () => expenseService.restoreExpense(otherUserExpense, user: mockUser),
        throwsA(isA<RepositoryFailure>()),
      );
      verifyNever(mockRepository.createExpense(any));
    });

    // =================================================================
    // TEST 20: Edit Expense - Permission Denied (User Mismatch)
    // =================================================================
    test('Should throw when editing expense with mismatched user', () async {
      // ARRANGE
      final otherUserExpense = sampleExpense.copyWith(userId: 'other-user-999');

      // ACT & ASSERT
      await expectLater(
        () => expenseService.editExpense(
          otherUserExpense,
          value: 100.0,
          description: 'Try to edit',
          date: DateTime.now(),
          currency: ExpenseCurrency.euro,
          category: ExpenseCategory.other,
          user: mockUser,
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
        sampleExpense.copyWith(
          uuid: 'restored-1',
          createdOn: now,
          value: 200.0,
        ),
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
      final expenses = [sampleExpense.copyWith(createdOn: now, value: 1000.0)];

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

    // =================================================================
    // TEST 24: Get Expenses by Category For Year (Aggregation)
    // =================================================================
    test('Should aggregate expenses by category for a specific year', () {
      // ARRANGE
      final expenses = [
        sampleExpense.copyWith(
          createdOn: DateTime(2024, 3, 10),
          value: 100.0,
          category: ExpenseCategory.food,
        ),
        sampleExpense.copyWith(
          createdOn: DateTime(2024, 6, 5),
          value: 50.0,
          category: ExpenseCategory.food,
        ),
        sampleExpense.copyWith(
          createdOn: DateTime(2024, 2, 1),
          value: 200.0,
          category: ExpenseCategory.transport,
        ),
        // Anno diverso: deve essere esclusa
        sampleExpense.copyWith(
          createdOn: DateTime(2023, 12, 31),
          value: 999.0,
          category: ExpenseCategory.food,
        ),
      ];

      // ACT
      final byCategory = expenseService.getExpensesByCategoryForYear(
        expenses,
        '2024',
        ExpenseCurrency.euro,
      );

      // ASSERT
      expect(
        byCategory[ExpenseCategory.food],
        closeTo(150.0, 0.01),
      ); // 100 + 50
      expect(byCategory[ExpenseCategory.transport], closeTo(200.0, 0.01));
      expect(byCategory.length, 2); // la spesa 2023 non genera una terza entry
    });

    // =================================================================
    // TEST 25: Edit Expense - Smart Update (Repair Fails with Empty Rates)
    // =================================================================
    test(
      'Should set fallback 1:1 when repair fails and rates are empty',
      () async {
        final brokenExpense = sampleExpense.copyWith(
          exchangeRates: {},
        ); // vuoto

        when(
          mockCurrencyService.getExchangeRates('EUR'),
        ).thenThrow(CurrencyFetchException('offline'));
        when(mockRepository.updateExpense(any)).thenAnswer((_) async => {});

        final result = await expenseService.editExpense(
          brokenExpense,
          value: 50.0,
          description: null,
          date: DateTime.now(),
          currency: ExpenseCurrency.euro,
          category: ExpenseCategory.other,
          user: mockUser,
        );

        expect(result.warning, 'offline_currency_edit');
        expect(result.expense.exchangeRates, {'EUR': 1.0});
      },
    );

    // =================================================================
    // TEST 26: Delete Expense - Permission Denied with Null User
    // =================================================================
    test('Should throw when deleting without authentication', () async {
      await expectLater(
        () => expenseService.deleteExpense(sampleExpense, user: null),
        throwsA(isA<RepositoryFailure>()),
      );
      verifyNever(mockRepository.deleteExpense(any));
    });

    // =================================================================
    // TEST 27: Edit Expense - Permission Denied with Null User
    // =================================================================
    test('Should throw when editing without authentication', () async {
      await expectLater(
        () => expenseService.editExpense(
          sampleExpense,
          value: 100.0,
          description: null,
          date: DateTime.now(),
          currency: ExpenseCurrency.euro,
          category: ExpenseCategory.other,
          user: null,
        ),
        throwsA(isA<RepositoryFailure>()),
      );
      verifyNever(mockRepository.updateExpense(any));
    });

    // =================================================================
    // TEST 28: Load User Expenses - Empty List
    // =================================================================
    test('Should return empty list when user has no expenses', () async {
      when(
        mockRepository.allExpensesForUser('test-user-123'),
      ).thenAnswer((_) async => []);

      final expenses = await expenseService.loadUserExpenses(user: mockUser);

      expect(expenses, isEmpty);
      verify(mockRepository.allExpensesForUser('test-user-123')).called(1);
    });
  });
}
