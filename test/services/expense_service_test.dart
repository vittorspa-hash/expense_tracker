// FILE: expense_service_test.dart
// DESCRIZIONE: Test suite per ExpenseService
// Testa la business logic: creazione, modifica, eliminazione, calcoli aggregati,
// verifiche budget, e strategie soft-fail/smart-update.
// Utilizza MOCK per simulare Firebase e CurrencyService senza dipendenze esterne.

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
        currency: 'EUR',
        exchangeRates: testRates,
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

      // MOCK: Configuriamo il repository a restituire 2 spese non ordinate
      when(mockRepository.allExpensesForUser('test-user-123'))
          .thenAnswer((_) async => [expense1, expense2]);

      // ACT
      final expenses = await expenseService.loadUserExpenses();

      // ASSERT
      // 1. Verifica che il repository sia stato chiamato con l'UID corretto
      verify(mockRepository.allExpensesForUser('test-user-123')).called(1);

      // 2. Verifica che le spese siano ordinate (più recente prima)
      expect(expenses.length, 2);
      expect(expenses[0].createdOn, DateTime(2024, 1, 20)); // Prima
      expect(expenses[1].createdOn, DateTime(2024, 1, 10)); // Seconda
    });

    // =================================================================
    // TEST 2: Load User Expenses - No User Authenticated
    // =================================================================
    test('Should return empty list when no user is authenticated', () async {
      // ARRANGE
      // Simuliamo che nessun utente sia loggato
      when(mockAuth.currentUser).thenReturn(null);

      // ACT
      final expenses = await expenseService.loadUserExpenses();

      // ASSERT
      expect(expenses, isEmpty);
      // Verifica che il repository NON sia stato chiamato (shortcut logico)
      verifyNever(mockRepository.allExpensesForUser(any));
    });

    // =================================================================
    // TEST 3: Create Expense - Success (Online)
    // =================================================================
    test('Should create expense with real exchange rates when online', () async {
      // ARRANGE
      // MOCK: CurrencyService restituisce tassi reali
      when(mockCurrencyService.getExchangeRates('USD'))
          .thenAnswer((_) async => testRates);

      // MOCK: Repository salva con successo
      when(mockRepository.createExpense(any))
          .thenAnswer((_) async => {});

      // ACT
      final result = await expenseService.createExpense(
        value: 50.0,
        description: 'Grocery',
        date: DateTime(2024, 1, 15),
        currency: 'USD',
      );

      // ASSERT
      // 1. Verifica che non ci sia warning (tutto online)
      expect(result.warning, isNull);

      // 2. Verifica che la spesa creata abbia i dati corretti
      expect(result.expense.value, 50.0);
      expect(result.expense.description, 'Grocery');
      expect(result.expense.currency, 'USD');
      expect(result.expense.exchangeRates, testRates);

      // 3. Verifica che il repository sia stato chiamato
      verify(mockRepository.createExpense(any)).called(1);

      // 4. Verifica che CurrencyService sia stato chiamato
      verify(mockCurrencyService.getExchangeRates('USD')).called(1);
    });

    // =================================================================
    // TEST 4: Create Expense - Soft Fail (Offline)
    // =================================================================
    test('Should create expense with fallback rates when currency fetch fails', () async {
      // ARRANGE
      // MOCK: CurrencyService lancia eccezione (simuliamo offline)
      when(mockCurrencyService.getExchangeRates('EUR'))
          .thenThrow(CurrencyFetchException('Network error'));

      when(mockRepository.createExpense(any))
          .thenAnswer((_) async => {});

      // ACT
      final result = await expenseService.createExpense(
        value: 75.0,
        description: 'Offline expense',
        date: DateTime(2024, 1, 15),
        currency: 'EUR',
      );

      // ASSERT
      // 1. Verifica che ci sia un warning (offline)
      expect(result.warning, 'offline_currency_create');

      // 2. Verifica che la spesa sia stata creata con fallback 1:1
      expect(result.expense.exchangeRates, {'EUR': 1.0});

      // 3. La spesa è stata salvata comunque (soft-fail strategy!)
      verify(mockRepository.createExpense(any)).called(1);
    });

    // =================================================================
    // TEST 5: Create Expense - No User Authenticated
    // =================================================================
    test('Should throw exception when creating expense without authentication', () async {
      // ARRANGE
      when(mockAuth.currentUser).thenReturn(null);

      // ACT & ASSERT
      // Verifica che lanci RepositoryFailure
      expect(
        () => expenseService.createExpense(
          value: 50.0,
          description: 'Test',
          date: DateTime.now(),
          currency: 'EUR',
        ),
        throwsA(isA<RepositoryFailure>()),
      );
    });

    // =================================================================
    // TEST 6: Edit Expense - Success (No Repair Needed)
    // =================================================================
    test('Should edit expense without repairing rates when rates are valid', () async {
      // ARRANGE
      // La spesa ha già tassi validi (più di 1 valuta)
      final expenseWithValidRates = sampleExpense; // Ha 3 valute

      when(mockRepository.updateExpense(any))
          .thenAnswer((_) async => {});

      // ACT
      final result = await expenseService.editExpense(
        expenseWithValidRates,
        value: 150.0,
        description: 'Updated',
        date: DateTime(2024, 1, 16),
        currency: 'EUR',
      );

      // ASSERT
      // 1. Nessun warning (tassi OK)
      expect(result.warning, isNull);

      // 2. Valori aggiornati
      expect(result.expense.value, 150.0);
      expect(result.expense.description, 'Updated');

      // 3. Tassi NON modificati (erano già validi)
      expect(result.expense.exchangeRates, testRates);

      // 4. CurrencyService NON chiamato (no repair necessario)
      verifyNever(mockCurrencyService.getExchangeRates(any));

      // 5. Repository chiamato per l'update
      verify(mockRepository.updateExpense(any)).called(1);
    });

    // =================================================================
    // TEST 7: Edit Expense - Smart Update (Repair Success)
    // =================================================================
    test('Should repair broken exchange rates during edit when online', () async {
      // ARRANGE
      // Spesa con tassi "rotti" (solo 1 valuta = creata offline)
      final brokenExpense = sampleExpense.copyWith(
        exchangeRates: {'USD': 1.0}, // Solo 1 = broken!
      );

      // MOCK: Ora siamo online, CurrencyService restituisce tassi reali
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
        currency: 'USD',
      );

      // ASSERT
      // 1. Nessun warning (repair riuscito)
      expect(result.warning, isNull);

      // 2. Tassi RIPARATI (ora ha tutti i tassi)
      expect(result.expense.exchangeRates, testRates);
      expect(result.expense.exchangeRates.length, 3); // Non più 1!

      // 3. CurrencyService chiamato per il repair
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

      // MOCK: Ancora offline, repair fallisce
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
        currency: 'GBP',
      );

      // ASSERT
      // 1. Warning presente (repair fallito)
      expect(result.warning, 'offline_currency_edit');

      // 2. Tassi rimangono fallback
      expect(result.expense.exchangeRates, {'GBP': 1.0});

      // 3. La spesa è stata salvata comunque
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
        userId: 'other-user-999', // Diverso dall'utente loggato
      );

      // ACT & ASSERT
      expect(
        () => expenseService.deleteExpense(otherUserExpense),
        throwsA(isA<RepositoryFailure>()),
      );

      // Verifica che il repository NON sia stato chiamato
      verifyNever(mockRepository.deleteExpense(any));
    });

    // =================================================================
    // TEST 11: Calculate Totals
    // =================================================================
    test('Should calculate expense totals for different time periods', () {
      // ARRANGE
      final now = DateTime.now();
      final expenses = [
        sampleExpense.copyWith(
          createdOn: now, // Oggi
          value: 50.0,
        ),
        sampleExpense.copyWith(
          createdOn: now.subtract(const Duration(days: 2)), // Questa settimana
          value: 30.0,
        ),
        sampleExpense.copyWith(
          createdOn: DateTime(now.year, now.month, 1), // Questo mese
          value: 20.0,
        ),
        sampleExpense.copyWith(
          createdOn: DateTime(now.year, 1, 1), // Quest'anno
          value: 100.0,
        ),
      ];

      // ACT
      final totals = expenseService.calculateTotals(expenses, 'EUR');

      // ASSERT
      // Verifica che i totali siano corretti
      expect(totals.today, greaterThan(0)); // Almeno la spesa di oggi
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
        sampleExpense.copyWith(
          createdOn: now,
          value: 600.0, // Supera il limite
        ),
      ];

      // ACT
      final result = expenseService.checkBudgetStatus(
        expenses: expenses,
        expenseDate: now,
        targetCurrency: 'EUR',
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
        sampleExpense.copyWith(value: 1000.0), // Supera il limite
      ];

      // ACT
      final result = expenseService.checkBudgetStatus(
        expenses: expenses,
        expenseDate: DateTime.now(),
        targetCurrency: 'EUR',
        budgetLimit: 100.0,
        alertEnabled: false, // DISABILITATO
      );

      // ASSERT
      expect(result.shouldNotify, false); // Non notifica mai
    });

    // =================================================================
    // TEST 14: Budget Check - Should NOT Notify (Different Month)
    // =================================================================
    test('Should not notify for expenses from different months', () {
      // ARRANGE
      final lastMonth = DateTime.now().subtract(const Duration(days: 60));
      final expenses = [
        sampleExpense.copyWith(
          createdOn: lastMonth,
          value: 1000.0,
        ),
      ];

      // ACT
      final result = expenseService.checkBudgetStatus(
        expenses: expenses,
        expenseDate: lastMonth, // Mese passato
        targetCurrency: 'EUR',
        budgetLimit: 100.0,
        alertEnabled: true,
      );

      // ASSERT
      expect(result.shouldNotify, false); // Non notifica mesi passati
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
        'EUR',
      );

      // ASSERT
      expect(sorted[0].createdOn, DateTime(2024, 1, 20)); // Più recente
      expect(sorted[1].createdOn, DateTime(2024, 1, 15));
      expect(sorted[2].createdOn, DateTime(2024, 1, 10)); // Meno recente
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
      final byMonth = expenseService.getExpensesByMonth(expenses, 'EUR');

      // ASSERT
      // Verifica che la mappa contenga dati aggregati
      expect(byMonth, isNotEmpty);
      
      // Verifica che i totali siano corretti per i mesi presenti
      // Nota: Le chiavi dipendono dall'implementazione di ExpenseCalculator
      final totalValues = byMonth.values.fold<double>(0, (sum, val) => sum + val);
      expect(totalValues, closeTo(225.0, 0.01)); // 100 + 50 + 75 = 225
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

      // Verifica che il repository NON sia stato chiamato
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

      // Verifica che il repository NON sia stato chiamato
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
          currency: 'EUR',
        ),
        throwsA(isA<RepositoryFailure>()),
      );

      // Verifica che il repository NON sia stato chiamato
      verifyNever(mockRepository.updateExpense(any));
    });

    // =================================================================
    // TEST 21: Budget Check for List - Should Notify
    // =================================================================
    test('Should notify when restoring expenses exceeds budget', () {
      // ARRANGE
      final now = DateTime.now();
      final currentMonthExpenses = [
        sampleExpense.copyWith(
          createdOn: now,
          value: 400.0,
        ),
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
        targetCurrency: 'EUR',
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
        createdOn: DateTime(2023, 1, 15), // Anno passato
        value: 1000.0,
      );

      // ACT
      final result = expenseService.checkBudgetStatusForList(
        allExpenses: [oldExpense],
        newExpenses: [oldExpense],
        targetCurrency: 'EUR',
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
        sampleExpense.copyWith(
          createdOn: now,
          value: 1000.0,
        ),
      ];

      // ACT
      final result = expenseService.checkBudgetStatusForList(
        allExpenses: expenses,
        newExpenses: expenses,
        targetCurrency: 'EUR',
        budgetLimit: 100.0,
        alertEnabled: false,  // DISABILITATO
      );

      // ASSERT
      expect(result.shouldNotify, false);
    });
  });
}